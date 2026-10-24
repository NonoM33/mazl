import { describe, expect, test } from "bun:test";
import type { BillingEvent } from "../../src/features/billing-web/application/ports";
import { StatusService } from "../../src/features/billing-web/application/status-service";
import { SubscriptionCancellation } from "../../src/features/billing-web/application/subscription-cancellation";
import { SubscriptionSync } from "../../src/features/billing-web/application/subscription-sync";
import { WebhookService } from "../../src/features/billing-web/application/webhook-service";
import { InvalidSignatureError, StripeGatewayError, UnknownPriceError } from "../../src/features/billing-web/domain/errors";
import { withStripeCancellation } from "../../src/features/billing-web/billing-web.module";
import { InMemoryCredits } from "./support/credits-fakes";
import { FakeGateway, FakeVerifier, InMemoryBilling, SETTINGS, subscriptionView } from "./support/billing-fakes";

function setup() {
  const gateway = new FakeGateway();
  const repository = new InMemoryBilling();
  const credits = new InMemoryCredits();
  const sync = new SubscriptionSync({ gateway, repository, settings: SETTINGS });
  const webhook = new WebhookService({ verifier: new FakeVerifier(), repository, sync, credits });
  const status = new StatusService(repository, sync, () => repository.now);
  return { gateway, repository, credits, sync, webhook, status };
}

type Omitted<E> = E extends unknown ? Omit<E, "eventId" | "type" | "livemode"> : never;
type Draft<K extends BillingEvent["kind"] = BillingEvent["kind"]> = Omitted<Extract<BillingEvent, { kind: K }>>;
let sequence = 0;
function send(webhook: WebhookService, event: Draft, id = `evt_${++sequence}`, signature = "valid") {
  const full = { eventId: id, type: "test", livemode: false, ...event };
  return webhook.handle(JSON.stringify(full), signature);
}

const completedSubscription: Draft<"checkout_completed"> = {
  kind: "checkout_completed", mode: "subscription", paymentStatus: "paid", sessionId: "cs_1", userId: 1, offerId: "plus_3m",
  subscriptionId: "sub_1", paymentIntentId: undefined, createdAt: new Date("2026-10-24T12:00:00Z"),
};
const completedPack = (paymentIntentId: string, offerId = "superlikes_15", paymentStatus = "paid"): Draft<"checkout_completed"> => ({
  kind: "checkout_completed", mode: "payment", paymentStatus, sessionId: "cs_2", userId: 1, offerId,
  subscriptionId: undefined, paymentIntentId, createdAt: new Date("2026-10-24T12:00:00Z"),
});

describe("webhook: signature and idempotence", () => {
  test("a bad signature is refused before anything is recorded", async () => {
    const { webhook, repository } = setup();
    await expect(send(webhook, completedSubscription, "evt_x", "forged")).rejects.toBeInstanceOf(InvalidSignatureError);
    expect(repository.events.size).toBe(0);
  });

  test("a replayed event is a duplicate and does no work", async () => {
    const { webhook, gateway, credits } = setup();
    expect(await send(webhook, completedPack("pi_1"), "evt_a")).toBe("processed");
    expect(await send(webhook, completedPack("pi_1"), "evt_a")).toBe("duplicate");
    expect(gateway.subscriptions.size).toBe(0);
    expect(credits.balance(1, "super_like")).toBe(15);
  });

  test("a failure leaves the event unmarked so Stripe redelivers it", async () => {
    const { webhook, gateway, repository } = setup();
    await expect(send(webhook, completedSubscription, "evt_f")).rejects.toBeInstanceOf(StripeGatewayError);
    expect(repository.events.get("evt_f")).toBe(false);
    gateway.subscriptions.set("sub_1", subscriptionView());
    expect(await send(webhook, completedSubscription, "evt_f")).toBe("processed");
    expect(repository.events.get("evt_f")).toBe(true);
  });

  test("unrelated events are acknowledged and ignored", async () => {
    const { webhook, repository } = setup();
    expect(await send(webhook, { kind: "ignored" })).toBe("processed");
    expect(repository.entitlements.size).toBe(0);
  });
});

