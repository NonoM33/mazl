import { createHash, createHmac, randomBytes } from "node:crypto";
import { describe, expect, test } from "bun:test";
import { PowService } from "../../src/features/web-session/application/pow-service";
import { leadingZeroBits } from "../../src/features/web-session/domain/pow";
import { readConfig } from "../../src/features/web-session/application/config";
import { FakeClock } from "./support/web-session-fakes";

// Written from the rule in ADR-W03, not from the implementation: count the
// zero bits of a hex digest character by character.
function zeroBitsOfHex(hex: string): number {
  let bits = 0;
  for (const char of hex) {
    const nibble = Number.parseInt(char, 16);
    if (nibble === 0) {
      bits += 4;
      continue;
    }
    return bits + (nibble >= 8 ? 0 : nibble >= 4 ? 1 : nibble >= 2 ? 2 : 3);
  }
  return bits;
}

function solve(challenge: string, difficulty: number): string {
  for (let n = 0; ; n++) {
    const hex = createHash("sha256").update(`${challenge}:${n}`).digest("hex");
    if (zeroBitsOfHex(hex) >= difficulty) return String(n);
  }
}

const DIFFICULTY = 8;
function setup() {
  const clock = new FakeClock();
  return { clock, pow: new PowService(DIFFICULTY, clock.now) };
}

describe("leadingZeroBits", () => {
  test("counts bits across bytes", () => {
    expect(leadingZeroBits(Uint8Array.of(0x80))).toBe(0);
    expect(leadingZeroBits(Uint8Array.of(0x40))).toBe(1);
    expect(leadingZeroBits(Uint8Array.of(0x01))).toBe(7);
    expect(leadingZeroBits(Uint8Array.of(0x00, 0x0f))).toBe(12);
    expect(leadingZeroBits(Uint8Array.of(0x00, 0x00, 0x00))).toBe(24);
  });

  test("agrees with an independent hex count on real digests", () => {
    for (let n = 0; n < 200; n++) {
      const digest = createHash("sha256").update(`x${n}`).digest();
      expect(leadingZeroBits(digest)).toBe(zeroBitsOfHex(digest.toString("hex")));
    }
  });
});

describe("PowService", () => {
  test("accepts a solved challenge", () => {
    const { pow } = setup();
    const issued = pow.issue();
    expect(issued.difficulty).toBe(DIFFICULTY);
    expect(pow.verify({ challenge: issued.challenge, nonce: solve(issued.challenge, DIFFICULTY) })).toBeNull();
  });

  test("refuses a nonce that does not do the work", () => {
    const { pow } = setup();
    const { challenge } = pow.issue();
    const bad = Array.from({ length: 2000 }, (_, n) => String(n)).find(
      (n) => zeroBitsOfHex(createHash("sha256").update(`${challenge}:${n}`).digest("hex")) < DIFFICULTY,
    );
    expect(pow.verify({ challenge, nonce: bad ?? "x" })).toBe("insufficient");
  });

  test("refuses a replayed solution", () => {
    const { pow } = setup();
    const { challenge } = pow.issue();
    const nonce = solve(challenge, DIFFICULTY);
    expect(pow.verify({ challenge, nonce })).toBeNull();
    expect(pow.verify({ challenge, nonce })).toBe("replayed");
  });

  test("a failed attempt does not burn the challenge", () => {
    const { pow } = setup();
    const { challenge } = pow.issue();
    pow.verify({ challenge, nonce: "" });
    expect(pow.verify({ challenge, nonce: solve(challenge, DIFFICULTY) })).toBeNull();
  });

  test("refuses an expired challenge", () => {
    const { pow, clock } = setup();
    const { challenge } = pow.issue();
    const nonce = solve(challenge, DIFFICULTY);
    clock.advance(121_000);
    expect(pow.verify({ challenge, nonce })).toBe("expired");
  });

  test("still accepts just before the deadline", () => {
    const { pow, clock } = setup();
    const { challenge } = pow.issue();
    const nonce = solve(challenge, DIFFICULTY);
    clock.advance(119_000);
    expect(pow.verify({ challenge, nonce })).toBeNull();
  });

  test("refuses a challenge whose difficulty was lowered after signing", () => {
    const { pow } = setup();
    const { challenge } = pow.issue();
    const [encoded, signature] = challenge.split(".") as [string, string];
    const payload = JSON.parse(Buffer.from(encoded, "base64url").toString()) as { d: number };
    const forgedPayload = Buffer.from(JSON.stringify({ ...payload, d: 0 })).toString("base64url");
    expect(pow.verify({ challenge: `${forgedPayload}.${signature}`, nonce: "0" })).toBe("forged");
  });

  test("refuses a challenge signed with another key", () => {
    const { pow } = setup();
    const payload = Buffer.from(JSON.stringify({ s: "AAAA", d: 0, e: 4_000_000_000 })).toString("base64url");
    const signature = createHmac("sha256", randomBytes(32)).update(payload).digest("base64url");
    expect(pow.verify({ challenge: `${payload}.${signature}`, nonce: "" })).toBe("forged");
  });

  test("refuses malformed input", () => {
    const { pow } = setup();
    expect(pow.verify({ challenge: "nope", nonce: "1" })).toBe("malformed");
    expect(pow.verify({ challenge: "a.b.c", nonce: "1" })).toBe("malformed");
    const { challenge } = pow.issue();
    expect(pow.verify({ challenge, nonce: "9".repeat(33) })).toBe("malformed");
  });

  test("a challenge from another process (another key) is refused", () => {
    const first = setup().pow;
    const second = setup().pow;
    const { challenge } = first.issue();
    expect(second.verify({ challenge, nonce: solve(challenge, DIFFICULTY) })).toBe("forged");
  });

  test("difficulty 0 accepts any nonce but still spends the challenge once", () => {
    const pow = new PowService(0, new FakeClock().now);
    const { challenge } = pow.issue();
    expect(pow.verify({ challenge, nonce: "" })).toBeNull();
    expect(pow.verify({ challenge, nonce: "" })).toBe("replayed");
  });
});

describe("difficulty configuration", () => {
  test("defaults to 18", () => expect(readConfig({}).powDifficulty).toBe(18));
  test("reads WEB_POW_DIFFICULTY", () => expect(readConfig({ WEB_POW_DIFFICULTY: "8" }).powDifficulty).toBe(8));
  test("refuses out-of-range and non-integer values", () => {
    for (const value of ["25", "-1", "1.5", "abc"]) {
      expect(() => readConfig({ WEB_POW_DIFFICULTY: value })).toThrow();
    }
  });
  test("refuses 0 in production but allows it elsewhere", () => {
    expect(() => readConfig({ WEB_POW_DIFFICULTY: "0", NODE_ENV: "production" })).toThrow();
    expect(readConfig({ WEB_POW_DIFFICULTY: "0", NODE_ENV: "development" }).powDifficulty).toBe(0);
  });
});
