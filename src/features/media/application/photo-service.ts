import { randomUUID } from "node:crypto";
import type { PhotoFaceChecker } from "../../verification/application/ports";
import { PictureImportError } from "../domain/errors";
import { classifyStoredUrl, newPhotoKey, parseGoogleAvatar } from "../domain/stored-photo";
import type {
  ImageProcessor,
  PhotoRepository,
  PhotoStorage,
  RemoteImageFetcher,
  StoredPhoto,
} from "./ports";

const IMPORT_TIMEOUT_MS = 5000;
const IMPORT_MAX_BYTES = 10 * 1024 * 1024;

export interface PhotoServiceDeps {
  readonly processor: ImageProcessor;
  readonly storage: PhotoStorage;
  readonly repository: PhotoRepository;
  readonly fetcher: RemoteImageFetcher;
  readonly faceChecker: PhotoFaceChecker;
}

export interface PhotoService {
  upload(userId: number, bytes: Uint8Array, isPrimary: boolean): Promise<StoredPhoto>;
  importOauthPicture(userId: number, isPrimary: boolean): Promise<StoredPhoto>;
  remove(userId: number, photoId: number): Promise<void>;
  // Sanitised JPEG bytes of a stored photo, or null when there is none.
  serve(photoId: number): Promise<Uint8Array | null>;
}

// Legacy rows hold "/uploads/profiles/<user>/<file>"; the file lives under the
// uploads directory without the leading "/uploads/".
function storageKeyOf(url: string): string | null {
  const kind = classifyStoredUrl(url);
  if (kind === "local") return url;
  if (kind === "legacy") return url.replace(/^\/uploads\//, "");
  return null;
}

export function createPhotoService(deps: PhotoServiceDeps): PhotoService {
  const { processor, storage, repository, fetcher, faceChecker } = deps;

  async function checkFace(userId: number, photoId: number, bytes: Uint8Array): Promise<void> {
    try {
      await faceChecker.checkStoredPhoto(userId, photoId, bytes);
    } catch (error: unknown) {
      // The upload is kept: the photo simply stays unverified.
      console.error("Photo face check failed:", error instanceof Error ? error.name : "unknown");
    }
  }

  async function upload(userId: number, bytes: Uint8Array, isPrimary: boolean): Promise<StoredPhoto> {
    const jpeg = await processor.toProfileJpeg(bytes);
    const key = newPhotoKey(randomUUID());
    await storage.save(key, jpeg);
    let photo: StoredPhoto;
    try {
      photo = await repository.addPhoto({ userId, key, isPrimary });
    } catch (error: unknown) {
      await storage.remove(key);
      throw error;
    }
    await checkFace(userId, photo.id, jpeg);
    return photo;
  }

  async function importOauthPicture(userId: number, isPrimary: boolean): Promise<StoredPhoto> {
    const picture = await repository.findUserPicture(userId);
    if (picture === null || picture === "") throw new PictureImportError("no_picture");
    const url = parseGoogleAvatar(picture);
    if (url === null) throw new PictureImportError("host_not_allowed");
    const bytes = await fetcher.fetch(url, { timeoutMs: IMPORT_TIMEOUT_MS, maxBytes: IMPORT_MAX_BYTES });
    return upload(userId, bytes, isPrimary);
  }

  async function remove(userId: number, photoId: number): Promise<void> {
    const url = await repository.deletePhoto(photoId, userId);
    const key = url === null ? null : storageKeyOf(url);
    if (key !== null) await storage.remove(key);
  }

  async function serve(photoId: number): Promise<Uint8Array | null> {
    const url = await repository.findKey(photoId);
    const key = url === null ? null : storageKeyOf(url);
    if (key === null || url === null) return null;
    const bytes = await storage.read(key);
    if (bytes === null) return null;
    // Files uploaded before the socle still carry their metadata.
    return classifyStoredUrl(url) === "legacy" ? processor.toProfileJpeg(bytes) : bytes;
  }

  return { upload, importOauthPicture, remove, serve };
}
