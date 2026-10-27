// The blurred variants already made, kept for a few minutes so that a screen of
// likes does not decode a photo again for every refresh. Small by design: a
// variant is about 2 KB. The cache never decides who may see a photo: the route
// still checks the signature and the database before reading it.

export interface BlurCache {
  get(key: string, nowMs: number): Uint8Array | null;
  set(key: string, bytes: Uint8Array, nowMs: number): void;
}

export function createBlurCache(options: { readonly maxEntries: number; readonly ttlMs: number }): BlurCache {
  const entries = new Map<string, { readonly bytes: Uint8Array; readonly expiresAt: number }>();
  return {
    get(key, nowMs) {
      const hit = entries.get(key);
      if (hit === undefined) return null;
      if (hit.expiresAt <= nowMs) {
        entries.delete(key);
        return null;
      }
      // Most recently used goes last.
      entries.delete(key);
      entries.set(key, hit);
      return hit.bytes;
    },
    set(key, bytes, nowMs) {
      entries.delete(key);
      entries.set(key, { bytes, expiresAt: nowMs + options.ttlMs });
      while (entries.size > options.maxEntries) {
        const oldest = entries.keys().next();
        if (oldest.done === true) break;
        entries.delete(oldest.value);
      }
    },
  };
}
