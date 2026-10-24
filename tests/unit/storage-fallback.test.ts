import { describe, expect, test } from "bun:test";
import { withLegacyFallback } from "../../src/shared/storage/fallback-object-store";
import type { ObjectStore } from "../../src/shared/storage/object-store";
import { createS3ObjectStore } from "../../src/shared/storage/s3-object-store";
import { describeObjectStoreContract } from "./storage-contract";
import { FakeS3Client } from "./storage-fakes";

const bytes = (...values: number[]): Uint8Array => new Uint8Array(values);

function pair(): { s3: FakeS3Client; legacy: FakeS3Client; store: ObjectStore } {
  const s3 = new FakeS3Client();
  const legacy = new FakeS3Client();
  return { s3, legacy, store: withLegacyFallback(createS3ObjectStore(s3), createS3ObjectStore(legacy)) };
}

describeObjectStoreContract("S3 with legacy fallback", () => pair().store);

describe("S3 first, legacy disk second", () => {
  test("an object present in S3 is read from S3 without touching the legacy store", async () => {
    const { s3, legacy, store } = pair();
    await s3.write("profiles/7/a.jpg", bytes(1));
    await legacy.write("profiles/7/a.jpg", bytes(9));
    expect(await store.get("profiles/7/a.jpg")).toEqual(bytes(1));
    expect(legacy.reads).toEqual([]);
  });

  test("an object missing from S3 is read once from the legacy store", async () => {
    const { legacy, store } = pair();
    await legacy.write("profiles/7/old.jpg", bytes(4));
    expect(await store.get("profiles/7/old.jpg")).toEqual(bytes(4));
    expect(await store.exists("profiles/7/old.jpg")).toBe(true);
    expect(legacy.reads).toEqual(["profiles/7/old.jpg"]);
  });

  test("missing from both is null", async () => {
    const { store } = pair();
    expect(await store.get("nope/x")).toBeNull();
    expect(await store.exists("nope/x")).toBe(false);
  });

  test("writes go to S3 only, never to the legacy store", async () => {
    const { s3, legacy, store } = pair();
    await store.put("chat/1/new.jpg", bytes(1));
    expect(s3.writes).toEqual(["chat/1/new.jpg"]);
    expect(legacy.writes).toEqual([]);
  });

  test("delete removes both copies, so an erased member leaves nothing on the old disk", async () => {
    const { s3, legacy, store } = pair();
    await s3.write("profiles/7/a.jpg", bytes(1));
    await legacy.write("profiles/7/a.jpg", bytes(1));
    await legacy.write("profiles/7/only-legacy.jpg", bytes(1));
    await store.delete("profiles/7/a.jpg");
    await store.delete("profiles/7/only-legacy.jpg");
    expect(s3.objects.size).toBe(0);
    expect(legacy.objects.size).toBe(0);
  });

  test("list is the union of both, each key once, S3 winning", async () => {
    const { s3, legacy, store } = pair();
    await s3.write("chat/1/a.jpg", bytes(1));
    await legacy.write("chat/1/a.jpg", bytes(1));
    await legacy.write("chat/1/b.jpg", bytes(1));
    expect((await store.list("chat")).map((o) => o.key)).toEqual(["chat/1/a.jpg", "chat/1/b.jpg"]);
  });

  test("an S3 failure is not papered over by the legacy copy", async () => {
    const { s3, legacy, store } = pair();
    await legacy.write("profiles/7/a.jpg", bytes(1));
    s3.failWith = new Error("connection refused");
    await expect(store.get("profiles/7/a.jpg")).rejects.toThrow("connection refused");
    await expect(store.exists("profiles/7/a.jpg")).rejects.toThrow("connection refused");
  });
});
