import { describe, expect, test } from "bun:test";
import type { ObjectStore } from "../../src/shared/storage/object-store";

const bytes = (...values: number[]): Uint8Array => new Uint8Array(values);

// What every ObjectStore must do, whatever it is stored in. Written from the
// behaviour the application relies on (photos, chat files, documents), not from
// any one adapter.
export function describeObjectStoreContract(name: string, create: () => Promise<ObjectStore> | ObjectStore): void {
  describe(`ObjectStore contract: ${name}`, () => {
    test("put then get returns the same bytes, nested keys included", async () => {
      const store = await create();
      await store.put("profiles/7/a.jpg", bytes(1, 2, 3));
      expect(await store.get("profiles/7/a.jpg")).toEqual(bytes(1, 2, 3));
    });

    test("an empty file is stored and read back as empty, not as missing", async () => {
      const store = await create();
      await store.put("chat/1/empty.bin", bytes());
      expect(await store.get("chat/1/empty.bin")).toEqual(bytes());
      expect(await store.exists("chat/1/empty.bin")).toBe(true);
    });

    test("put replaces an existing object", async () => {
      const store = await create();
      await store.put("k/a", bytes(1));
      await store.put("k/a", bytes(2, 2));
      expect(await store.get("k/a")).toEqual(bytes(2, 2));
    });

    test("get of a missing key is null and exists is false", async () => {
      const store = await create();
      expect(await store.get("nope/none.jpg")).toBeNull();
      expect(await store.exists("nope/none.jpg")).toBe(false);
    });

    test("a prefix of a stored key is not an object", async () => {
      const store = await create();
      await store.put("profiles/7/a.jpg", bytes(1));
      expect(await store.get("profiles/7")).toBeNull();
      expect(await store.exists("profiles")).toBe(false);
    });

    test("delete removes the object and is idempotent", async () => {
      const store = await create();
      await store.put("k/a", bytes(1));
      await store.delete("k/a");
      expect(await store.exists("k/a")).toBe(false);
      await store.delete("k/a");
      await store.delete("k/never-existed");
    });

    test("keys with spaces, accents and symbols survive a round trip", async () => {
      const store = await create();
      await store.put("documents/é & +x.enc", bytes(9));
      expect(await store.get("documents/é & +x.enc")).toEqual(bytes(9));
      expect((await store.list("documents")).map((o) => o.key)).toEqual(["documents/é & +x.enc"]);
    });

    test("keys that climb out of the store are refused by every operation", async () => {
      const store = await create();
      for (const key of ["../etc/passwd", "a/../../x", "..", "a/..", "documents/../../x"]) {
        await expect(store.put(key, bytes(1))).rejects.toThrow();
        await expect(store.get(key)).rejects.toThrow();
        await expect(store.exists(key)).rejects.toThrow();
        await expect(store.delete(key)).rejects.toThrow();
      }
    });

    test("an empty key, or one with a NUL byte, is refused", async () => {
      const store = await create();
      for (const key of ["", "/", "a\0b"]) {
        await expect(store.put(key, bytes(1))).rejects.toThrow();
        await expect(store.get(key)).rejects.toThrow();
      }
    });

    test("a leading slash and doubled slashes address the same object as the clean key", async () => {
      const store = await create();
      await store.put("/profiles//7/a.jpg", bytes(5));
      expect(await store.get("profiles/7/a.jpg")).toEqual(bytes(5));
    });

    test("list returns the keys under a directory prefix, with a modification time, sorted", async () => {
      const store = await create();
      await store.put("chat/7/b.jpg", bytes(1));
      await store.put("chat/7/a.jpg", bytes(1));
      await store.put("chat/preview-cache/p.jpg", bytes(1));
      await store.put("photos/x.jpg", bytes(1));
      const found = await store.list("chat");
      expect(found.map((o) => o.key)).toEqual(["chat/7/a.jpg", "chat/7/b.jpg", "chat/preview-cache/p.jpg"]);
      for (const object of found) expect(object.modifiedAt).toBeInstanceOf(Date);
    });

    test("list of a prefix is a directory, not a string prefix: chat does not list chatter", async () => {
      const store = await create();
      await store.put("chat/1/a", bytes(1));
      await store.put("chatter/1/a", bytes(1));
      expect((await store.list("chat")).map((o) => o.key)).toEqual(["chat/1/a"]);
      expect((await store.list("chat/")).map((o) => o.key)).toEqual(["chat/1/a"]);
    });

    test("list of a missing prefix is empty", async () => {
      const store = await create();
      expect(await store.list("chat/404")).toEqual([]);
    });

    test("list with an empty prefix covers the whole store; non-recursive keeps the top level only", async () => {
      const store = await create();
      await store.put("12-selfie.jpg", bytes(1));
      await store.put("documents/x.enc", bytes(1));
      expect((await store.list("")).map((o) => o.key)).toEqual(["12-selfie.jpg", "documents/x.enc"]);
      expect((await store.list("", { recursive: false })).map((o) => o.key)).toEqual(["12-selfie.jpg"]);
    });

    test("an absolute prefix is read relative to the store, never as a system path", async () => {
      const store = await create();
      expect(await store.list("/etc")).toEqual([]);
    });

    test("a prefix that climbs out of the store is refused", async () => {
      const store = await create();
      for (const prefix of ["..", "../outside", "chat/../../outside", "chat/../.."]) {
        await expect(store.list(prefix)).rejects.toThrow();
      }
    });
  });
}
