import { classifyStoredUrl, parseGoogleAvatar } from "../domain/stored-photo";
import { signPhotoUrl } from "./photo-signer";

// Turns stored rows into what API responses may expose. Imported by the
// monolith's queries, so it must stay free of database access.

export interface PhotoRef {
  readonly id: number;
  readonly url: string;
}

export function publicPhotoUrl(photo: PhotoRef, nowMs: number = Date.now()): string | null {
  const kind = classifyStoredUrl(photo.url);
  return kind === "local" || kind === "legacy" ? signPhotoUrl(photo.id, nowMs) : null;
}

export function publicAvatarUrl(picture: string | null): string | null {
  return parseGoogleAvatar(picture)?.toString() ?? null;
}

// Primary uploaded photo first, Google avatar as a fallback.
export function publicPicture(primary: PhotoRef | null, picture: string | null): string | null {
  const photo = primary ? publicPhotoUrl(primary) : null;
  return photo ?? publicAvatarUrl(picture);
}

export function publicPhotoUrls(photos: readonly PhotoRef[]): string[] {
  const urls: string[] = [];
  for (const photo of photos) {
    const url = publicPhotoUrl(photo);
    if (url !== null) urls.push(url);
  }
  return urls;
}

export interface PrimaryPhotoColumns {
  readonly primary_photo_id: number | null;
  readonly primary_photo_url: string | null;
  readonly picture: string | null;
}

// Replaces the raw `picture` column by what may be exposed and drops the helper
// columns selected by primaryPhotoColumns().
export function withPublicPicture<T extends PrimaryPhotoColumns>(
  row: T,
): Omit<T, "primary_photo_id" | "primary_photo_url"> {
  const { primary_photo_id, primary_photo_url, ...rest } = row;
  const primary =
    primary_photo_id !== null && primary_photo_url !== null
      ? { id: primary_photo_id, url: primary_photo_url }
      : null;
  return { ...rest, picture: publicPicture(primary, row.picture) };
}
