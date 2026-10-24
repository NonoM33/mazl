import { describe, expect, test } from "bun:test";
import { base32Decode, base32Encode } from "../../src/features/staff/domain/base32";
import { generateSecret, otpauthUri, totpAt, verifyTotp } from "../../src/features/staff/domain/totp";

// RFC 6238 Appendix B, SHA-1 rows. Secret = ASCII "12345678901234567890".
const RFC_SECRET = new TextEncoder().encode("12345678901234567890");
const RFC_VECTORS: readonly [number, string][] = [
  [59, "94287082"],
  [1111111109, "07081804"],
  [1111111111, "14050471"],
  [1234567890, "89005924"],
  [2000000000, "69279037"],
  [20000000000, "65353130"],
];

describe("TOTP against RFC 6238 appendix B", () => {
  for (const [time, expected] of RFC_VECTORS) {
    test(`T=${time} gives ${expected} (8 digits) and ${expected.slice(2)} (6 digits)`, () => {
      expect(totpAt(RFC_SECRET, time, 8)).toBe(expected);
      expect(totpAt(RFC_SECRET, time)).toBe(expected.slice(2));
    });
  }

  test("the step boundary is at multiples of 30 seconds", () => {
    expect(totpAt(RFC_SECRET, 59)).toBe(totpAt(RFC_SECRET, 30));
    expect(totpAt(RFC_SECRET, 59)).not.toBe(totpAt(RFC_SECRET, 60));
  });
});

describe("verifyTotp", () => {
  const at = (seconds: number) => new Date(seconds * 1000);

  test("accepts the current code and returns its step", () => {
    expect(verifyTotp(RFC_SECRET, "287082", at(59))).toBe(1);
  });

  test("accepts one step of drift each way, no more", () => {
    // 287082 is the code of step 1 (T=30..59).
    expect(verifyTotp(RFC_SECRET, "287082", at(89))).toBe(1); // now in step 2
    expect(verifyTotp(RFC_SECRET, "287082", at(29))).toBe(1); // now in step 0
    expect(verifyTotp(RFC_SECRET, "287082", at(120))).toBeNull(); // now in step 4
    expect(verifyTotp(RFC_SECRET, "287082", at(89), 0)).toBeNull();
  });

  test("refuses wrong, malformed and empty codes", () => {
    expect(verifyTotp(RFC_SECRET, "287083", at(59))).toBeNull();
    expect(verifyTotp(RFC_SECRET, "28708", at(59))).toBeNull();
    expect(verifyTotp(RFC_SECRET, "2870820", at(59))).toBeNull();
    expect(verifyTotp(RFC_SECRET, "28708a", at(59))).toBeNull();
    expect(verifyTotp(RFC_SECRET, "", at(59))).toBeNull();
    expect(verifyTotp(RFC_SECRET, " 287082", at(59))).toBeNull();
  });

  test("a code of another secret is refused", () => {
    expect(verifyTotp(new TextEncoder().encode("ABCDEFGHIJKLMNOPQRST"), "287082", at(59))).toBeNull();
  });
});

describe("base32, RFC 4648 section 10 vectors", () => {
  const vectors: readonly [string, string][] = [
    ["", ""],
    ["f", "MY"],
    ["fo", "MZXQ"],
    ["foo", "MZXW6"],
    ["foob", "MZXW6YQ"],
    ["fooba", "MZXW6YTB"],
    ["foobar", "MZXW6YTBOI"],
  ];
  for (const [plain, encoded] of vectors) {
    test(`"${plain}" <-> ${encoded}`, () => {
      expect(base32Encode(new TextEncoder().encode(plain))).toBe(encoded);
      expect(new TextDecoder().decode(base32Decode(encoded))).toBe(plain);
    });
  }

  test("decoding tolerates padding, spaces and lower case", () => {
    expect(new TextDecoder().decode(base32Decode("mzxw 6ytb oi======"))).toBe("foobar");
  });

  test("decoding refuses characters outside the alphabet", () => {
    expect(() => base32Decode("MZXW1")).toThrow();
  });

  test("the RFC 6238 secret in base32", () => {
    expect(base32Encode(RFC_SECRET)).toBe("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ");
  });
});

describe("secret and otpauth URI", () => {
  test("a secret is 20 bytes from the injected random source", () => {
    let asked = 0;
    const secret = generateSecret((size) => {
      asked = size;
      return new Uint8Array(size).fill(7);
    });
    expect(asked).toBe(20);
    expect([...secret]).toEqual(new Array(20).fill(7));
  });

  test("two generated secrets differ", () => {
    expect(generateSecret()).not.toEqual(generateSecret());
  });

  test("the URI names the issuer, the account and the base32 secret", () => {
    const uri = new URL(otpauthUri("jeanne@example.com", RFC_SECRET));
    expect(uri.protocol).toBe("otpauth:");
    expect(uri.host).toBe("totp");
    expect(decodeURIComponent(uri.pathname)).toBe("/MAZL Staff:jeanne@example.com");
    expect(uri.searchParams.get("secret")).toBe("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ");
    expect(uri.searchParams.get("issuer")).toBe("MAZL Staff");
    expect(uri.searchParams.get("digits")).toBe("6");
    expect(uri.searchParams.get("period")).toBe("30");
  });
});