describe("webhook: subscriptions", () => {
  test("checkout.session.completed activates mazl+ from the state read at Stripe", async () => {
    const { webhook, gateway, repository } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView());
    await repository.saveCustomer(1, "cus_1");
    await send(webhook, completedSubscription);
    expect(repository.entitlements.get(1)).toMatchObject({
      store: "stripe", status: "active", planType: "three_month", originalTransactionId: "sub_1", live: true,
      expiresAt: new Date("2027-01-24T12:00:00Z"),
    });
    expect(repository.subscriptions.get("sub_1")).toMatchObject({ status: "active", cancelAtPeriodEnd: false, priceId: "price_plus_3m" });
  });

  test("events out of order converge to the latest Stripe state", async () => {
    const { webhook, gateway, repository } = setup();
    // Stripe already says canceled when the older "updated" and "completed" events arrive.
    gateway.subscriptions.set("sub_1", subscriptionView({ status: "canceled" }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" });
    await send(webhook, completedSubscription);
    expect(repository.entitlements.get(1)).toMatchObject({ status: "expired", live: false });
    gateway.subscriptions.set("sub_1", subscriptionView({ status: "active" }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" });
    expect(repository.entitlements.get(1)).toMatchObject({ status: "active", live: true });
  });

  test("payment_failed projects billing_issue, deleted projects expired", async () => {
    const { webhook, gateway, repository } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView({ status: "past_due" }));
    await send(webhook, { kind: "payment_failed", subscriptionId: "sub_1" });
    expect(repository.entitlements.get(1)?.status).toBe("billing_issue");
    gateway.subscriptions.set("sub_1", subscriptionView({ status: "canceled" }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" });
    expect(repository.entitlements.get(1)?.status).toBe("expired");
    await send(webhook, { kind: "payment_failed", subscriptionId: undefined });
  });

  test("an incomplete subscription projects nothing", async () => {
    const { webhook, gateway, repository } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView({ status: "incomplete" }));
    await send(webhook, completedSubscription);
    expect(repository.entitlements.size).toBe(0);
  });

  test("a live Apple subscription is never overwritten by Stripe", async () => {
    const { webhook, gateway, repository } = setup();
    repository.setApple(1, new Date("2027-06-01T00:00:00Z"));
    gateway.subscriptions.set("sub_1", subscriptionView());
    await send(webhook, completedSubscription);
    expect(repository.entitlements.get(1)).toMatchObject({ store: "apple", originalTransactionId: "2000000123456789" });
    expect(repository.subscriptions.get("sub_1")?.status).toBe("active");
  });

  test("an expired Apple row is replaced by the Stripe subscription", async () => {
    const { webhook, gateway, repository } = setup();
    repository.setApple(1, new Date("2026-01-01T00:00:00Z"));
    gateway.subscriptions.set("sub_1", subscriptionView());
    await send(webhook, completedSubscription);
    expect(repository.entitlements.get(1)?.store).toBe("stripe");
  });

  test("a late event of an old Stripe subscription does not undo the newer one", async () => {
    const { webhook, gateway, repository } = setup();
    gateway.subscriptions.set("sub_2", subscriptionView({ id: "sub_2", status: "active" }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_2" });
    gateway.subscriptions.set("sub_1", subscriptionView({ id: "sub_1", status: "canceled" }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" });
    expect(repository.entitlements.get(1)).toMatchObject({ originalTransactionId: "sub_2", live: true });
  });

  test("a member erased since the purchase is skipped, not an error", async () => {
    const { webhook, gateway, repository } = setup();
    repository.users.delete(1);
    gateway.subscriptions.set("sub_1", subscriptionView());
    expect(await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" })).toBe("processed");
    expect(repository.subscriptions.size).toBe(0);
  });

  test("the customer mapping wins over the metadata", async () => {
    const { webhook, gateway, repository } = setup();
    await repository.saveCustomer(2, "cus_1");
    gateway.subscriptions.set("sub_1", subscriptionView({ metadataUserId: 1 }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" });
    expect(repository.entitlements.has(2)).toBe(true);
    expect(repository.entitlements.has(1)).toBe(false);
  });

  test("a price that maps to no offer fails loudly", async () => {
    const { webhook, gateway } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView({ priceId: "price_unknown", metadataOffer: undefined }));
    await expect(send(webhook, { kind: "subscription_changed", subscriptionId: "sub_1" })).rejects.toBeInstanceOf(UnknownPriceError);
  });
});

describe("webhook: credit packs", () => {
  test("a paid pack credits once, however many times it is delivered", async () => {
    const { webhook, credits } = setup();
    await send(webhook, completedPack("pi_77"));
    await send(webhook, completedPack("pi_77"), "evt_other_delivery");
    expect(credits.balance(1, "super_like")).toBe(15);
    expect(credits.purchases.size).toBe(1);
  });

  test("an unpaid session credits nothing until the async payment succeeds", async () => {
    const { webhook, credits } = setup();
    await send(webhook, completedPack("pi_8", "boost_3", "unpaid"));
    expect(credits.balance(1, "boost")).toBe(0);
    await send(webhook, completedPack("pi_8", "boost_3", "paid"));
    expect(credits.balance(1, "boost")).toBe(3);
  });

  test("a full refund takes the credits back once; partial refunds and other charges change nothing", async () => {
    const { webhook, credits } = setup();
    await send(webhook, completedPack("pi_9", "boost_1"));
    await send(webhook, { kind: "charge_refunded", paymentIntentId: "pi_9", offerId: "boost_1", fullyRefunded: false });
    expect(credits.balance(1, "boost")).toBe(1);
    await send(webhook, { kind: "charge_refunded", paymentIntentId: "pi_other", offerId: undefined, fullyRefunded: true });
    expect(credits.revoked.size).toBe(0);
    await send(webhook, { kind: "charge_refunded", paymentIntentId: "pi_9", offerId: "boost_1", fullyRefunded: true });
    await send(webhook, { kind: "charge_refunded", paymentIntentId: "pi_9", offerId: "boost_1", fullyRefunded: true });
    expect(credits.balance(1, "boost")).toBe(0);
  });

  test("a pack for an erased member or an unknown offer is ignored", async () => {
    const { webhook, credits, repository } = setup();
    repository.users.delete(1);
    await send(webhook, completedPack("pi_10"));
    repository.users.add(1);
    await send(webhook, completedPack("pi_11", "plus_3m"));
    expect(credits.purchases.size).toBe(0);
  });

  test("the livemode flag selects the environment of the purchase", async () => {
    const { repository, gateway, sync } = setup();
    const seen: string[] = [];
    const credits = {
      recordPurchase: async (_u: number, p: { environment: string }) => (seen.push(p.environment), "credited" as const),
      refundPurchase: async () => "unknown" as const,
    };
    const webhook = new WebhookService({ verifier: new FakeVerifier(), repository, sync, credits });
    void gateway;
    await webhook.handle(JSON.stringify({ eventId: "e1", type: "t", livemode: true, ...completedPack("pi_a") }), "valid");
    await webhook.handle(JSON.stringify({ eventId: "e2", type: "t", livemode: false, ...completedPack("pi_b") }), "valid");
    expect(seen).toEqual(["Production", "Sandbox"]);
  });
});

describe("status", () => {
  test("a member without anything can subscribe", async () => {
    const { status } = setup();
    expect(await status.status(1)).toEqual({
      plus: { active: false, source: null, plan_type: null, expires_at: null, status: null },
      stripe: { subscription: null, has_customer: false },
      conflict: null, can_subscribe: true, blocked_reason: null,
    });
  });

  test("an Apple subscription blocks the web one", async () => {
    const { status, repository } = setup();
    repository.setApple(1, new Date("2027-01-01T00:00:00Z"));
    const view = await status.status(1);
    expect(view.plus).toMatchObject({ active: true, source: "apple", plan_type: "yearly", expires_at: "2027-01-01T00:00:00.000Z" });
    expect(view).toMatchObject({ can_subscribe: false, blocked_reason: "apple_active", conflict: null });
  });

  test("Stripe active on top of Apple is a double subscription, and Stripe takes over when Apple ends", async () => {
    const { status, repository, webhook, gateway } = setup();
    repository.setApple(1, new Date("2026-11-30T00:00:00Z"));
    gateway.subscriptions.set("sub_1", subscriptionView());
    await send(webhook, completedSubscription);
    const both = await status.status(1);
    expect(both.conflict).toBe("double_subscription");
    expect(both.plus.source).toBe("apple");
    expect(both.stripe.subscription).toMatchObject({ offer: "plus_3m", status: "active", cancel_at_period_end: false });
    repository.setApple(1, new Date("2026-10-01T00:00:00Z"));
    const after = await status.status(1);
    expect(after.plus.source).toBe("stripe");
    expect(after.conflict).toBeNull();
    expect(after.blocked_reason).toBe("stripe_active");
  });

  test("an active Stripe subscription that was never projected is projected by the status call", async () => {
    const { status, repository } = setup();
    await repository.saveCustomer(1, "cus_1");
    await repository.saveSubscription({
      subscriptionId: "sub_1", userId: 1, customerId: "cus_1", priceId: "price_plus_1m",
      offer: (await import("../../src/features/billing-web/domain/offers")).subscriptionOfferById("plus_1m")!,
      status: "active", currentPeriodEnd: new Date("2026-11-24T12:00:00Z"), cancelAtPeriodEnd: true, startedAt: new Date("2026-10-24T12:00:00Z"),
    });
    const view = await status.status(1);
    expect(view.plus).toMatchObject({ active: true, source: "stripe", plan_type: "monthly" });
    expect(view.stripe).toEqual({ subscription: { offer: "plus_1m", status: "active", current_period_end: "2026-11-24T12:00:00.000Z", cancel_at_period_end: true }, has_customer: true });
  });
});

describe("account erasure", () => {
  test("active Stripe subscriptions are cancelled before the erasure runs", async () => {
    const { repository, gateway, webhook } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView());
    await send(webhook, completedSubscription);
    gateway.subscriptions.set("sub_2", subscriptionView({ id: "sub_2", status: "canceled" }));
    await send(webhook, { kind: "subscription_changed", subscriptionId: "sub_2" });
    const order: string[] = [];
    const cancellation = new SubscriptionCancellation(gateway, repository);
    const guarded = withStripeCancellation(
      { around: async (_id, deletion) => (order.push("erase"), await deletion()) },
      { cancelSubscriptions: async (id) => (await cancellation.cancelAll(id), void order.push(`cancelled:${gateway.cancelled.join(",")}`)) },
    );
    expect(await guarded.around(1, async () => "done")).toBe("done");
    expect(order).toEqual(["cancelled:sub_1", "erase"]);
  });

  test("a Stripe failure fails the erasure without erasing", async () => {
    const { repository, gateway, webhook } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView());
    await send(webhook, completedSubscription);
    gateway.failCancel = true;
    const cancellation = new SubscriptionCancellation(gateway, repository);
    let erased = false;
    const guarded = withStripeCancellation(
      { around: async (_id, deletion) => ((erased = true), await deletion()) },
      { cancelSubscriptions: (id) => cancellation.cancelAll(id) },
    );
    await expect(guarded.around(1, async () => "done")).rejects.toBeInstanceOf(StripeGatewayError);
    expect(erased).toBe(false);
  });
});
