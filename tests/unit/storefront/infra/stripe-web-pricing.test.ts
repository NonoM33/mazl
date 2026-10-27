import { describe, expect, test } from "bun:test";
import Stripe from "stripe";
import { createWebPricing, StripeWebPricing, WebPricingError } from "../../../../src/features/storefront/infra/stripe";

// A fake Stripe API behind the real SDK: it answers only the exact method + path + query/form body
// it was told about, so the test checks what really goes on the wire (Stripe's documented parameters).
interface Seen {
  readonly method: string;
  readonly path: string;
  readonly params: Record<string, string>;
}

function fakeStripe(routes: readonly { method: string; path: string; params?: Record<string, string>; status?: number; body: unknown }[]) {
  const seen: Seen[] = [];
  const unexpected: string[] = [];
  const fakeFetch = async (input: string | URL | Request, init?: RequestInit): Promise<Response> => {
    const url = new URL(String(input));
    const params: Record<string, string> = {};
    const raw = init?.method === "GET" || init?.method === undefined ? url.search.slice(1) : String(init.body ?? "");
    for (const [k, v] of new URLSearchParams(raw)) params[k] = v;
    const call = { method: init?.method ?? "GET", path: url.pathname, params };
    seen.push(call);
    const route = routes.find((r) => r.method === call.method && r.path === call.path && JSON.stringify(sorted(r.params ?? {})) === JSON.stringify(sorted(params)));
    if (route === undefined) {
      unexpected.push(`${call.method} ${call.path} ${JSON.stringify(params)}`);
      return new Response(JSON.stringify({ error: { type: "invalid_request_error", message: "unexpected test request" } }), { status: 400 });
    }
    return new Response(JSON.stringify(route.body), { status: route.status ?? 200, headers: { "content-type": "application/json" } });
  };
  const stripe = new Stripe("sk_test_fake", { httpClient: Stripe.createFetchHttpClient(fakeFetch as typeof fetch), maxNetworkRetries: 0 });
  return { pricing: new StripeWebPricing(stripe), seen, unexpected };
}

const sorted = (o: Record<string, string>): [string, string][] => Object.entries(o).sort(([a], [b]) => a.localeCompare(b));

const price = (over: Record<string, unknown> = {}) => ({
  id: "price_3m_new",
  object: "price",
  active: true,
  currency: "eur",
  unit_amount: 4499,
  product: "prod_plus",
  recurring: { interval: "month", interval_count: 3 },
  ...over,
});

describe("currentPrice", () => {
  test("returns the amount in cents and the upper-case currency", async () => {
    const { pricing, unexpected } = fakeStripe([{ method: "GET", path: "/v1/prices/price_3m", body: price({ id: "price_3m" }) }]);
    expect(await pricing.currentPrice("price_3m")).toEqual({ priceId: "price_3m", amountCents: 4499, currency: "EUR" });
    expect(unexpected).toEqual([]);
  });

  test("a price without unit_amount is refused", async () => {
    const { pricing } = fakeStripe([{ method: "GET", path: "/v1/prices/price_x", body: price({ id: "price_x", unit_amount: null }) }]);
    await expect(pricing.currentPrice("price_x")).rejects.toBeInstanceOf(WebPricingError);
  });
});

describe("createPrice", () => {
  const products = (items: unknown[]) => ({ object: "list", url: "/v1/products", has_more: false, data: items });
  const listProducts = { method: "GET", path: "/v1/products", params: { active: "true", limit: "100" } };

  test("reuses the product tagged with metadata.productId and creates a monthly x3 recurring price", async () => {
    const { pricing, unexpected } = fakeStripe([
      { ...listProducts, body: products([{ id: "prod_other", object: "product", metadata: { productId: "com.mazl.app.plus.1m" } }, { id: "prod_plus", object: "product", metadata: { productId: "com.mazl.app.plus.3m" } }]) },
      {
        method: "POST",
        path: "/v1/prices",
        params: { product: "prod_plus", unit_amount: "4999", currency: "eur", "metadata[productId]": "com.mazl.app.plus.3m", "recurring[interval]": "month", "recurring[interval_count]": "3" },
        body: price({ unit_amount: 4999 }),
      },
    ]);
    expect(await pricing.createPrice("com.mazl.app.plus.3m", 4999, "EUR", 3)).toEqual({ priceId: "price_3m_new", amountCents: 4999, currency: "EUR" });
    expect(unexpected).toEqual([]);
  });

  test("creates the product when none carries the metadata, and a one-time price for a credit pack", async () => {
    const { pricing, unexpected } = fakeStripe([
      { ...listProducts, body: products([]) },
      { method: "POST", path: "/v1/products", params: { name: "com.mazl.app.boost.1", "metadata[productId]": "com.mazl.app.boost.1" }, body: { id: "prod_boost", object: "product", metadata: {} } },
      { method: "POST", path: "/v1/prices", params: { product: "prod_boost", unit_amount: "799", currency: "eur", "metadata[productId]": "com.mazl.app.boost.1" }, body: price({ id: "price_boost", unit_amount: 799, recurring: null }) },
    ]);
    expect((await pricing.createPrice("com.mazl.app.boost.1", 799, "eur", null)).amountCents).toBe(799);
    expect(unexpected).toEqual([]);
  });

  test("finds the product on a later page of the list", async () => {
    const first = { object: "list", url: "/v1/products", has_more: true, data: [{ id: "prod_a", object: "product", metadata: {} }] };
    const { pricing, unexpected } = fakeStripe([
      { ...listProducts, body: first },
      { method: "GET", path: "/v1/products", params: { active: "true", limit: "100", starting_after: "prod_a" }, body: products([{ id: "prod_plus", object: "product", metadata: { productId: "com.mazl.app.plus.3m" } }]) },
      { method: "POST", path: "/v1/prices", params: { product: "prod_plus", unit_amount: "100", currency: "eur", "metadata[productId]": "com.mazl.app.plus.3m", "recurring[interval]": "month", "recurring[interval_count]": "3" }, body: price({ unit_amount: 100 }) },
    ]);
    await pricing.createPrice("com.mazl.app.plus.3m", 100, "eur", 3);
    expect(unexpected).toEqual([]);
  });

  test.each([
    ["zero amount", 0, "eur", null],
    ["fractional amount", 10.5, "eur", null],
    ["bad currency", 100, "euro", null],
    ["zero months", 100, "eur", 0],
  ])("rejects %s before calling Stripe", async (_l, amount, currency, months) => {
    const { pricing, seen } = fakeStripe([]);
    await expect(pricing.createPrice("com.mazl.app.plus.3m", amount, currency, months)).rejects.toBeInstanceOf(WebPricingError);
    expect(seen).toEqual([]);
  });
});

