import { readFile } from "node:fs/promises";
import { resolve, sep } from "node:path";
import type { PhotoFileReader } from "./pg-profile-photo-store";

// Maps a storage key (`/uploads/profiles/1/a.jpg` or a bare relative key) to a
// file under the uploads directory. Anything that is a URL, or that would
// resolve outside the directory, is not readable.
export function createLocalPhotoReader(uploadsDir: string): PhotoFileReader {
  const root = resolve(uploadsDir);
  return async (storageKey) => {
    if (/^[a-z][a-z0-9+.-]*:/i.test(storageKey)) return null;
    const relative = storageKey.replace(/^\/?uploads\//, "").replace(/^\/+/, "");
    const path = resolve(root, relative);
    if (!path.startsWith(root + sep)) return null;
    try {
      return new Uint8Array(await readFile(path));
    } catch (error: unknown) {
      if (error instanceof Error && "code" in error && (error.code === "ENOENT" || error.code === "EISDIR")) return null;
      throw error;
    }
  };
}
