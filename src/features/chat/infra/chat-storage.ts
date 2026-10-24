import type { ObjectStore } from "../../../shared/storage/object-store";
import type { FileStorage } from "../application/ports";

// Chat files live under `chat/` in the object store. The listing feeds the
// stray-file sweep; it stays inside the store and, on disk, never follows a
// symbolic link, so a planted link cannot make the sweep delete, or even look
// at, anything else.
export function createChatStorage(store: ObjectStore): FileStorage {
  return {
    save: (key, bytes) => store.put(key, bytes),
    read: (key) => store.get(key),
    remove: (key) => store.delete(key),
    list: (prefix) => store.list(prefix),
  };
}
