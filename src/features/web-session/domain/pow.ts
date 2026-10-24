import { createHash, createHmac } from "node:crypto";
import { constantTimeEqual } from "./hashing";
import type { PowFailure } from "./errors";

// Proof of work: the browser must find a nonce so that
// SHA-256(`${challenge}:${nonce}`) starts with `difficulty` zero bits.
// The challenge is `<payload base64url>.<hmac base64url>`, signed with a
// per-process key, so the server keeps no state for challenges it issued.

export const MAX_DIFFICULTY = 24;
export const DEFAULT_DIFFICULTY = 18;
export const CHALLENGE_TTL_SECONDS = 120;
export const NONCE_MAX_LENGTH = 32;

interface ChallengePayload {
  readonly s: string;
  readonly d: number;
  readonly e: number;
}

export interface IssuedChallenge {
  readonly challenge: string;
  readonly difficulty: number;
  readonly expiresAt: number;
}

export type ChallengeCheck =
  | { readonly ok: true; readonly expiresAt: number }
  | { readonly ok: false; readonly reason: PowFailure };

function sign(key: Buffer, payload: string): string {
  return createHmac("sha256", key).update(payload).digest("base64url");
}

export function issueChallenge(key: Buffer, salt: Buffer, difficulty: number, nowSeconds: number): IssuedChallenge {
  const expiresAt = nowSeconds + CHALLENGE_TTL_SECONDS;
  const payload: ChallengePayload = { s: salt.toString("base64url"), d: difficulty, e: expiresAt };
  const encoded = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return { challenge: `${encoded}.${sign(key, encoded)}`, difficulty, expiresAt };
}

export function leadingZeroBits(digest: Uint8Array): number {
  let bits = 0;
  for (const byte of digest) {
    if (byte === 0) {
      bits += 8;
      continue;
    }
    return bits + Math.clz32(byte) - 24;
  }
  return bits;
}

function isPayload(value: unknown): value is ChallengePayload {
  if (typeof value !== "object" || value === null) return false;
  const { s, d, e } = value as Record<string, unknown>;
  return (
    typeof s === "string" &&
    typeof d === "number" &&
    Number.isInteger(d) &&
    d >= 0 &&
    d <= MAX_DIFFICULTY &&
    typeof e === "number" &&
    Number.isInteger(e)
  );
}

function decodePayload(encoded: string): ChallengePayload | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(encoded, "base64url").toString("utf8"));
    return isPayload(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

// Checks signature, expiry and the work itself. Replay is the caller's job.
export function checkSolution(key: Buffer, challenge: string, nonce: string, nowSeconds: number): ChallengeCheck {
  const parts = challenge.split(".");
  const [encoded, signature] = parts;
  if (parts.length !== 2 || !encoded || !signature || nonce.length > NONCE_MAX_LENGTH) {
    return { ok: false, reason: "malformed" };
  }
  if (!constantTimeEqual(signature, sign(key, encoded))) return { ok: false, reason: "forged" };
  const payload = decodePayload(encoded);
  if (!payload) return { ok: false, reason: "malformed" };
  if (payload.e <= nowSeconds) return { ok: false, reason: "expired" };
  const digest = createHash("sha256").update(`${challenge}:${nonce}`, "utf8").digest();
  if (leadingZeroBits(digest) < payload.d) return { ok: false, reason: "insufficient" };
  return { ok: true, expiresAt: payload.e };
}
