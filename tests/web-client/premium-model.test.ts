import { describe, expect, test } from "bun:test";
import { ApiError } from "../../web/src/shared/api/errors";
import type { BillingCatalog, BillingStatus, Offer } from "../../web/src/shared/api/types";
import { canPay, checkoutErrorMessage, defaultOffer, packLabel, perMonthLabel, plusView, priceLabel, subscriptionOffers } from "../../web/src/features/premium/premium-model";

const flat = (text: string | null) => text?.replace(/[  ]/g, " ") ?? null;
const sub = (id: Offer["id"], months: number, cents: number, perMonth: number, featured = false): Offer => ({ id, kind: "subscription", months, amount_ttc_cents: cents, per_month_ttc_cents: perMonth, featured });
const catalog: BillingCatalog = {
  success: true, available: true, currency: "eur", withdrawal: { text: "Je renonce", version: "v1" },
  offers: [sub("plus_12m", 12, 9999, 833), sub("plus_3m", 3, 4499, 1500, true), sub("plus_1m", 1, 1999, 1999), sub("plus_6m", 6, 6999, 1167),
    { id: "superlikes_5", kind: "credits", credit_kind: "super_like", quantity: 5, amount_ttc_cents: 499, featured: false }],
};

describe("prices", () => {
  test("a price carries TTC and the per-month figure", () => {
    expect(flat(priceLabel(4499))).toBe("44,99 € TTC");
    expect(flat(perMonthLabel(sub("plus_3m", 3, 4499, 1500)))).toBe("soit 15,00 € / mois");
  });
  test("a pack has no per-month figure", () => {
    expect(perMonthLabel({ id: "boost_1", kind: "credits", credit_kind: "boost", quantity: 1, amount_ttc_cents: 799, featured: false })).toBeNull();
    expect(packLabel({ id: "superlikes_5", kind: "credits", credit_kind: "super_like", quantity: 5, amount_ttc_cents: 499, featured: false })).toBe("5 Super Likes");
  });
});

describe("offers", () => {
  test("subscriptions are listed shortest first", () => {
    expect(subscriptionOffers(catalog).map((offer) => offer.months)).toEqual([1, 3, 6, 12]);
  });
  test("the highlighted offer (3 months) is chosen when one can subscribe", () => {
    expect(defaultOffer(catalog, true)).toBe("plus_3m");
  });
  test("nothing is chosen when a subscription already exists", () => {
    expect(defaultOffer(catalog, false)).toBeNull();
  });
});

describe("pay button", () => {
  test("stays closed until the waiver is ticked", () => {
    expect(canPay({ selected: "plus_3m", waiver: false, busy: false })).toBe(false);
    expect(canPay({ selected: "plus_3m", waiver: true, busy: false })).toBe(true);
  });
  test("stays closed without an offer or while a payment starts", () => {
    expect(canPay({ selected: null, waiver: true, busy: false })).toBe(false);
    expect(canPay({ selected: "plus_3m", waiver: true, busy: true })).toBe(false);
  });
});

describe("checkout errors", () => {
  test("an Apple subscription is said to be managed by the App Store", () => {
    expect(checkoutErrorMessage(new ApiError(409, "already_subscribed", null, { source: "apple" }))).toBe("Votre abonnement mazl+ est géré par l'App Store.");
  });
  test("billing off, rate limit", () => {
    expect(checkoutErrorMessage(new ApiError(503, "billing_unavailable"))).toContain("bientôt disponible");
    expect(checkoutErrorMessage(new ApiError(429, "rate_limited"))).toContain("Trop de tentatives");
  });
});

describe("status", () => {
  const base: BillingStatus = { success: true, plus: { active: false, source: null, plan_type: null, expires_at: null, status: null }, stripe: { subscription: null, has_customer: false }, conflict: null, can_subscribe: true, blocked_reason: null };
  test("inactive", () => expect(plusView(base).kind).toBe("none"));
  test("Apple has no portal", () => {
    expect(plusView({ ...base, plus: { ...base.plus, active: true, source: "apple", expires_at: "2027-01-05T10:00:00Z" } }).kind).toBe("apple");
  });
  test("a Stripe subscription that will end says so", () => {
    const view = plusView({ ...base, plus: { ...base.plus, active: true, source: "stripe" }, stripe: { has_customer: true, subscription: { offer: "plus_3m", status: "active", current_period_end: "2027-01-05T10:00:00Z", cancel_at_period_end: true } } });
    expect(view).toMatchObject({ kind: "stripe", canceling: true });
    expect(view.kind === "stripe" && view.line).toContain("Résiliation prévue le");
  });
});
