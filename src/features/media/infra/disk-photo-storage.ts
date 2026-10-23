import { mkdir, unlink } from "node:fs/promises";
import { dirname, join, resolve, sep } from "node:path";
import type { PhotoStorage } from "../application/ports";

// Photos live under the uploads directory, which the static guard in index.ts
// never serves directly: they only leave through the signed /media route.
export function createDiskPhotoStorage(uploadsDir: string): PhotoStorage {
  const root = resolve(uploadsDir);

  // Keys come from our own generator or from a validated legacy pattern; the
  // prefix check is a second line of defence against path traversal.
  function pathOf(key: string): string {
    const full = resolve(join(root, key));
    if (!full.startsWith(root + sep)) throw new Error("storage key escapes the uploads directory");
    return full;
  }

  return {
    async save(key, bytes) {
      const path = pathOf(key);
      await mkdir(dirname(path), { recursive: true });
      await Bun.write(path, bytes);
    },
    async read(key) {
      const file = Bun.file(pathOf(key));
      return (await file.exists()) ? new Uint8Array(await file.arrayBuffer()) : null;
    },
    async remove(key) {
      try {
        await unlink(pathOf(key));
      } catch (error: unknown) {
        if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) throw error;
      }
    },
  };
}
