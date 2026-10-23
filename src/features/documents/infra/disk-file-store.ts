import { mkdir, readdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, resolve, sep } from "node:path";
import type { DocumentFileStore } from "../application/ports";

// <uploads>/<id>-<type>-<uuid>.<ext>: how plaintext files were named before.
const LEGACY_NAME = /^\d+-[A-Za-z0-9_-]+-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[A-Za-z0-9]+$/;

export class UnsafePathError extends Error {
  constructor() {
    super("path escapes the uploads directory");
    this.name = "UnsafePathError";
  }
}

export class DiskFileStore implements DocumentFileStore {
  private readonly root: string;

  constructor(uploadsDir: string) {
    this.root = resolve(uploadsDir);
  }

  private pathFor(fileName: string): string {
    const full = resolve(this.root, fileName);
    if (!full.startsWith(this.root + sep)) throw new UnsafePathError();
    return full;
  }

  async write(fileName: string, bytes: Uint8Array): Promise<void> {
    const target = this.pathFor(fileName);
    await mkdir(dirname(target), { recursive: true, mode: 0o700 });
    // Write then rename, so a reader never sees a half-written file.
    const partial = `${target}.partial`;
    await writeFile(partial, bytes, { mode: 0o600 });
    await rename(partial, target);
  }

  async read(fileName: string): Promise<Uint8Array | null> {
    const target = this.pathFor(fileName);
    try {
      return await readFile(target);
    } catch (error) {
      if (isNotFound(error)) return null;
      throw error;
    }
  }

  async remove(fileName: string): Promise<void> {
    await rm(this.pathFor(fileName), { force: true });
  }

  async listLegacyFiles(): Promise<string[]> {
    const entries = await readdir(this.root, { withFileTypes: true }).catch((error: unknown) => {
      if (isNotFound(error)) return [];
      throw error;
    });
    return entries.filter((e) => e.isFile() && LEGACY_NAME.test(e.name)).map((e) => e.name);
  }
}

function isNotFound(error: unknown): boolean {
  return typeof error === "object" && error !== null && (error as { code?: string }).code === "ENOENT";
}
