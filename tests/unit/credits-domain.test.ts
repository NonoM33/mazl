import { describe, expect, test } from "bun:test";
import { dailyAllowance, chooseDebitSource } from "../../src/features/credits/domain/allowance";
import { CREDIT_PRODUCTS, creditProductFor } from "../../src/features/credits/domain/catalog";
import { buildCredits } from "../../src/features/credits/domain/view";

// The numbers below come from docs/premium/CREDITS.md, not from the code.

describe("catalogue", () => {
  test("sells exactly the four consumables of the contract", () => {
    expect(CREDIT_PRODUCTS.map((p) => [p.productId, p.kind, p.quantity])).toEqual([
      ["com.mazl.app.boost.1", "boost", 1],
      ["com.mazl.app.boost.3", "boost", 3],
      ["com.mazl.app.superlikes.5", "super_like", 5],
      ["com.mazl.app.superlikes.15", "super_like", 15],
    ]);
  });

  test("looks a product up by id, and refuses what it does not sell", () => {
    expect(creditProductFor("com.mazl.app.superlikes.15")).toEqual({ productId: "com.mazl.app.superlikes.15", kind: "super_like", quantity: 15 });
    expect(creditProductFor("com.mazl.app.plus.1m")).toBeUndefined();
    expect(creditProductFor("toString")).toBeUndefined();
  });
});

describe("daily allowance", () => {
  test("free: 1 super like, 0 boost", () => {
    expect(dailyAllowance(false, "super_like")).toBe(1);
    expect(dailyAllowance(false, "boost")).toBe(0);
  });

  test("mazl+: 5 super likes, 1 boost", () => {
    expect(dailyAllowance(true, "super_like")).toBe(5);
    expect(dailyAllowance(true, "boost")).toBe(1);
  });
});

describe("debit order", () => {
  test("the allowance of the day goes first", () => {
    expect(chooseDebitSource({ allowance: 5, dailyUsed: 0, purchasedBalance: 12 })).toBe("daily");
    expect(chooseDebitSource({ allowance: 5, dailyUsed: 4, purchasedBalance: 12 })).toBe("daily");
  });

  test("then the purchased credits", () => {
    expect(chooseDebitSource({ allowance: 5, dailyUsed: 5, purchasedBalance: 12 })).toBe("purchased");
    expect(chooseDebitSource({ allowance: 0, dailyUsed: 0, purchasedBalance: 1 })).toBe("purchased");
  });

  test("nothing left: undefined", () => {
    expect(chooseDebitSource({ allowance: 1, dailyUsed: 1, purchasedBalance: 0 })).toBeUndefined();
    expect(chooseDebitSource({ allowance: 0, dailyUsed: 0, purchasedBalance: 0 })).toBeUndefined();
  });

  test("a negative balance (refunded pack) is never spendable", () => {
    expect(chooseDebitSource({ allowance: 0, dailyUsed: 0, purchasedBalance: -2 })).toBeUndefined();
  });

  test("a day over its allowance (plus lapsed to free) does not go negative", () => {
    expect(chooseDebitSource({ allowance: 1, dailyUsed: 4, purchasedBalance: 0 })).toBeUndefined();
  });
});

describe("credits view", () => {
  const resetsAt = new Date("2026-10-25T00:00:00.000Z");

  test("matches the shape of the contract", () => {
    expect(
      buildCredits({
        isPlus: true,
        dailyUsed: { super_like: 2, boost: 1 },
        balances: { super_like: 12, boost: 2 },
        resetsAt,
      }),
    ).toEqual({
      super_like: { daily_allowance: 5, daily_remaining: 3, purchased_balance: 12, available: 15 },
      boost: { daily_allowance: 1, daily_remaining: 0, purchased_balance: 2, available: 2 },
      resets_at: "2026-10-25T00:00:00.000Z",
    });
  });

  test("available counts a negative balance as zero but still reports it", () => {
    const view = buildCredits({ isPlus: false, dailyUsed: { super_like: 0, boost: 0 }, balances: { super_like: -3, boost: 0 }, resetsAt });
    expect(view.super_like).toEqual({ daily_allowance: 1, daily_remaining: 1, purchased_balance: -3, available: 1 });
    expect(view.boost).toEqual({ daily_allowance: 0, daily_remaining: 0, purchased_balance: 0, available: 0 });
  });

  test("daily_remaining never goes below zero", () => {
    const view = buildCredits({ isPlus: false, dailyUsed: { super_like: 4, boost: 0 }, balances: { super_like: 0, boost: 0 }, resetsAt });
    expect(view.super_like.daily_remaining).toBe(0);
  });
});
