import { afterEach, describe, expect, test } from "bun:test";
import { assertKeysConfigured, getKey, MissingKeyError, resetKeyCacheForTests } from "../../src/shared/crypto/keys";
import { open, seal, SealedDataError } from "../../src/shared/crypto/secret-box";
import { hmacHex, safeEqual } from "../../src/shared/crypto/signer";

const originalEnv = { ...process.env };

afterEach(() => {
  process.env = { ...originalEnv };
  resetKeyCacheForTests();
});

describe("keys", () => {
  test("production refuses to boot without keys", () => {
    process.env.NODE_ENV = "production";
    delete process.env.DATA_ENCRYPTION_KEY;
    expect(() => assertKeysConfigured()).toThrow(MissingKeyError);
  });

  test("a key that is not 32 bytes is rejected", () => {
    process.env.DATA_ENCRYPTION_KEY = Buffer.alloc(16).toString("base64");
    expect(() => getKey("DATA_ENCRYPTION_KEY")).toThrow(MissingKeyError);
  });

  test("development keys differ per purpose", () => {
    process.env.NODE_ENV = "development";
    delete process.env.MEDIA_SIGNING_KEY;
    delete process.env.DOC_FINGERPRINT_KEY;
    expect(getKey("MEDIA_SIGNING_KEY").equals(getKey("DOC_FINGERPRINT_KEY"))).toBe(false);
  });
});

describe("secret box (AES-256-GCM)", () => {
  const plaintext = new TextEncoder().encode("carte d'identite recto");

  test("round trip with the same context", () => {
    expect(open(seal(plaintext, "doc:1"), "doc:1").toString()).toBe("carte d'identite recto");
  });

  test("ciphertext does not contain the plaintext and uses a fresh IV", () => {
    const a = seal(plaintext, "doc:1");
    const b = seal(plaintext, "doc:1");
    expect(a.includes(Buffer.from(plaintext))).toBe(false);
    expect(a.equals(b)).toBe(false);
  });

  test("another context cannot open it", () => {
    expect(() => open(seal(plaintext, "doc:1"), "doc:2")).toThrow(SealedDataError);
  });

  test("a flipped bit is detected", () => {
    const sealed = seal(plaintext, "doc:1");
    sealed[20] = (sealed[20] ?? 0) ^ 0x01;
    expect(() => open(sealed, "doc:1")).toThrow(SealedDataError);
  });

  test("another key cannot open it", () => {
    const sealed = seal(plaintext, "doc:1");
    process.env.DATA_ENCRYPTION_KEY = Buffer.alloc(32, 7).toString("base64");
    resetKeyCacheForTests();
    expect(() => open(sealed, "doc:1")).toThrow(SealedDataError);
  });
});

describe("hmac", () => {
  test("is HMAC-SHA256 under the configured key (checked against Bun's hasher)", () => {
    process.env.DOC_FINGERPRINT_KEY = Buffer.alloc(32, 1).toString("base64");
    resetKeyCacheForTests();
    const expected = new Bun.CryptoHasher("sha256", Buffer.alloc(32, 1)).update("FRA|X123|900101").digest("hex");
    expect(hmacHex("DOC_FINGERPRINT_KEY", "FRA|X123|900101")).toBe(expected);
  });

  test("safeEqual", () => {
    expect(safeEqual("abc", "abc")).toBe(true);
    expect(safeEqual("abc", "abd")).toBe(false);
    expect(safeEqual("abc", "abcd")).toBe(false);
  });
});
