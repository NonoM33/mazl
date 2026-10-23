import { createHash, createHmac } from "node:crypto";
import postgres from "postgres";
import sharp from "sharp";

// Shared helpers of the media integration tests. Needs a running server
// (TEST_API_URL) and direct access to its database to set verification state
// and to create rows the API cannot create (TEST_DATABASE_URL, then
// DATABASE_URL, then the local media dev database).
export const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

export const db = postgres(
  process.env.TEST_DATABASE_URL ??
    process.env.DATABASE_URL ??
    "postgres://postgres:postgres@127.0.0.1:55441/mazl_media",
);

export interface TestUser { id: number; token: string }

export const auth = (token: string): Record<string, string> => ({ Authorization: `Bearer ${token}` });
export const json = (token: string): Record<string, string> => ({ ...auth(token), "Content-Type": "application/json" });

export async function makeUser(label: string): Promise<TestUser> {
  const email = `media-${label}-${Date.now()}-${Math.floor(performance.now() * 1000)}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: `Media ${label}` }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}) failed: ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

// A JPEG that carries EXIF orientation, a recognisable text marker and GPS tags.
export const EXIF_MARKER = "SECRET-HOME-ADDRESS";
export async function jpegWithGps(width = 300, height = 100, orientation = 6): Promise<Buffer> {
  return sharp({ create: { width, height, channels: 3, background: { r: 20, g: 120, b: 200 } } })
    .jpeg()
    .withExif({
      IFD0: { ImageDescription: EXIF_MARKER, Copyright: EXIF_MARKER },
      IFD3: { GPSLatitudeRef: "N", GPSLatitude: "48/1 51/1 30/1", GPSLongitudeRef: "E", GPSLongitude: "2/1 17/1 40/1" },
    })
    .withMetadata({ orientation })
    .toBuffer();
}

export async function uploadPhoto(
  token: string,
  bytes: Uint8Array,
  options: { filename?: string; mime?: string; primary?: boolean } = {},
): Promise<Response> {
  const form = new FormData();
  form.append("photo", new File([bytes], options.filename ?? "photo.jpg", { type: options.mime ?? "image/jpeg" }));
  if (options.primary) form.append("is_primary", "true");
  return fetch(`${BASE_URL}/api/profile/photos`, { method: "POST", headers: auth(token), body: form });
}

export interface PhotoRow { id: number; url: string; is_primary?: boolean }

export async function uploadOk(token: string, bytes: Uint8Array, primary = false): Promise<PhotoRow> {
  const res = await uploadPhoto(token, bytes, { primary });
  const body = (await res.json()) as { success: boolean; photo?: PhotoRow };
  if (res.status !== 200 || !body.photo) throw new Error(`upload failed ${res.status}: ${JSON.stringify(body)}`);
  return body.photo;
}

// Contract §2.1, computed independently of the server code:
// sig = HMAC-SHA256(MEDIA_SIGNING_KEY, "photo:<id>:<exp>") in base64url.
// Without MEDIA_SIGNING_KEY the server derives its development key from
// SHA-256("mazl-development-only:MEDIA_SIGNING_KEY") (see shared/crypto/keys.ts).
export function craftSignedUrl(photoId: number, exp: number): string {
  const configured = process.env.MEDIA_SIGNING_KEY;
  const key = configured
    ? Buffer.from(configured, "base64")
    : createHash("sha256").update("mazl-development-only:MEDIA_SIGNING_KEY").digest();
  const sig = createHmac("sha256", key).update(`photo:${photoId}:${exp}`).digest("base64url");
  return `${BASE_URL}/media/photos/${photoId}?exp=${exp}&sig=${sig}`;
}

export function absolute(url: string): string {
  return url.startsWith("http") ? url : `${BASE_URL}${url}`;
}
