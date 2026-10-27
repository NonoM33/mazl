import { describe, expect, test, beforeAll, afterAll } from "bun:test";
import { createHmac } from "node:crypto";
import { resetKeyCacheForTests } from "../../src/shared/crypto/keys";
import {
  PHOTO_URL_TTL_SECONDS,
  isExpired,
  maxAgeFor,
  parseExpiry,
} from "../../src/features/media/domain/signed-url";
import {
  signPhotoUrl,
  verifyPhotoSignature,
} from "../../src/features/media/application/photo-signer";

// Expected values come from CONTRAT.md §2.1:
//   sig = HMAC-SHA256(MEDIA_SIGNING_KEY, "photo:<photoId>:<exp>"), base64url,
//   validity 1 hour.
const KEY_B64 = Buffer.alloc(32, 7).toString("base64");
const NOW_MS = 1_800_000_000_000;
const NOW_S = 1_800_000_000;

function contractSignature(photoId: number, exp: number): string {
  return createHmac("sha256", Buffer.alloc(32, 7)).update(`photo:${photoId}:${exp}`).digest("base64url");
}

describe("signed photo URLs (contract 2.1)", () => {
  const previous = process.env.MEDIA_SIGNING_KEY;
  const previousBase = process.env.PUBLIC_BASE_URL;
  beforeAll(() => {
    process.env.MEDIA_SIGNING_KEY = KEY_B64;
    delete process.env.PUBLIC_BASE_URL;
    resetKeyCacheForTests();
  });
  afterAll(() => {
    if (previous === undefined) delete process.env.MEDIA_SIGNING_KEY;
    else process.env.MEDIA_SIGNING_KEY = previous;
    if (previousBase !== undefined) process.env.PUBLIC_BASE_URL = previousBase;
    resetKeyCacheForTests();
  });

  test("lifetime is one hour", () => {
    expect(PHOTO_URL_TTL_SECONDS).toBe(3600);
  });

  test("relative URL carries the slice expiry and the contract HMAC", () => {
    const url = signPhotoUrl(12, NOW_MS);
    const exp = (Math.floor(NOW_S / 3600) + 2) * 3600;
    expect(url).toBe(`/media/photos/12?exp=${exp}&sig=${contractSignature(12, exp)}`);
  });

  test("absolute URL when PUBLIC_BASE_URL is set (trailing slash tolerated)", () => {
    process.env.PUBLIC_BASE_URL = "https://api.mazl.example/";
    try {
      expect(signPhotoUrl(5, NOW_MS).startsWith("https://api.mazl.example/media/photos/5?exp=")).toBe(true);
    } finally {
      delete process.env.PUBLIC_BASE_URL;
    }
  });

  test("the same photo keeps the same URL within a slice, a new one in the next slice", () => {
    const sliceStart = Math.floor(NOW_S / 3600) * 3600 * 1000;
    const first = signPhotoUrl(12, sliceStart);
    expect(signPhotoUrl(12, sliceStart + 1_800_000)).toBe(first);
    expect(signPhotoUrl(12, sliceStart + 3_599_000)).toBe(first);
    expect(signPhotoUrl(12, sliceStart + 3_600_000)).not.toBe(first);
    expect(signPhotoUrl(13, sliceStart)).not.toBe(first);
  });

  test("a URL stays valid at least one hour and is refused after its expiry", () => {
    const sliceEnd = (Math.floor(NOW_S / 3600) + 1) * 3600 * 1000;
    const issuedLast = new URL(`http://x${signPhotoUrl(12, sliceEnd - 1000)}`);
    const exp = issuedLast.searchParams.get("exp") ?? "";
    const sig = issuedLast.searchParams.get("sig") ?? "";
    expect(Number(exp) * 1000 - (sliceEnd - 1000)).toBeGreaterThanOrEqual(3_600_000);
    expect(verifyPhotoSignature(12, exp, sig, sliceEnd - 1000 + 3_600_000)).toBe(true);
    expect(verifyPhotoSignature(12, exp, sig, Number(exp) * 1000 + 1000)).toBe(false);
  });

  test("max age is the time left until expiry", () => {
    expect(maxAgeFor(NOW_S + 500, NOW_MS)).toBe(500);
    expect(maxAgeFor(NOW_S - 5, NOW_MS)).toBe(0);
  });

  test("accepts the contract signature, rejects any other", () => {
    const exp = NOW_S + 100;
    expect(verifyPhotoSignature(12, String(exp), contractSignature(12, exp), NOW_MS)).toBe(true);
    expect(verifyPhotoSignature(13, String(exp), contractSignature(12, exp), NOW_MS)).toBe(false);
    expect(verifyPhotoSignature(12, String(exp + 1), contractSignature(12, exp), NOW_MS)).toBe(false);
    expect(verifyPhotoSignature(12, String(exp), "", NOW_MS)).toBe(false);
    expect(verifyPhotoSignature(12, String(exp), undefined, NOW_MS)).toBe(false);
  });

  test("an expired URL is refused even with a valid signature", () => {
    const exp = NOW_S - 1;
    expect(verifyPhotoSignature(12, String(exp), contractSignature(12, exp), NOW_MS)).toBe(false);
  });

  test("a malformed exp is refused", () => {
    for (const bad of ["", "abc", "-5", "1e9", "12.5", undefined]) {
      expect(verifyPhotoSignature(12, bad, "x", NOW_MS)).toBe(false);
    }
  });

  test("domain helpers", () => {
    expect(isExpired(NOW_S, NOW_MS + 1000)).toBe(true);
    expect(isExpired(NOW_S, NOW_MS)).toBe(false);
    expect(isExpired(NOW_S + 1, NOW_MS)).toBe(false);
    expect(parseExpiry("1800000000")).toBe(1_800_000_000);
    expect(parseExpiry("nope")).toBeNull();
  });
});
