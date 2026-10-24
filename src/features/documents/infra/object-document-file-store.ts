import type { ObjectStore } from "../../../shared/storage/object-store";
import type { DocumentFileStore } from "../application/ports";

// <uploads>/<id>-<type>-<uuid>.<ext>: how plaintext files were named before.
const LEGACY_NAME = /^\d+-[A-Za-z0-9_-]+-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[A-Za-z0-9]+$/;

// Identity documents (encrypted before they get here) in the object store.
export class ObjectDocumentFileStore implements DocumentFileStore {
  constructor(private readonly store: ObjectStore) {}

  write(fileName: string, bytes: Uint8Array): Promise<void> {
    return this.store.put(fileName, bytes);
  }

  read(fileName: string): Promise<Uint8Array | null> {
    return this.store.get(fileName);
  }

  remove(fileName: string): Promise<void> {
    return this.store.delete(fileName);
  }

  async listLegacyFiles(): Promise<string[]> {
    const topLevel = await this.store.list("", { recursive: false });
    return topLevel.map((object) => object.key).filter((key) => LEGACY_NAME.test(key));
  }
}
