import { describe, expect, test } from "bun:test";
import { CatalogService } from "../../src/features/billing-web/application/catalog-service";
import { OFFERS, offerById } from "../../src/features/billing-web/domain/offers";
import { WITHDRAWAL_TEXT, WITHDRAWAL_VERSION } from "../../src/features/billing-web/domain/withdrawal";
import { CREDIT_PRODUCTS } from "../../src/features/credits/domain/catalog";
import { planTypeForProduct } from "../../src/features/subscriptions/domain/plan";
import { FakeGateway, SETTINGS } from "./support/billing-fakes";

function gatewayWithPrices(overrides: Record<string, number | null> = {}): FakeGateway {
  const gateway = new FakeGateway();
  const amounts: Record<string, number | null> = {
    price_plus_1m: 999, price_plus_3m: 2400, price_plus_6m: 4500, price_plus_12m: 7800,
    price_boost_1: 199, price_boost_3: 499, price_sl_5: 399, price_sl_15: 999, ...overrides,
  };
  for (const [id, unitAmount] of Object.entries(amounts)) {
    gateway.prices.set(id, { id, unitAmount, currency: "eur", taxBehavior: "inclusive" });
  }
  return gateway;
}

describe("offers", () => {
  test("eight offers with the documented ids", () => {
    expect(OFFERS.map((o) => o.id)).toEqual(["plus_1m", "plus_3m", "plus_6m", "plus_12m", "boost_1", "boost_3", "superlikes_5", "superlikes_15"]);
  });

  test("subscription plans map to the App Store plan types and product ids", () => {
    const plus = OFFERS.filter((o) => o.kind === "subscription");
    expect(plus.map((o) => o.planType)).toEqual(["monthly", "three_month", "six_month", "yearly"]);
    for (const offer of plus) expect(planTypeForProduct(offer.productId)).toBe(offer.planType);
  });

  test("credit offers reuse the product ids of the credits catalogue", () => {
    for (const offer of OFFERS.filter((o) => o.kind === "credits")) {
      const product = CREDIT_PRODUCTS.find((p) => p.productId === offer.productId);
      expect(product?.kind).toBe(offer.creditKind);
      expect(product?.quantity).toBe(offer.quantity);
    }
  });

  test("price variables are the ones of the ADR", () => {
    expect(OFFERS.map((o) => o.priceEnv)).toEqual([
      "STRIPE_PRICE_PLUS_1M", "STRIPE_PRICE_PLUS_3M", "STRIPE_PRICE_PLUS_6M", "STRIPE_PRICE_PLUS_12M",
      "STRIPE_PRICE_BOOST_1", "STRIPE_PRICE_BOOST_3", "STRIPE_PRICE_SUPERLIKES_5", "STRIPE_PRICE_SUPERLIKES_15",
    ]);
  });

  test("only plus_3m is featured, unknown ids are refused", () => {
    expect(OFFERS.filter((o) => o.featured).map((o) => o.id)).toEqual(["plus_3m"]);
    expect(offerById("plus_2m")).toBeUndefined();
  });

  test("the waiver text is the legal wording, versioned", () => {
    expect(WITHDRAWAL_VERSION).toBe("2026-10-24");
    expect(WITHDRAWAL_TEXT).toContain("L221-28 13°");
    expect(WITHDRAWAL_TEXT).toContain("14 jours");
  });
});

describe("catalogue", () => {
  const at = (iso: string) => () => new Date(iso);

  test("amounts come from Stripe, per-month is derived, plus_3m is featured", async () => {
    const view = await new CatalogService(gatewayWithPrices(), SETTINGS, at("2026-10-24T12:00:00Z")).catalog();
    expect(view.available).toBe(true);
    expect(view.currency).toBe("EUR");
    expect(view.withdrawal).toEqual({ text: WITHDRAWAL_TEXT, version: WITHDRAWAL_VERSION });
    const plus3 = view.offers.find((o) => o.id === "plus_3m");
    expect(plus3).toEqual({ id: "plus_3m", kind: "subscription", months: 3, amount_ttc_cents: 2400, featured: true, per_month_ttc_cents: 800 });
    const boost = view.offers.find((o) => o.id === "boost_3");
    expect(boost).toEqual({ id: "boost_3", kind: "credits", credit_kind: "boost", quantity: 3, amount_ttc_cents: 499, featured: false });
    expect(view.offers.find((o) => o.id === "superlikes_15")?.credit_kind).toBe("super_like");
  });

  test("the answer is cached for ten minutes, then read again", async () => {
    const gateway = gatewayWithPrices();
    let now = new Date("2026-10-24T12:00:00Z");
    const service = new CatalogService(gateway, SETTINGS, () => now);
    await service.catalog();
    await service.catalog();
    expect(gateway.priceReads).toBe(8);
    now = new Date("2026-10-24T12:09:59Z");
    await service.catalog();
    expect(gateway.priceReads).toBe(8);
    now = new Date("2026-10-24T12:10:01Z");
    await service.catalog();
    expect(gateway.priceReads).toBe(16);
  });

  test("an offer without a configured price, or without a fixed amount, is left out", async () => {
    const { plus_12m: _removed, ...prices } = SETTINGS.prices;
    const view = await new CatalogService(gatewayWithPrices({ price_boost_1: null }), { ...SETTINGS, prices }, at("2026-10-24T12:00:00Z")).catalog();
    expect(view.offers.map((o) => o.id)).not.toContain("plus_12m");
    expect(view.offers.map((o) => o.id)).not.toContain("boost_1");
    expect(view.offers).toHaveLength(6);
  });

  test("a price that is not tax inclusive is served but warned about", async () => {
    const gateway = gatewayWithPrices();
    gateway.prices.set("price_plus_1m", { id: "price_plus_1m", unitAmount: 999, currency: "eur", taxBehavior: "exclusive" });
    const warnings: string[] = [];
    const original = console.warn;
    console.warn = (message: string) => void warnings.push(message);
    try {
      await new CatalogService(gateway, SETTINGS, at("2026-10-24T12:00:00Z")).catalog();
    } finally {
      console.warn = original;
    }
    expect(warnings.some((w) => w.includes("price_plus_1m") && w.includes("not tax inclusive"))).toBe(true);
  });
});
