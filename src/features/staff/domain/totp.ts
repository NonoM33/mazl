import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { base32Encode } from "./base32";

// TOTP, RFC 6238 over HOTP, RFC 4226: HMAC-SHA1, 30 second steps, 6 digits.

export const TOTP_STEP_SECONDS = 30;
export const TOTP_DIGITS = 6;
export const TOTP_ISSUER = "MAZL Staff";
const SECRET_BYTES = 20;

export type RandomSource = (size: number) => Uint8Array;

export function generateSecret(random: RandomSource = randomBytes): Uint8Array {
  return Uint8Array.from(random(SECRET_BYTES));
}

// The time step (counter) a unix time in seconds falls in.
export function stepOf(unixSeconds: number): number {
  return Math.floor(unixSeconds / TOTP_STEP_SECONDS);
}

// HOTP(secret, counter), dynamic truncation of RFC 4226 section 5.3.
export function hotp(secret: Uint8Array, counter: number, digits: number = TOTP_DIGITS): string {
  const message = Buffer.alloc(8);
  message.writeBigUInt64BE(BigInt(counter));
  const digest = createHmac("sha1", secret).update(message).digest();
  const offset = (digest[digest.length - 1] ?? 0) & 0x0f;
  const binary =
    (((digest[offset] ?? 0) & 0x7f) << 24) |
    ((digest[offset + 1] ?? 0) << 16) |
    ((digest[offset + 2] ?? 0) << 8) |
    (digest[offset + 3] ?? 0);
  return String(binary % 10 ** digits).padStart(digits, "0");
}

export function totpAt(secret: Uint8Array, unixSeconds: number, digits: number = TOTP_DIGITS): string {
  return hotp(secret, stepOf(unixSeconds), digits);
}

function sameCode(given: string, expected: string): boolean {
  return given.length === expected.length && timingSafeEqual(Buffer.from(given), Buffer.from(expected));
}

// Returns the time step the code is valid for, or null. Steps within `window`
// of the current one are accepted (clock drift). The caller records the step
// to refuse a replay of the same code.
export function verifyTotp(secret: Uint8Array, code: string, now: Date, window: number = 1): number | null {
  if (!/^\d{6}$/.test(code)) return null;
  const current = stepOf(now.getTime() / 1000);
  let matched: number | null = null;
  // No early exit: the time taken does not tell which step matched.
  for (let step = current - window; step <= current + window; step += 1) {
    if (step >= 0 && sameCode(code, hotp(secret, step)) && (matched === null || step > matched)) matched = step;
  }
  return matched;
}

export function otpauthUri(email: string, secret: Uint8Array): string {
  const label = encodeURIComponent(`${TOTP_ISSUER}:${email}`);
  const parameters = new URLSearchParams({
    secret: base32Encode(secret),
    issuer: TOTP_ISSUER,
    algorithm: "SHA1",
    digits: String(TOTP_DIGITS),
    period: String(TOTP_STEP_SECONDS),
  });
  return `otpauth://totp/${label}?${parameters.toString()}`;
}
