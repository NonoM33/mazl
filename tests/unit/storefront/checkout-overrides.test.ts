import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { CheckoutService } from "../../../src/features/billing-web/application/checkout-service";
import type { CheckoutOverrides } from "../../../src/features/billing-web/application/ports";
import { offerById, type Offer } from "../../../src/features/billing-web/domain/offers";
import { WITHDRAWAL_VERSION } from "../../../src/features/billing-web/domain/withdrawal";
import { createStripeClient, SdkStripeGateway } from "../../../src/features/billing-web/infra/stripe-sdk-gateway";
import { FakeStripe } from "../../support/fake-stripe";
import { FakeGateway, InMemoryBilling, SETTINGS } from "../support/billing-fakes";

const offer = (id: string): Offer => {
  const found = offerById(id);
  if (found === undefined) throw new Error(id);
  return found;
};
const request = { waiverAccepted: true, waiverVersion: WITHDRAWAL_VERSION } as const;

function overrides(prices: Record<string, string>, promotions: Record<string, string>): CheckoutOverrides {
  return {
    priceIdFor: async (productId) => prices[productId],
    promotionCodeFor: async (productId) => promotions[productId],
  };
}

describe("checkout with the storefront's decisions", () => {
  test("the catalogue's Stripe price wins over the environment's", async () => {
    const gateway = new FakeGateway();
    const checkout = new CheckoutService(gateway, new InMemoryBilling(), SETTINGS, overrides({ "com.mazl.app.plus.3m": "price_catalogue_plus_3m" }, {}));
    await checkout.start(1, { offer: offer("plus_3m"), ...request });
    expect(gateway.sessions[0]).toMatchObject({ priceId: "price_catalogue_plus_3m" });
    expect(gateway.sessions[0]?.promotionCodeId).toBeUndefined();
  });

  test("the environment's price is the fallback when the catalogue has none", async () => {
    const gateway = new FakeGateway();
    const checkout = new CheckoutService(gateway, new InMemoryBilling(), SETTINGS, overrides({}, {}));
    await checkout.start(1, { offer: offer("plus_3m"), ...request });
    expect(gateway.sessions[0]).toMatchObject({ priceId: "price_plus_3m" });
  });

  test("the promotion of the live campaign is applied to the product it targets, and only to it", async () => {
    const gateway = new FakeGateway();
    const checkout = new CheckoutService(gateway, new InMemoryBilling(), SETTINGS, overrides({}, { "com.mazl.app.plus.3m": "promo_valentine" }));
    await checkout.start(1, { offer: offer("plus_3m"), ...request });
    await checkout.start(2, { offer: offer("plus_6m"), ...request });
    expect(gateway.sessions[0]?.promotionCodeId).toBe("promo_valentine");
    expect(gateway.sessions[1]?.promotionCodeId).toBeUndefined();
  });

  test("without overrides the checkout is what it was", async () => {
    const gateway = new FakeGateway();
    await new CheckoutService(gateway, new InMemoryBilling(), SETTINGS).start(1, { offer: offer("plus_3m"), ...request });
    expect(gateway.sessions[0]).toMatchObject({ priceId: "price_plus_3m" });
  });
});

describe("Stripe gateway", () => {
  const fake = new FakeStripe();
  let gateway: SdkStripeGateway;
  beforeAll(() => {
    fake.start();
    gateway = new SdkStripeGateway(createStripeClient({ secretKey: "sk_test_unit", apiBase: new URL(fake.url) }));
  });
  afterAll(() => fake.stop());

  const base = { customerId: "cus_1", userId: 42, priceId: "price_test_plus_3m", waiverId: 9, waiverConfirmation: "Renoncement", successUrl: "https://example.com/ok", cancelUrl: "https://example.com/ko" };

  test("a promotion code becomes a discount of the session; none, no discount", async () => {
    await gateway.createCheckoutSession({ ...base, offer: offer("plus_3m"), promotionCodeId: "promo_example_1" });
    expect(fake.requestsTo("POST", "/v1/checkout/sessions").at(-1)?.params).toMatchObject({ "discounts[0][promotion_code]": "promo_example_1" });
    await gateway.createCheckoutSession({ ...base, offer: offer("plus_3m") });
    expect(Object.keys(fake.requestsTo("POST", "/v1/checkout/sessions").at(-1)?.params ?? {}).some((key) => key.startsWith("discounts"))).toBe(false);
  });
});
