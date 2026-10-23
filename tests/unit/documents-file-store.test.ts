import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { mkdtemp, readdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createUploadDocument } from "../../src/features/documents/application/upload-document";
import { DiskFileStore } from "../../src/features/documents/infra/disk-file-store";
import { containsBytes, fakeJpeg, MemoryRepo, SECRET_MARKER } from "./documents-fakes";

let root = "";
beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), "mazl-docs-"));
});
afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

describe("DiskFileStore", () => {
  test("after an upload nothing under the uploads root contains the plaintext", async () => {
    const store = new DiskFileStore(root);
    const upload = createUploadDocument({ repo: new MemoryRepo(), store });
    const { filename } = await upload({ waitlistId: 1, type: "selfie_id", bytes: fakeJpeg() });

    const walk = async (dir: string): Promise<string[]> => {
      const out: string[] = [];
      for (const entry of await readdir(dir, { withFileTypes: true })) {
        const full = join(dir, entry.name);
        if (entry.isDirectory()) out.push(...(await walk(full)));
        else out.push(full);
      }
      return out;
    };
    const files = await walk(root);
    expect(files.length).toBe(1);
    expect(files[0]).toEndWith(".enc");
    for (const file of files) expect(containsBytes(await readFile(file), SECRET_MARKER)).toBe(false);
    expect(filename).toBe(files[0]!.slice(root.length + 1));
  });

  test("files are private to the server user", async () => {
    const store = new DiskFileStore(root);
    await store.write("documents/x.enc", new Uint8Array([1]));
    expect((await stat(join(root, "documents/x.enc"))).mode & 0o077).toBe(0);
  });

  test("read returns null for a missing file and remove is idempotent", async () => {
    const store = new DiskFileStore(root);
    expect(await store.read("documents/none.enc")).toBeNull();
    await store.remove("documents/none.enc");
  });

  test("names that escape the root are refused", async () => {
    const store = new DiskFileStore(root);
    await expect(store.read("../etc/passwd")).rejects.toThrow();
    await expect(store.remove("documents/../../x")).rejects.toThrow();
  });

  test("listLegacyFiles lists only root-level document files", async () => {
    const store = new DiskFileStore(root);
    await writeFile(join(root, "12-selfie_id-0b9a1f3e-aaaa-4bbb-8ccc-1234567890ab.jpg"), "x");
    await writeFile(join(root, "notes.txt"), "x");
    await store.write("documents/x.enc", new Uint8Array([1]));
    expect(await store.listLegacyFiles()).toEqual(["12-selfie_id-0b9a1f3e-aaaa-4bbb-8ccc-1234567890ab.jpg"]);
  });
});
