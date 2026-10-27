// Signed photo URLs, CONTRAT.md §2.1. Pure: the HMAC itself is computed in the
// application layer with the shared signer.

export const PHOTO_URL_TTL_SECONDS = 3600;

export function photoSigningMessage(photoId: number, exp: number): string {
  return `photo:${photoId}:${exp}`;
}

export function expiryFor(nowMs: number): number {
  return Math.floor(nowMs / 1000) + PHOTO_URL_TTL_SECONDS;
}

// Photo expiry is aligned on a slice boundary so that every URL signed within the
// same slice for the same photo is byte-identical: clients can cache on it.
// A URL is valid between one and two TTL from the moment it is issued.
export function sliceExpiryFor(nowMs: number): number {
  const nextSlice = (Math.floor(nowMs / 1000 / PHOTO_URL_TTL_SECONDS) + 1) * PHOTO_URL_TTL_SECONDS;
  return nextSlice + PHOTO_URL_TTL_SECONDS;
}

// Seconds a client may keep the bytes served for a URL expiring at `exp`.
export function maxAgeFor(exp: number, nowMs: number): number {
  return Math.max(0, exp - Math.floor(nowMs / 1000));
}

export function isExpired(exp: number, nowMs: number): boolean {
  return exp < Math.floor(nowMs / 1000);
}

// Digits only: rejects signs, decimals and exponents before Number() sees them.
export function parseExpiry(raw: string | undefined): number | null {
  if (raw === undefined || !/^\d{1,12}$/.test(raw)) return null;
  return Number(raw);
}
