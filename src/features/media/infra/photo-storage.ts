import type { ObjectStore } from "../../../shared/storage/object-store";
import type { PhotoStorage } from "../application/ports";

// Profile photos live under `profiles/<user>/` in the object store (disk or
// bucket). They only leave through the signed /media route, never directly.
// The store refuses any key that would leave its prefix.
export function createPhotoStorage(store: ObjectStore): PhotoStorage {
  return {
    save: (key, bytes) => store.put(key, bytes),
    read: (key) => store.get(key),
    remove: (key) => store.delete(key),
  };
}
