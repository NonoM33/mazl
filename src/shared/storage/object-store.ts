// The one port every stored file goes through: profile photos, chat files,
// identity documents. Keys are the relative paths historically used under
// UPLOADS_DIR (`profiles/7/a.jpg`, `chat/7/b.jpg`, `documents/x.enc`), so the
// same key names the same object on disk and in a bucket and a migration is a
// plain copy.

export interface StoredObject {
  readonly key: string;
  readonly modifiedAt: Date;
}

export interface ListOptions {
  // Default true: every object below the prefix. False: only the objects
  // directly inside it (no sub-directory).
  readonly recursive?: boolean;
}

export interface ObjectStore {
  put(key: string, bytes: Uint8Array): Promise<void>;
  // null when the object does not exist. Any other failure rejects.
  get(key: string): Promise<Uint8Array | null>;
  exists(key: string): Promise<boolean>;
  // Idempotent: an object that is already gone is not an error.
  delete(key: string): Promise<void>;
  // Regular objects below `prefix`, read as a directory ("chat" lists
  // "chat/..." and never "chatter/..."), sorted by key. Empty when the prefix
  // holds nothing. Rejects when the prefix climbs out of the store.
  list(prefix: string, options?: ListOptions): Promise<StoredObject[]>;
}

export class StorageKeyError extends Error {
  constructor(reason: string) {
    super(`invalid storage key: ${reason}`);
    this.name = "StorageKeyError";
  }
}

// Turns a caller key or prefix into its path segments. Empty and "." segments
// are dropped ("/a//b" is "a/b"), so a leading slash cannot reach outside the
// root; ".." anywhere, or a NUL byte, is refused rather than resolved: a key
// can never leave its prefix, whatever the backend.
export function keySegments(raw: string): string[] {
  if (raw.includes("\0")) throw new StorageKeyError("NUL byte");
  const segments = raw.split("/").filter((segment) => segment !== "" && segment !== ".");
  if (segments.includes("..")) throw new StorageKeyError("path escapes the storage root");
  return segments;
}

// The path segments of an object key: at least one.
export function objectKeySegments(raw: string): string[] {
  const segments = keySegments(raw);
  if (segments.length === 0) throw new StorageKeyError("empty key");
  return segments;
}

// The canonical key of an object.
export function normalizeKey(raw: string): string {
  return objectKeySegments(raw).join("/");
}

// The canonical directory of a listing: "" for the root, "a/b" otherwise.
export function normalizePrefix(raw: string): string {
  return keySegments(raw).join("/");
}
