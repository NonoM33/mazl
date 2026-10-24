import { describe, expect, test } from "bun:test";
import { mulberry32, seedFrom } from "../../src/features/matching/domain/random";

describe("mulberry32", () => {
  test("same seed, same stream; values in [0,1)", () => {
    const a = mulberry32(42);
    const b = mulberry32(42);
    for (let i = 0; i < 100; i++) {
      const v = a();
      expect(v).toBe(b());
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThan(1);
    }
  });
  test("different seeds differ", () => {
    expect(mulberry32(1)()).not.toBe(mulberry32(2)());
  });
  test("roughly uniform", () => {
    const r = mulberry32(7);
    let sum = 0;
    for (let i = 0; i < 5000; i++) sum += r();
    expect(Math.abs(sum / 5000 - 0.5)).toBeLessThan(0.02);
  });
});

describe("seedFrom", () => {
  test("FNV-1a 32 bits of the joined parts (known vector for 'a')", () => {
    // FNV-1a("a") = 0xe40c292c
    expect(seedFrom("a")).toBe(0xe40c292c);
    expect(seedFrom("")).toBe(0x811c9dc5);
  });
  test("deterministic, order and part boundaries matter", () => {
    expect(seedFrom("x", 1)).toBe(seedFrom("x", 1));
    expect(seedFrom("a", "b")).not.toBe(seedFrom("b", "a"));
    expect(seedFrom("ab", "c")).not.toBe(seedFrom("a", "bc"));
    expect(seedFrom(1, 2)).not.toBe(seedFrom(12));
  });
});
