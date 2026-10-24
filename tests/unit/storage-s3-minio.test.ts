import { afterAll, describe, expect, test } from "bun:test";
import { randomUUID } from "node:crypto";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { createObjectStore } from "../../src/shared/storage/create-object-store";
import { readStorageConfig } from "../../src/shared/storage/storage-config";

// Runs against a real S3-compatible server (MinIO in production). Skipped unless
// S3_TEST_ENDPOINT is set:
//
//   S3_TEST_ENDPOINT=http://localhost:59000 S3_TEST_BUCKET=mazl-test \
//   S3_TEST_ACCESS_KEY_ID=... S3_TEST_SECRET_ACCESS_KEY=... \
//   bun test ./storage-s3-minio.test.ts        (from tests/unit)
//
// The bucket must already exist (mc mb). Every run works under its own random
// prefix and removes what it wrote. Credentials come from the environment only.

const endpoint = process.env.S3_TEST_ENDPOINT;
const run = endpoint ? describe : describe.skip;

const bytes = (...values: number[]): Uint8Array => new Uint8Array(values);
const prefix = `it-${randomUUID()}`;
const legacyRoot = mkdtempSync(join(tmpdir(), "mazl-s3-legacy-"));

function realStore() {
  const config = readStorageConfig({
    S3_ENDPOINT: endpoint,
    S3_BUCKET: process.env.S3_TEST_BUCKET ?? "mazl-test",
    S3_ACCESS_KEY_ID: process.env.S3_TEST_ACCESS_KEY_ID,
    S3_SECRET_ACCESS_KEY: process.env.S3_TEST_SECRET_ACCESS_KEY,
    S3_REGION: process.env.S3_TEST_REGION,
    UPLOADS_DIR: legacyRoot,
  });
  return createObjectStore(config);
}

afterAll(async () => {
  rmSync(legacyRoot, { recursive: true, force: true });
  if (!endpoint) return;
  const store = realStore();
  // Over 1000 keys behind a real network: well past bun's 5 s default.
  const objects = await store.list(prefix);
  for (let i = 0; i < objects.length; i += 50) {
    await Promise.all(objects.slice(i, i + 50).map((object) => store.delete(object.key)));
  }
}, 120_000);

run("object store on a real bucket", () => {
  test("put then get returns the same bytes", async () => {
    const store = realStore();
    await store.put(`${prefix}/profiles/7/a.jpg`, bytes(1, 2, 3, 255, 0));
    expect(await store.get(`${prefix}/profiles/7/a.jpg`)).toEqual(bytes(1, 2, 3, 255, 0));
  });

  test("exists is true for a stored object and false for a missing key", async () => {
    const store = realStore();
    await store.put(`${prefix}/exists/a`, bytes(1));
    expect(await store.exists(`${prefix}/exists/a`)).toBe(true);
    expect(await store.exists(`${prefix}/exists/none`)).toBe(false);
  });

  test("a missing key reads as null, not as an error", async () => {
    expect(await realStore().get(`${prefix}/missing/none.jpg`)).toBeNull();
  });

  test("an empty object and an accented key with symbols round-trip", async () => {
    const store = realStore();
    await store.put(`${prefix}/odd/empty`, bytes());
    await store.put(`${prefix}/odd/é & +x y.enc`, bytes(9));
    expect(await store.get(`${prefix}/odd/empty`)).toEqual(bytes());
    expect(await store.get(`${prefix}/odd/é & +x y.enc`)).toEqual(bytes(9));
  });

  test("delete removes the object and a second delete is fine", async () => {
    const store = realStore();
    await store.put(`${prefix}/del/a`, bytes(1));
    await store.delete(`${prefix}/del/a`);
    expect(await store.exists(`${prefix}/del/a`)).toBe(false);
    await store.delete(`${prefix}/del/a`);
  });

  test("put replaces an existing object", async () => {
    const store = realStore();
    await store.put(`${prefix}/replace/a`, bytes(1));
    await store.put(`${prefix}/replace/a`, bytes(2, 2));
    expect(await store.get(`${prefix}/replace/a`)).toEqual(bytes(2, 2));
  });

  test("list reads a prefix as a directory and reports modification times", async () => {
    const store = realStore();
    await store.put(`${prefix}/chat/7/a.jpg`, bytes(1));
    await store.put(`${prefix}/chat/7/b.jpg`, bytes(1));
    await store.put(`${prefix}/chatter/1/x.jpg`, bytes(1));
    const found = await store.list(`${prefix}/chat`);
    expect(found.map((o) => o.key)).toEqual([`${prefix}/chat/7/a.jpg`, `${prefix}/chat/7/b.jpg`]);
    for (const object of found) expect(Number.isNaN(object.modifiedAt.getTime())).toBe(false);
    expect(await store.list(`${prefix}/chat/404`)).toEqual([]);
  });

  test("a list of more than one page (S3 returns at most 1000 keys) follows the continuation token", async () => {
    const store = realStore();
    const total = 1003;
    for (let from = 0; from < total; from += 50) {
      const batch = Array.from({ length: Math.min(50, total - from) }, (_, i) => from + i);
      await Promise.all(batch.map((n) => store.put(`${prefix}/many/${String(n).padStart(5, "0")}`, bytes(1))));
    }
    const found = await store.list(`${prefix}/many`);
    expect(found).toHaveLength(total);
    expect(new Set(found.map((o) => o.key)).size).toBe(total);
  }, 60_000);

  test("a non-recursive list keeps the files directly inside the prefix", async () => {
    const store = realStore();
    await store.put(`${prefix}/flat/12-doc.jpg`, bytes(1));
    await store.put(`${prefix}/flat/documents/x.enc`, bytes(1));
    expect((await store.list(`${prefix}/flat`, { recursive: false })).map((o) => o.key)).toEqual([`${prefix}/flat/12-doc.jpg`]);
  });

  test("keys that climb out are refused before reaching the server", async () => {
    const store = realStore();
    await expect(store.put(`${prefix}/../escape`, bytes(1))).rejects.toThrow();
    await expect(store.get("../escape")).rejects.toThrow();
  });

  test("an object only on the old disk is still readable, listed and deletable", async () => {
    const store = realStore();
    const legacyKey = `${prefix}/legacy/old.jpg`;
    const path = join(legacyRoot, legacyKey);
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, bytes(4, 4));
    expect(await store.get(legacyKey)).toEqual(bytes(4, 4));
    expect(await store.exists(legacyKey)).toBe(true);
    expect((await store.list(`${prefix}/legacy`)).map((o) => o.key)).toEqual([legacyKey]);
    await store.delete(legacyKey);
    expect(await store.get(legacyKey)).toBeNull();
    expect(await Bun.file(path).exists()).toBe(false);
  });

  test("wrong credentials are an error, never an empty answer", async () => {
    const config = readStorageConfig({
      S3_ENDPOINT: endpoint,
      S3_BUCKET: process.env.S3_TEST_BUCKET ?? "mazl-test",
      S3_ACCESS_KEY_ID: "wrong-key",
      S3_SECRET_ACCESS_KEY: "wrong-secret-value",
      UPLOADS_DIR: legacyRoot,
    });
    const store = createObjectStore(config);
    await expect(store.get(`${prefix}/profiles/7/a.jpg`)).rejects.toThrow();
    await expect(store.put(`${prefix}/profiles/7/b.jpg`, bytes(1))).rejects.toThrow();
  });
});
