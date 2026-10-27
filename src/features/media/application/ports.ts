// Ports of the media feature. Use cases depend on these interfaces only;
// adapters live in ../infra.

export interface ImageProcessor {
  // Always returns a metadata-free JPEG, long side <= 1600 px.
  // Throws PhotoRejectedError when the bytes are not a decodable raster image.
  toProfileJpeg(bytes: Uint8Array): Promise<Buffer>;
  // A tiny (48 px wide) heavily blurred JPEG: enough to see a colour and a
  // silhouette, impossible to sharpen back into a face.
  toBlurredJpeg(bytes: Uint8Array): Promise<Buffer>;
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
  // Storage keys (url column) of every profile photo of the user.
  listUserKeys(userId: number): Promise<string[]>;
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

export interface UnfuzzedPosition {
  readonly userId: number;
  readonly latitude: number;
  readonly longitude: number;
}

export interface LocationBackfillRepository {
  // Positions whose profile still has location_fuzzed = false.
  listUnfuzzed(limit: number): Promise<UnfuzzedPosition[]>;
  // Stores the fuzzed point and sets location_fuzzed. Returns false, changing
  // nothing, when the profile is already flagged.
  markFuzzed(userId: number, fuzzed: { latitude: number; longitude: number }): Promise<boolean>;
}
