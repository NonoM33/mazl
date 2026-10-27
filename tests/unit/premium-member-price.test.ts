import { describe, expect, test } from "bun:test";
import { isReduction, priceInCents, readMemberPrice } from "../../src/features/events/domain/member-price";

// docs/premium/MONETISATION.md section 10: whole cents, never above the normal price.

describe("member price of an event", () => {
  test("absent leaves it, null removes it, a whole number of cents sets it", () => {
    expect(readMemberPrice(undefined)).toEqual({ kind: "unchanged" });
    expect(readMemberPrice(null)).toEqual({ kind: "remove" });
    expect(readMemberPrice(800)).toEqual({ kind: "set", cents: 800 });
    expect(readMemberPrice(0)).toEqual({ kind: "set", cents: 0 });
  });

  test("decimals, negatives, text, NaN and absurd amounts are invalid", () => {
    for (const raw of [8.5, -1, "800", Number.NaN, Number.POSITIVE_INFINITY, 10_000_001, true, {}]) {
      expect([raw, readMemberPrice(raw).kind]).toEqual([raw, "invalid"]);
    }
  });

  test("the price column is a decimal, read in cents", () => {
    expect(priceInCents("12.50")).toBe(1250);
    expect(priceInCents(12.5)).toBe(1250);
    expect(priceInCents("0.10")).toBe(10);
    expect(priceInCents("n/a")).toBe(0);
  });

  test("a member rate above the price is a surcharge, not a reduction", () => {
    expect(isReduction(800, "12.50")).toBe(true);
    expect(isReduction(1250, "12.50")).toBe(true);
    expect(isReduction(1251, "12.50")).toBe(false);
    expect(isReduction(100, 0)).toBe(false);
  });
});
