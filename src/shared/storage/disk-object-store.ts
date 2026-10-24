import { randomUUID } from "node:crypto";
import { mkdir, readdir, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import { dirname, join, relative, resolve, sep } from "node:path";
import { keySegments, objectKeySegments, type ListOptions, type ObjectStore, type StoredObject } from "./object-store";

function isMissing(error: unknown): boolean {
  if (typeof error !== "object" || error === null || !("code" in error)) return false;
  return error.code === "ENOENT" || error.code === "EISDIR" || error.code === "ENOTDIR";
}

// Files under one root directory. The static guard in index.ts never serves the
// directory: files only leave through the API's own routes.
export function createDiskObjectStore(rootDir: string): ObjectStore {
  const root = resolve(rootDir);

  // Keys are already free of "..", so this prefix check is a second line of
  // defence, not the only one.
  function pathOf(segments: string[]): string {
    const full = resolve(root, ...segments);
    if (full !== root && !full.startsWith(root + sep)) throw new Error("storage key escapes the uploads directory");
    return full;
  }

  async function walk(directory: string, recursive: boolean, found: StoredObject[]): Promise<void> {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error: unknown) {
      if (isMissing(error)) return;
      throw error;
    }
    for (const entry of entries) {
      const path = join(directory, entry.name);
      // Dirent says what the entry itself is: a symbolic link is neither a file
      // nor a directory here, so a link planted in the tree is never followed.
      if (entry.isDirectory()) {
        if (recursive) await walk(path, recursive, found);
      } else if (entry.isFile()) {
        found.push({ key: relative(root, path).split(sep).join("/"), modifiedAt: (await stat(path)).mtime });
      }
    }
  }

  return {
    async put(key, bytes) {
      const target = pathOf(objectKeySegments(key));
      await mkdir(dirname(target), { recursive: true, mode: 0o700 });
      // Write then rename, so a reader never sees a half-written file.
      const partial = `${target}.${randomUUID()}.partial`;
      try {
        await writeFile(partial, bytes, { mode: 0o600 });
        await rename(partial, target);
      } catch (error: unknown) {
        await rm(partial, { force: true });
        throw error;
      }
    },

    async get(key) {
      try {
        return new Uint8Array(await readFile(pathOf(objectKeySegments(key))));
      } catch (error: unknown) {
        if (isMissing(error)) return null;
        throw error;
      }
    },

    async exists(key) {
      try {
        return (await stat(pathOf(objectKeySegments(key)))).isFile();
      } catch (error: unknown) {
        if (isMissing(error)) return false;
        throw error;
      }
    },

    async delete(key) {
      try {
        await rm(pathOf(objectKeySegments(key)), { force: true });
      } catch (error: unknown) {
        // A directory is not an object: nothing to delete, as in a bucket.
        if (!isMissing(error)) throw error;
      }
    },

    async list(prefix, options?: ListOptions) {
      const found: StoredObject[] = [];
      await walk(pathOf(keySegments(prefix)), options?.recursive ?? true, found);
      return found.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));
    },
  };
}
