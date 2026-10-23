// How profile_photos.url (the storage key) and users.picture are interpreted.

export const GOOGLE_AVATAR_HOST = "lh3.googleusercontent.com";

export type StoredUrlKind = "external" | "legacy" | "local";

const LOCAL_KEY = /^photos\/[0-9a-f-]{36}\.jpg$/;
const LEGACY_KEY = /^\/uploads\/profiles\/\d+\/[A-Za-z0-9._-]+$/;

export function newPhotoKey(uuid: string): string {
  return `photos/${uuid}.jpg`;
}

// "external": rows written before the socle, pointing at third-party hosts.
// "legacy": files uploaded before the socle, never re-encoded.
// "local": files produced by the upload pipeline.
export function classifyStoredUrl(url: string): StoredUrlKind | "invalid" {
  if (/^https?:/i.test(url)) return "external";
  if (LOCAL_KEY.test(url)) return "local";
  if (LEGACY_KEY.test(url) && !url.includes("..")) return "legacy";
  return "invalid";
}

// Returns the parsed URL only for https://lh3.googleusercontent.com/…, with
// the exact host, default port and no credentials.
export function parseGoogleAvatar(raw: string | null): URL | null {
  if (raw === null) return null;
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return null;
  }
  const ok =
    url.protocol === "https:" &&
    url.hostname === GOOGLE_AVATAR_HOST &&
    url.port === "" &&
    url.username === "" &&
    url.password === "";
  return ok ? url : null;
}
