import { describe, expect, test } from "bun:test";
import Stripe from "stripe";
import { InvalidSignatureError } from "../../src/features/billing-web/domain/errors";
import { StripeWebhookVerifier } from "../../src/features/billing-web/infra/stripe-webhook-verifier";

// The verification is the SDK's own (constructEventAsync); the headers come from
// the SDK's test helper, written from Stripe's documented scheme, not from our code.
const secret = `whsec_test_${crypto.randomUUID().replaceAll("-", "")}`;
const stripe = new Stripe(`sk_test_${crypto.randomUUID().replaceAll("-", "")}`);
const verifier = new StripeWebhookVerifier(stripe, secret);

function payload(type: string, object: Record<string, unknown>): string {
  return JSON.stringify({ id: "evt_sig_1", object: "event", type, livemode: false, created: 1_790_000_000, data: { object } });
}

const session = { id: "cs_test_1", object: "checkout.session", mode: "payment", payment_status: "paid", client_reference_id: "12", metadata: { offer: "boost_3", user_id: "12" }, payment_intent: "pi_1", subscription: null, created: 1_790_000_000 };

describe("webhook signature", () => {
  test("a correctly signed payload is accepted and reduced to the facts we read", async () => {
    const body = payload("checkout.session.completed", session);
    const header = await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret });
    expect(await verifier.verify(body, header)).toMatchObject({
      kind: "checkout_completed", eventId: "evt_sig_1", livemode: false, mode: "payment", paymentStatus: "paid",
      userId: 12, offerId: "boost_3", paymentIntentId: "pi_1", subscriptionId: undefined,
    });
  });

  test("another secret, a missing header and a tampered body are refused", async () => {
    const body = payload("checkout.session.completed", session);
    const wrongSecret = await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret: "whsec_test_other" });
    await expect(verifier.verify(body, wrongSecret)).rejects.toBeInstanceOf(InvalidSignatureError);
    await expect(verifier.verify(body, undefined)).rejects.toBeInstanceOf(InvalidSignatureError);
    await expect(verifier.verify(body, "")).rejects.toBeInstanceOf(InvalidSignatureError);
    await expect(verifier.verify(body, "t=1,v1=deadbeef")).rejects.toBeInstanceOf(InvalidSignatureError);
    const header = await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret });
    await expect(verifier.verify(body.replace("boost_3", "boost_1"), header)).rejects.toBeInstanceOf(InvalidSignatureError);
  });

  test("a timestamp older than the 300 s tolerance is refused, a fresh one passes", async () => {
    const body = payload("customer.subscription.updated", { id: "sub_1", object: "subscription" });
    const now = Math.floor(Date.now() / 1000);
    const old = await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret, timestamp: now - 301 });
    await expect(verifier.verify(body, old)).rejects.toBeInstanceOf(InvalidSignatureError);
    const fresh = await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret, timestamp: now - 200 });
    expect(await verifier.verify(body, fresh)).toEqual({ eventId: "evt_sig_1", type: "customer.subscription.updated", livemode: false, kind: "subscription_changed", subscriptionId: "sub_1" });
  });

  test("events we do not handle verify, then map to ignored", async () => {
    const body = payload("customer.created", { id: "cus_1", object: "customer" });
    const header = await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret });
    expect((await verifier.verify(body, header)).kind).toBe("ignored");
  });

  test("charge.refunded and invoice.payment_failed carry what the handlers need", async () => {
    const refund = payload("charge.refunded", { id: "ch_1", object: "charge", refunded: true, payment_intent: "pi_5", metadata: { offer: "boost_1" } });
    expect(await verifier.verify(refund, await stripe.webhooks.generateTestHeaderStringAsync({ payload: refund, secret }))).toMatchObject({
      kind: "charge_refunded", paymentIntentId: "pi_5", fullyRefunded: true,
    });
    const dispute = payload("charge.dispute.created", { id: "dp_1", object: "dispute", charge: "ch_1", payment_intent: "pi_6", reason: "fraudulent", status: "needs_response" });
    expect(await verifier.verify(dispute, await stripe.webhooks.generateTestHeaderStringAsync({ payload: dispute, secret }))).toMatchObject({ kind: "charge_disputed", paymentIntentId: "pi_6" });
    const failed = payload("invoice.payment_failed", { id: "in_1", object: "invoice", parent: { type: "subscription_details", subscription_details: { subscription: "sub_8" } } });
    expect(await verifier.verify(failed, await stripe.webhooks.generateTestHeaderStringAsync({ payload: failed, secret }))).toMatchObject({ kind: "payment_failed", subscriptionId: "sub_8" });
  });
});
