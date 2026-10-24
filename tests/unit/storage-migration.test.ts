import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { createDiskObjectStore } from "../../src/shared/storage/disk-object-store";
import { copyMissingObjects } from "../../src/shared/storage/copy-missing-objects";
import { createS3ObjectStore } from "../../src/shared/storage/s3-object-store";
import { FakeS3Client } from "./storage-fakes";

let base = "";
let root = "";
function put(key: string, content: string): void {
  const path = join(root, key);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

beforeEach(() => {
  base = mkdtempSync(join(tmpdir(), "mazl-migrate-"));
  root = join(base, "uploads");
  mkdirSync(root, { recursive: true });
});
afterEach(() => rmSync(base, { recursive: true, force: true }));

function setup() {
  const client = new FakeS3Client();
  return { client, source: createDiskObjectStore(root), target: createS3ObjectStore(client) };
}

describe("copyMissingObjects (uploads directory -> bucket)", () => {
  test("every file lands under the same key, byte for byte", async () => {
    put("profiles/7/a.jpg", "photo");
    put("chat/7/b.jpg", "chat");
    put("documents/x.enc", "enc");
    put("12-selfie_id-0b9a1f3e-aaaa-4bbb-8ccc-1234567890ab.jpg", "legacy");
    const { client, source, target } = setup();
    const report = await copyMissingObjects({ source, target, dryRun: false });
    expect([...client.objects.keys()].sort()).toEqual([
      "12-selfie_id-0b9a1f3e-aaaa-4bbb-8ccc-1234567890ab.jpg",
      "chat/7/b.jpg",
      "documents/x.enc",
      "profiles/7/a.jpg",
    ]);
    expect(new TextDecoder().decode(client.objects.get("profiles/7/a.jpg")!.bytes)).toBe("photo");
    expect(report).toMatchObject({ scanned: 4, uploaded: 4, alreadyPresent: 0, failed: [] });
    expect(report.bytesUploaded).toBe("photo".length + "chat".length + "enc".length + "legacy".length);
  });

  test("idempotent: a second run uploads nothing and never overwrites what is in the bucket", async () => {
    put("profiles/7/a.jpg", "photo");
    const { client, source, target } = setup();
    await copyMissingObjects({ source, target, dryRun: false });
    await target.put("profiles/7/a.jpg", new TextEncoder().encode("newer in bucket"));
    client.writes.length = 0;
    const report = await copyMissingObjects({ source, target, dryRun: false });
    expect(report).toMatchObject({ scanned: 1, uploaded: 0, alreadyPresent: 1, failed: [] });
    expect(client.writes).toEqual([]);
    expect(new TextDecoder().decode(client.objects.get("profiles/7/a.jpg")!.bytes)).toBe("newer in bucket");
  });

  test("dry run counts what would be uploaded and writes nothing", async () => {
    put("profiles/7/a.jpg", "photo");
    put("profiles/7/b.jpg", "photo2");
    const { client, source, target } = setup();
    await target.put("profiles/7/b.jpg", new Uint8Array([1]));
    client.writes.length = 0;
    const report = await copyMissingObjects({ source, target, dryRun: true });
    expect(report).toMatchObject({ scanned: 2, uploaded: 1, alreadyPresent: 1, failed: [] });
    expect(client.writes).toEqual([]);
  });

  test("never deletes or changes a local file", async () => {
    put("profiles/7/a.jpg", "photo");
    const { source, target } = setup();
    await copyMissingObjects({ source, target, dryRun: false });
    expect(await Bun.file(join(root, "profiles/7/a.jpg")).text()).toBe("photo");
  });

  test("temporary .partial files are skipped, not uploaded", async () => {
    put("documents/x.enc.0b9a1f3e.partial", "half");
    put("documents/x.enc", "enc");
    const { client, source, target } = setup();
    const report = await copyMissingObjects({ source, target, dryRun: false });
    expect([...client.objects.keys()]).toEqual(["documents/x.enc"]);
    expect(report.skippedPartial).toBe(1);
  });

  test("symbolic links are not followed out of the uploads directory", async () => {
    put("profiles/7/a.jpg", "photo");
    const outside = join(base, "outside.txt");
    writeFileSync(outside, "secret");
    symlinkSync(outside, join(root, "profiles/7/link.txt"));
    const { client, source, target } = setup();
    await copyMissingObjects({ source, target, dryRun: false });
    expect([...client.objects.keys()]).toEqual(["profiles/7/a.jpg"]);
  });

  test("a file that fails is reported and does not stop the others", async () => {
    put("profiles/7/a.jpg", "photo");
    put("profiles/7/b.jpg", "photo2");
    const { client, source } = setup();
    const flaky = createS3ObjectStore({
      read: (key) => client.read(key),
      exists: (key) => client.exists(key),
      remove: (key) => client.remove(key),
      list: (query) => client.list(query),
      write: async (key, bytes) => {
        if (key === "profiles/7/a.jpg") throw new Error("boom");
        await client.write(key, bytes);
      },
    });
    const report = await copyMissingObjects({ source, target: flaky, dryRun: false });
    expect(report.uploaded).toBe(1);
    expect(report.failed).toEqual(["profiles/7/a.jpg"]);
    expect([...client.objects.keys()]).toEqual(["profiles/7/b.jpg"]);
  });

  test("an empty uploads directory is a clean no-op", async () => {
    const { source, target } = setup();
    expect(await copyMissingObjects({ source, target, dryRun: false })).toMatchObject({ scanned: 0, uploaded: 0, failed: [] });
  });
});
