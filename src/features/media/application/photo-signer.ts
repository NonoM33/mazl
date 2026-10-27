import { hmacBase64Url, safeEqual } from "../../../shared/crypto/signer";
import { isExpired, parseExpiry, photoSigningMessage, sliceExpiryFor } from "../domain/signed-url";

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
