// Signed photo URLs, CONTRAT.md §2.1. Pure: the HMAC itself is computed in the
// application layer with the shared signer.

export const PHOTO_URL_TTL_SECONDS = 3600;

export function photoSigningMessage(photoId: number, exp: number): string {
  return `photo:${photoId}:${exp}`;
}

export function expiryFor(nowMs: number): number {
  return Math.floor(nowMs / 1000) + PHOTO_URL_TTL_SECONDS;
}

export function isExpired(exp: number, nowMs: number): boolean {
  return exp < Math.floor(nowMs / 1000);
}

// Digits only: rejects signs, decimals and exponents before Number() sees them.
export function parseExpiry(raw: string | undefined): number | null {
  if (raw === undefined || !/^\d{1,12}$/.test(raw)) return null;
  return Number(raw);
}