describe("promotions", () => {
  const redeemBy = new Date("2027-02-15T00:00:00Z");
  const unix = String(Math.floor(redeemBy.getTime() / 1000));
  const priceRoutes = [
    { method: "GET", path: "/v1/prices/price_a", body: price({ id: "price_a", product: "prod_plus" }) },
    { method: "GET", path: "/v1/prices/price_b", body: price({ id: "price_b", product: "prod_plus" }) },
    { method: "GET", path: "/v1/prices/price_c", body: price({ id: "price_c", product: { id: "prod_year", object: "product" } }) },
  ];
  const couponParams = { name: "Saint-Valentin 2027", percent_off: "30", duration: "once", "applies_to[products][0]": "prod_plus", "applies_to[products][1]": "prod_year", redeem_by: unix };

  test("creates a percent_off coupon limited to the (deduplicated) products, then its promotion code", async () => {
    const { pricing, unexpected } = fakeStripe([
      ...priceRoutes,
      { method: "POST", path: "/v1/coupons", params: couponParams, body: { id: "coupon_1", object: "coupon" } },
      { method: "POST", path: "/v1/promotion_codes", params: { "promotion[type]": "coupon", "promotion[coupon]": "coupon_1", expires_at: unix }, body: { id: "promo_1", object: "promotion_code" } },
    ]);
    expect(await pricing.createPromotion("Saint-Valentin 2027", 30, ["price_a", "price_b", "price_c"], redeemBy)).toEqual({ couponId: "coupon_1", promotionCodeId: "promo_1" });
    expect(unexpected).toEqual([]);
  });

  test("removes the coupon when its promotion code cannot be created, and reports the Stripe error", async () => {
    const { pricing, seen } = fakeStripe([
      ...priceRoutes,
      { method: "POST", path: "/v1/coupons", params: couponParams, body: { id: "coupon_1", object: "coupon" } },
      { method: "POST", path: "/v1/promotion_codes", params: { "promotion[type]": "coupon", "promotion[coupon]": "coupon_1", expires_at: unix }, status: 400, body: { error: { type: "invalid_request_error", message: "nope" } } },
      { method: "DELETE", path: "/v1/coupons/coupon_1", body: { id: "coupon_1", object: "coupon", deleted: true } },
    ]);
    await expect(pricing.createPromotion("Saint-Valentin 2027", 30, ["price_a", "price_b", "price_c"], redeemBy)).rejects.toThrow("nope");
    expect(seen.at(-1)).toMatchObject({ method: "DELETE", path: "/v1/coupons/coupon_1" });
  });

  test.each([[0], [101], [-5]])("rejects percentOff %d", async (percent) => {
    const { pricing, seen } = fakeStripe([]);
    await expect(pricing.createPromotion("x", percent, ["price_a"], redeemBy)).rejects.toBeInstanceOf(WebPricingError);
    expect(seen).toEqual([]);
  });

  test("rejects a promotion with no price", async () => {
    const { pricing } = fakeStripe([]);
    await expect(pricing.createPromotion("x", 10, [], redeemBy)).rejects.toBeInstanceOf(WebPricingError);
  });

  test("deactivating sets the promotion code inactive and nothing else", async () => {
    const { pricing, seen, unexpected } = fakeStripe([{ method: "POST", path: "/v1/promotion_codes/promo_1", params: { active: "false" }, body: { id: "promo_1", object: "promotion_code", active: false } }]);
    await pricing.deactivatePromotion({ couponId: "coupon_1", promotionCodeId: "promo_1" });
    expect(seen).toHaveLength(1);
    expect(unexpected).toEqual([]);
  });
});

describe("configuration", () => {
  test("is null without STRIPE_SECRET_KEY", () => {
    expect(createWebPricing({})).toBeNull();
    expect(createWebPricing({ STRIPE_SECRET_KEY: "  " })).toBeNull();
  });

  test("builds an adapter from a test key and refuses something that is not a Stripe key", () => {
    expect(createWebPricing({ STRIPE_SECRET_KEY: "sk_test_abc123" })).not.toBeNull();
    expect(() => createWebPricing({ STRIPE_SECRET_KEY: "hunter2" })).toThrow(WebPricingError);
  });
});
