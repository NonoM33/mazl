import { readdir, stat } from "node:fs/promises";
import { join, relative, resolve, sep } from "node:path";
import { createDiskPhotoStorage } from "../../media/infra/disk-photo-storage";
import type { FileStorage, StoredFile } from "../application/ports";

// Chat files live under `chat/` in the uploads directory. Save, read and remove
// are the photo store's (same traversal guard); the listing is added here for
// the stray-file sweep. It stays inside the root and never follows symbolic
// links: a link planted in the directory cannot make the sweep delete, or even
// look at, anything else.
export function createChatDiskStorage(uploadsDir: string): FileStorage {
  const root = resolve(uploadsDir);
  const files = createDiskPhotoStorage(uploadsDir);

  function directoryOf(prefix: string): string {
    const full = resolve(join(root, prefix));
    if (full !== root && !full.startsWith(root + sep)) throw new Error("listing prefix escapes the uploads directory");
    return full;
  }

  async function walk(directory: string, found: StoredFile[]): Promise<void> {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error: unknown) {
      if (error instanceof Error && "code" in error && error.code === "ENOENT") return;
      throw error;
    }
    for (const entry of entries) {
      const path = join(directory, entry.name);
      if (entry.isDirectory()) await walk(path, found);
      else if (entry.isFile()) {
        found.push({ key: relative(root, path).split(sep).join("/"), modifiedAt: (await stat(path)).mtime });
      }
    }
  }

  return {
    ...files,
    async list(prefix) {
      const found: StoredFile[] = [];
      await walk(directoryOf(prefix), found);
      return found;
    },
  };
}
