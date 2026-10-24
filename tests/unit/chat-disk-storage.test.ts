import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createChatDiskStorage } from "../../src/features/chat/infra/disk-chat-storage";

// The chat disk store: the same traversal guard as the photo store, plus a
// listing used by the stray-file sweep. The listing must stay inside the root.

let base = "";
let root = "";
let outside = "";

beforeAll(() => {
  base = mkdtempSync(join(tmpdir(), "mazl-chat-disk-"));
  root = join(base, "uploads");
  outside = join(base, "outside");
  mkdirSync(join(root, "chat", "7"), { recursive: true });
  mkdirSync(join(root, "chat", "preview-cache"), { recursive: true });
  mkdirSync(join(root, "photos"), { recursive: true });
  mkdirSync(outside, { recursive: true });
  writeFileSync(join(root, "chat", "7", "a.jpg"), "a");
  writeFileSync(join(root, "chat", "preview-cache", "p.jpg"), "p");
  writeFileSync(join(root, "photos", "profile.jpg"), "x");
  writeFileSync(join(outside, "secret.txt"), "secret");
  utimesSync(join(root, "chat", "7", "a.jpg"), new Date("2026-01-01T00:00:00Z"), new Date("2026-01-01T00:00:00Z"));
  symlinkSync(outside, join(root, "chat", "link-dir"));
  symlinkSync(join(outside, "secret.txt"), join(root, "chat", "link-file.txt"));
});

afterAll(() => rmSync(base, { recursive: true, force: true }));

describe("list", () => {
  test("every regular file under the prefix, with its key and modification time", async () => {
    const files = await createChatDiskStorage(root).list("chat");
    expect(files.map((f) => f.key).sort()).toEqual(["chat/7/a.jpg", "chat/preview-cache/p.jpg"]);
    expect(files.find((f) => f.key === "chat/7/a.jpg")?.modifiedAt.toISOString()).toBe("2026-01-01T00:00:00.000Z");
  });

  test("never follows a symbolic link out of the root, to a file or to a directory", async () => {
    const keys = (await createChatDiskStorage(root).list("chat")).map((f) => f.key);
    expect(keys.some((k) => k.includes("link"))).toBe(false);
    expect(keys.some((k) => k.includes("secret"))).toBe(false);
  });

  test("does not list outside its prefix", async () => {
    const keys = (await createChatDiskStorage(root).list("chat/7")).map((f) => f.key);
    expect(keys).toEqual(["chat/7/a.jpg"]);
  });

  test("a prefix that escapes the root is refused", async () => {
    const storage = createChatDiskStorage(root);
    for (const prefix of ["..", "../outside", "chat/../../outside", "chat/../.."]) {
      await expect(storage.list(prefix)).rejects.toThrow();
    }
  });

  test("an absolute prefix is read as relative to the root, never as a system path", async () => {
    expect(await createChatDiskStorage(root).list("/etc")).toEqual([]);
  });

  test("a prefix that does not exist is an empty list", async () => {
    expect(await createChatDiskStorage(root).list("chat/404")).toEqual([]);
  });
});

describe("remove keeps the photo store's guard", () => {
  test("a key that escapes the root is refused and nothing outside is touched", async () => {
    const storage = createChatDiskStorage(root);
    await expect(storage.remove("../outside/secret.txt")).rejects.toThrow();
    expect(await Bun.file(join(outside, "secret.txt")).exists()).toBe(true);
  });

  test("removing a missing file is not an error", async () => {
    await createChatDiskStorage(root).remove("chat/7/missing.jpg");
  });
});
