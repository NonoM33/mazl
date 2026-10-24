import type { ObjectStore, StoredObject } from "./object-store";

// The migration bridge: S3 is the store of record, the legacy store (the old
// uploads directory) is consulted only for what S3 does not have yet. Files
// written before the switch stay readable while the copy script runs, so the
// deploy needs no downtime.
//  - writes go to the primary only;
//  - a read that finds nothing in the primary tries the legacy store once;
//  - an error from the primary is never answered with the legacy copy: a bucket
//    that fails is an error, not a missing file;
//  - deletes hit both, so an erased member leaves nothing on the old disk.
export function withLegacyFallback(primary: ObjectStore, legacy: ObjectStore): ObjectStore {
  return {
    put: (key, bytes) => primary.put(key, bytes),

    async get(key) {
      return (await primary.get(key)) ?? legacy.get(key);
    },

    async exists(key) {
      return (await primary.exists(key)) || legacy.exists(key);
    },

    async delete(key) {
      await primary.delete(key);
      await legacy.delete(key);
    },

    async list(prefix, options) {
      const [fromPrimary, fromLegacy] = await Promise.all([primary.list(prefix, options), legacy.list(prefix, options)]);
      const byKey = new Map<string, StoredObject>();
      for (const object of [...fromLegacy, ...fromPrimary]) byKey.set(object.key, object);
      return [...byKey.values()].sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));
    },
  };
}
