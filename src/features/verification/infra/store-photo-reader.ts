import { StorageKeyError, type ObjectStore } from "../../../shared/storage/object-store";
import type { PhotoFileReader } from "./pg-profile-photo-store";

// Maps a storage key (`/uploads/profiles/1/a.jpg` or a bare relative key) to an
// object in the store. Anything that is a URL, or that would climb out of the
// store, is not readable (null); a store failure is an error, not a missing photo.
export function createStorePhotoReader(store: ObjectStore): PhotoFileReader {
  return async (storageKey) => {
    if (/^[a-z][a-z0-9+.-]*:/i.test(storageKey)) return null;
    const key = storageKey.replace(/^\/?uploads\//, "").replace(/^\/+/, "");
    try {
      return await store.get(key);
    } catch (error: unknown) {
      if (error instanceof StorageKeyError) return null;
      throw error;
    }
  };
}
