import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { StripeGatewayError } from "../../src/features/billing-web/domain/errors";
import { offerById } from "../../src/features/billing-web/domain/offers";
import { createStripeClient, SdkStripeGateway } from "../../src/features/billing-web/infra/stripe-sdk-gateway";
import { FakeStripe } from "../support/fake-stripe";

// The real SDK, pointed at a fake server that answers the real Stripe paths.
const fake = new FakeStripe();
let gateway: SdkStripeGateway;

beforeAll(() => {
  fake.start();
  gateway = new SdkStripeGateway(createStripeClient({ secretKey: "sk_test_unit", apiBase: new URL(fake.url) }));
});
afterAll(() => fake.stop());

const lastTo = (method: string, path: string) => fake.requestsTo(method, path).at(-1);
const offer = (id: string) => {
  const found = offerById(id);
  if (found === undefined) throw new Error(id);
  return found;
};

describe("Stripe SDK gateway", () => {
  test("customers: POST /v1/customers with the member id in the metadata", async () => {
    const customer = await gateway.createCustomer({ userId: 42, email: "jeanne@example.com" });
    expect(customer.id).toStartWith("cus_fake_");
    const request = lastTo("POST", "/v1/customers");
    expect(request?.params).toMatchObject({ "metadata[user_id]": "42", email: "jeanne@example.com" });
    expect(request?.headers.authorization).toBe("Bearer sk_test_unit");
    expect(request?.headers["idempotency-key"]).toBe("mazl-customer-42");
  });

  test("a subscription checkout session carries the reference, metadata and subscription_data", async () => {
    const session = await gateway.createCheckoutSession({
      customerId: "cus_1", userId: 42, offer: offer("plus_3m"), priceId: "price_test_plus_3m", waiverId: 9,
      successUrl: "https://mazl.test/app/premium?checkout=success", cancelUrl: "https://mazl.test/app/premium?checkout=cancel",
    });
    expect(session.url).toStartWith("https://checkout.stripe.test/c/pay/cs_test_fake_");
    const { params } = lastTo("POST", "/v1/checkout/sessions") ?? { params: {} };
    expect(params).toMatchObject({
      mode: "subscription", customer: "cus_1", client_reference_id: "42", locale: "fr",
      "line_items[0][price]": "price_test_plus_3m", "line_items[0][quantity]": "1",
      "metadata[user_id]": "42", "metadata[offer]": "plus_3m", "metadata[waiver_id]": "9",
      "subscription_data[metadata][user_id]": "42", "subscription_data[metadata][offer]": "plus_3m",
      success_url: "https://mazl.test/app/premium?checkout=success", cancel_url: "https://mazl.test/app/premium?checkout=cancel",
    });
    expect(Object.keys(params).some((key) => key.startsWith("invoice_creation") || key.startsWith("payment_intent_data"))).toBe(false);
  });

  test("a pack checkout session is a payment with invoice creation and PaymentIntent metadata", async () => {
    await gateway.createCheckoutSession({
      customerId: "cus_1", userId: 42, offer: offer("superlikes_15"), priceId: "price_test_superlikes_15", waiverId: 10,
      successUrl: "https://mazl.test/ok", cancelUrl: "https://mazl.test/ko",
    });
    const { params } = lastTo("POST", "/v1/checkout/sessions") ?? { params: {} };
    expect(params).toMatchObject({
      mode: "payment", "invoice_creation[enabled]": "true", "line_items[0][price]": "price_test_superlikes_15",
      "payment_intent_data[metadata][user_id]": "42", "payment_intent_data[metadata][offer]": "superlikes_15",
      "payment_intent_data[metadata][waiver_id]": "10",
    });
    expect(Object.keys(params).some((key) => key.startsWith("subscription_data"))).toBe(false);
  });

  test("portal: POST /v1/billing_portal/sessions with customer and return_url", async () => {
    const portal = await gateway.createPortalSession({ customerId: "cus_1", returnUrl: "https://mazl.test/app/premium" });
    expect(portal.url).toStartWith("https://billing.stripe.test/p/session/");
    expect(lastTo("POST", "/v1/billing_portal/sessions")?.params).toMatchObject({ customer: "cus_1", return_url: "https://mazl.test/app/premium" });
  });

  test("subscriptions: the period end is read from the items, the metadata from the subscription", async () => {
    fake.subscriptions.set("sub_abc", {
      id: "sub_abc", customer: "cus_1", price: "price_test_plus_6m", status: "past_due", current_period_end: 1_800_000_000,
      start_date: 1_790_000_000, cancel_at_period_end: true, metadata: { user_id: "42", offer: "plus_6m" },
    });
    expect(await gateway.retrieveSubscription("sub_abc")).toEqual({
      id: "sub_abc", customerId: "cus_1", metadataUserId: 42, metadataOffer: "plus_6m", priceId: "price_test_plus_6m",
      status: "past_due", currentPeriodEnd: new Date(1_800_000_000_000), cancelAtPeriodEnd: true, startedAt: new Date(1_790_000_000_000),
    });
    expect(fake.requestsTo("GET", "/v1/subscriptions/sub_abc")).toHaveLength(1);
  });

  test("cancel: DELETE /v1/subscriptions/:id, and an unknown subscription counts as cancelled", async () => {
    fake.subscriptions.set("sub_del", { id: "sub_del", customer: "cus_1", price: "price_test_plus_1m", status: "active", current_period_end: 1_800_000_000 });
    await gateway.cancelSubscription("sub_del");
    expect(fake.requestsTo("DELETE", "/v1/subscriptions/sub_del")).toHaveLength(1);
    expect(fake.subscriptions.get("sub_del")?.status).toBe("canceled");
    await gateway.cancelSubscription("sub_gone");
  });

  test("prices: GET /v1/prices/:id gives the amount and the tax behaviour", async () => {
    expect(await gateway.retrievePrice("price_test_plus_12m")).toEqual({ id: "price_test_plus_12m", unitAmount: 7999, currency: "eur", taxBehavior: "inclusive" });
  });

  test("a Stripe error becomes a StripeGatewayError without the message of the call", async () => {
    const error = await gateway.retrievePrice("price_nope").catch((e: unknown) => e);
    expect(error).toBeInstanceOf(StripeGatewayError);
    expect((error as StripeGatewayError).code).toBe("resource_missing");
    await expect(gateway.retrieveSubscription("sub_nope")).rejects.toBeInstanceOf(StripeGatewayError);
  });
});

