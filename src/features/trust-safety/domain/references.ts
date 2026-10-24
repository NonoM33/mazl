// Statement references and appeal codes. Crockford base32: no I, L, O or U, so
// nothing reads ambiguously on a phone screen or over the phone.
const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

export const REFERENCE_PATTERN = /^MZ-\d{4}-[0-9A-HJKMNP-TV-Z]{6}$/;

export function encodeBase32(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => ALPHABET[byte & 31] ?? "0").join("");
}

// `bytes` must be random (6 bytes); the caller owns the randomness.
export function buildReference(year: number, bytes: Uint8Array): string {
  return `MZ-${year}-${encodeBase32(bytes.slice(0, 6))}`;
}

// `bytes` must be random (12 bytes). Shown once as XXXX-XXXX-XXXX.
export function buildAppealCode(bytes: Uint8Array): string {
  const raw = encodeBase32(bytes.slice(0, 12));
  return `${raw.slice(0, 4)}-${raw.slice(4, 8)}-${raw.slice(8, 12)}`;
}

// What the member types may differ in case, spaces and dashes.
export function normalizeAppealCode(input: string): string {
  return input.toUpperCase().replace(/[^0-9A-Z]/g, "");
}
