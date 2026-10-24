import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, readdirSync, rmSync, statSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createDiskObjectStore } from "../../src/shared/storage/disk-object-store";
import { describeObjectStoreContract } from "./storage-contract";

const made: string[] = [];
function freshRoot(): string {
  const base = mkdtempSync(join(tmpdir(), "mazl-disk-store-"));
  made.push(base);
  return join(base, "uploads");
}
afterAll(() => {
  for (const base of made) rmSync(base, { recursive: true, force: true });
});

describeObjectStoreContract("disk", () => createDiskObjectStore(freshRoot()));

describe("disk store", () => {
  test("files are private to the server user", async () => {
    const root = freshRoot();
    await createDiskObjectStore(root).put("documents/x.enc", new Uint8Array([1]));
    expect(statSync(join(root, "documents/x.enc")).mode & 0o077).toBe(0);
  });

  test("a write leaves no temporary file behind", async () => {
    const root = freshRoot();
    await createDiskObjectStore(root).put("documents/x.enc", new Uint8Array([1]));
    expect(readdirSync(join(root, "documents"))).toEqual(["x.enc"]);
  });

  describe("with symbolic links planted in the directory", () => {
    let root = "";
    let outside = "";
    beforeAll(() => {
      root = freshRoot();
      outside = join(root, "..", "outside");
      mkdirSync(join(root, "chat", "7"), { recursive: true });
      mkdirSync(outside, { recursive: true });
      writeFileSync(join(root, "chat", "7", "a.jpg"), "a");
      writeFileSync(join(outside, "secret.txt"), "secret");
      utimesSync(join(root, "chat", "7", "a.jpg"), new Date("2026-01-01T00:00:00Z"), new Date("2026-01-01T00:00:00Z"));
      symlinkSync(outside, join(root, "chat", "link-dir"));
      symlinkSync(join(outside, "secret.txt"), join(root, "chat", "link-file.txt"));
    });

    test("list never follows a link, to a file or to a directory", async () => {
      const keys = (await createDiskObjectStore(root).list("chat")).map((o) => o.key);
      expect(keys).toEqual(["chat/7/a.jpg"]);
    });

    test("list reports the modification time of the file", async () => {
      const [only] = await createDiskObjectStore(root).list("chat/7");
      expect(only?.modifiedAt.toISOString()).toBe("2026-01-01T00:00:00.000Z");
    });

    test("delete of a key that climbs out leaves the outside untouched", async () => {
      await expect(createDiskObjectStore(root).delete("../outside/secret.txt")).rejects.toThrow();
      expect(await Bun.file(join(outside, "secret.txt")).exists()).toBe(true);
    });
  });
});
