// Ports of the media feature. Use cases depend on these interfaces only;
// adapters live in ../infra.

export interface ImageProcessor {
  // Always returns a metadata-free JPEG, long side <= 1600 px.
  // Throws PhotoRejectedError when the bytes are not a decodable raster image.
  toProfileJpeg(bytes: Uint8Array): Promise<Buffer>;
}

export interface PhotoStorage {
  save(key: string, bytes: Uint8Array): Promise<void>;
  // Returns null when the file does not exist.
  read(key: string): Promise<Uint8Array | null>;
  remove(key: string): Promise<void>;
}

export interface StoredPhoto {
  readonly id: number;
  readonly url: string;
  readonly is_primary: boolean;
  readonly position: number;
}

export interface PhotoRepository {
  addPhoto(input: { userId: number; key: string; isPrimary: boolean }): Promise<StoredPhoto>;
  findKey(photoId: number): Promise<string | null>;
  // Deletes the row and returns its storage key; throws when it is not the user's.
  deletePhoto(photoId: number, userId: number): Promise<string | null>;
  findUserPicture(userId: number): Promise<string | null>;
}

export interface RemoteImageFetcher {
  // Throws PictureImportError("fetch_failed" | "too_large").
  fetch(url: URL, limits: { timeoutMs: number; maxBytes: number }): Promise<Uint8Array>;
}

export interface LocationUpdateLog {
  // Atomically records one location change when the user made fewer than `max`
  // changes in the last `windowMs`. Returns false (nothing recorded) otherwise.
  tryRecord(userId: number, max: number, windowMs: number): Promise<boolean>;
  // The position currently stored for the user, if any.
  currentPosition(userId: number): Promise<{ latitude: number; longitude: number } | null>;
}
