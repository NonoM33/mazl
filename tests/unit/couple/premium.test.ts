import { describe, expect, test } from "bun:test";
import { coupleSubscriptionOf, NO_PREMIUM, type MemberSubscription } from "../../../src/features/couple/domain/premium";
import { planTypeForProduct } from "../../../src/features/subscriptions/domain/plan";
import { OFFERS, subscriptionOfferById } from "../../../src/features/billing-web/domain/offers";
import { readProductPolicy } from "../../../src/features/subscriptions/infra/config";
import { ROLE_PERMISSIONS } from "../../../src/features/staff/domain/roles";
import { stripeProductName } from "../../../src/features/storefront/infra/stripe/stripe-web-pricing";
import { CATALOG_PRODUCTS } from "../../../src/features/storefront/domain/products";

// Contract section 1: one partner pays, both have the rights.
const NOW = new Date("2026-10-27T12:00:00Z");
const day = (n: number) => new Date(NOW.getTime() + n * 86_400_000);
const sub = (userId: number, over: Partial<MemberSubscription> = {}): MemberSubscription => ({
  userId, planType: "couple_monthly", status: "active", expiresAt: day(20), ...over,
});

describe("MAZL Couple rights", () => {
  test("when only the partner pays, the caller is covered and told who pays", () => {
    expect(coupleSubscriptionOf(1, [sub(2)], NOW)).toEqual({ active: true, paidBy: "partner", renewsAt: day(20).toISOString() });
  });

  test("the payer sees themselves as the payer", () => {
    expect(coupleSubscriptionOf(2, [sub(2)], NOW).paidBy).toBe("me");
  });

  test("nobody pays: not active", () => {
    expect(coupleSubscriptionOf(1, [], NOW)).toEqual(NO_PREMIUM);
  });

  test("an expired subscription gives nothing, even for the payer", () => {
    expect(coupleSubscriptionOf(2, [sub(2, { expiresAt: day(-1) })], NOW).active).toBe(false);
    expect(coupleSubscriptionOf(1, [sub(2, { expiresAt: new Date(NOW.getTime()) })], NOW).active).toBe(false);
  });

  test("a refunded, expired or failing subscription gives nothing", () => {
    for (const status of ["revoked", "expired", "billing_issue"]) expect(coupleSubscriptionOf(1, [sub(2, { status })], NOW).active).toBe(false);
  });

  test("a plain mazl+ plan is not MAZL Couple: it does not cover the partner", () => {
    expect(coupleSubscriptionOf(1, [sub(2, { planType: "monthly" })], NOW).active).toBe(false);
  });
});

describe("the MAZL Couple product", () => {
  test("com.mazl.app.couple.1m is the couple_monthly plan; the plus products are unchanged", () => {
    expect(planTypeForProduct("com.mazl.app.couple.1m")).toBe("couple_monthly");
    expect(planTypeForProduct("com.mazl.app.plus.3m")).toBe("three_month");
    expect(planTypeForProduct("com.mazl.app.couple.3m")).toBe("unknown");
  });

  test("the App Store verification accepts it by default", () => {
    expect(readProductPolicy({}).productIds).toContain("com.mazl.app.couple.1m");
  });

  test("the web offer couple_1m is sold on STRIPE_PRICE_COUPLE_1M and shares the product id", () => {
    const offer = subscriptionOfferById("couple_1m");
    expect(offer).toMatchObject({ productId: "com.mazl.app.couple.1m", planType: "couple_monthly", priceEnv: "STRIPE_PRICE_COUPLE_1M", months: 1 });
    expect(OFFERS.filter((o) => o.id === "couple_1m")).toHaveLength(1);
  });

  test("the storefront catalogue lists it, named MAZL Couple at Stripe", () => {
    expect(CATALOG_PRODUCTS.find((p) => p.productId === "com.mazl.app.couple.1m")).toMatchObject({ kind: "subscription", months: 1, priceEnv: "STRIPE_PRICE_COUPLE_1M" });
    expect(stripeProductName("com.mazl.app.couple.1m")).toBe("MAZL Couple");
  });
});

describe("staff permission concierge.manage", () => {
  test("admin and super-admin have it, nobody else", () => {
    expect(ROLE_PERMISSIONS.admin).toContain("concierge.manage");
    expect(ROLE_PERMISSIONS.super_admin).toContain("concierge.manage");
    for (const role of ["moderator", "verifier", "support", "analyst"] as const) expect(ROLE_PERMISSIONS[role]).not.toContain("concierge.manage");
  });
});