describe("duplicate protection on the real paths (security review M2)", () => {
  const checkout = (customerId: string, offerId: string, priceId: string) =>
    gateway.createCheckoutSession({ customerId, userId: 7, offer: offer(offerId), priceId, waiverId: 1, successUrl: "https://mazl.test/s", cancelUrl: "https://mazl.test/c" });

  test("expiring lists the customer's open sessions and expires the subscription ones only", async () => {
    const sub = await checkout("cus_dup", "plus_1m", "price_test_plus_1m");
    const pack = await checkout("cus_dup", "boost_1", "price_test_boost_1");
    await gateway.expireOpenSubscriptionCheckouts("cus_dup");
    expect(lastTo("GET", "/v1/checkout/sessions")?.params).toMatchObject({ customer: "cus_dup", status: "open" });
    expect(fake.requestsTo("POST", `/v1/checkout/sessions/${sub.id}/expire`)).toHaveLength(1);
    expect(fake.requestsTo("POST", `/v1/checkout/sessions/${pack.id}/expire`)).toHaveLength(0);
  });

  test("refunding reads the latest invoice's payment and refunds its PaymentIntent", async () => {
    fake.subscriptions.set("sub_dup", { id: "sub_dup", customer: "cus_dup", price: "price_test_plus_1m", status: "active", current_period_end: 1_800_000_000 });
    await gateway.refundLatestPayment("sub_dup");
    expect(lastTo("GET", "/v1/invoice_payments")?.params).toMatchObject({ invoice: "in_sub_dup" });
    expect(lastTo("POST", "/v1/refunds")?.params).toMatchObject({ payment_intent: "pi_sub_dup" });
  });
});

describe("account erasure on the real paths (security review B2)", () => {
  test("lists the customer's subscriptions and keeps those not over", async () => {
    fake.subscriptions.set("sub_live_b2", { id: "sub_live_b2", customer: "cus_b2", price: "price_test_plus_1m", status: "active", current_period_end: 1_800_000_000 });
    fake.subscriptions.set("sub_over_b2", { id: "sub_over_b2", customer: "cus_b2", price: "price_test_plus_1m", status: "canceled", current_period_end: 1_800_000_000 });
    expect(await gateway.liveSubscriptionsOf("cus_b2")).toEqual(["sub_live_b2"]);
    expect(lastTo("GET", "/v1/subscriptions")?.params).toMatchObject({ customer: "cus_b2", status: "all" });
  });

  test("deletes the customer", async () => {
    await gateway.deleteCustomer("cus_b2");
    expect(fake.requestsTo("DELETE", "/v1/customers/cus_b2")).toHaveLength(1);
  });
});
