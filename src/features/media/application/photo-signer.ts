import { hmacBase64Url, safeEqual } from "../../../shared/crypto/signer";
import { blurSigningMessage, expiryFor, isExpired, parseExpiry, photoSigningMessage, sliceExpiryFor } from "../domain/signed-url";

function baseUrl(): string {
  return (process.env.PUBLIC_BASE_URL ?? "").replace(/\/+$/, "");
}

function signature(photoId: number, exp: number): string {
  return hmacBase64Url("MEDIA_SIGNING_KEY", photoSigningMessage(photoId, exp));
}

export function signPhotoUrl(photoId: number, nowMs: number = Date.now()): string {
  const exp = sliceExpiryFor(nowMs);
  return `${baseUrl()}/media/photos/${photoId}?exp=${exp}&sig=${signature(photoId, exp)}`;
}

export function verifyPhotoSignature(
  photoId: number,
  rawExp: string | undefined,
  sig: string | undefined,
  nowMs: number = Date.now(),
): boolean {
  const exp = parseExpiry(rawExp);
  if (exp === null || !sig || isExpired(exp, nowMs)) return false;
  return safeEqual(sig, signature(photoId, exp));
}

function blurSignature(photoId: number, exp: number): string {
  return hmacBase64Url("MEDIA_SIGNING_KEY", blurSigningMessage(photoId, exp));
}

// URL of the 48 px blurred variant of a photo: what a member without mazl+
// gets to see of someone who liked them.
export function signBlurredPhotoUrl(photoId: number, nowMs: number = Date.now()): string {
  const exp = expiryFor(nowMs);
  return `${baseUrl()}/media/photos/${photoId}/blur?exp=${exp}&sig=${blurSignature(photoId, exp)}`;
}

export function verifyBlurSignature(
  photoId: number,
  rawExp: string | undefined,
  sig: string | undefined,
  nowMs: number = Date.now(),
): boolean {
  const exp = parseExpiry(rawExp);
  if (exp === null || !sig || isExpired(exp, nowMs)) return false;
  return safeEqual(sig, blurSignature(photoId, exp));
}

// The id of the photo behind a signed URL of this server (sharp or blurred), or
// null for anything else (an avatar, a demo photo).
export function photoIdOfSignedUrl(url: unknown): number | null {
  if (typeof url !== "string") return null;
  const match = /\/media\/photos\/(\d{1,9})(?:\/blur)?\?/.exec(url);
  return match?.[1] === undefined ? null : Number(match[1]);
}
