import { describe, expect, test } from "bun:test";
import { CheckoutService } from "../../src/features/billing-web/application/checkout-service";
import { SubscriptionSync } from "../../src/features/billing-web/application/subscription-sync";
import { offerById, type Offer } from "../../src/features/billing-web/domain/offers";
import { WITHDRAWAL_VERSION } from "../../src/features/billing-web/domain/withdrawal";
import { FakeGateway, InMemoryBilling, SETTINGS, subscriptionView } from "./support/billing-fakes";

// Security review M2: two tabs could open two Checkout sessions and bill two
// mazl+ subscriptions, because the only check ran when the button was clicked.

function offer(id: string): Offer {
  const found = offerById(id);
  if (found === undefined) throw new Error(id);
  return found;
}
const accepted = { waiverAccepted: true, waiverVersion: WITHDRAWAL_VERSION } as const;

function setup() {
  const gateway = new FakeGateway();
  const repository = new InMemoryBilling();
  const sync = new SubscriptionSync({ gateway, repository, settings: SETTINGS, now: () => repository.now });
  return { gateway, repository, sync, checkout: new CheckoutService(gateway, repository, SETTINGS) };
}

describe("one open subscription checkout at a time", () => {
  test("a new subscription checkout expires the member's open subscription checkouts first", async () => {
    const { checkout, gateway } = setup();
    await checkout.start(1, { offer: offer("plus_1m"), ...accepted });
    await checkout.start(1, { offer: offer("plus_3m"), ...accepted });
    expect(gateway.expiredFor).toEqual(["cus_1", "cus_1"]);
    expect(gateway.openSubscriptionCheckouts("cus_1")).toHaveLength(1);
  });

  test("a pack checkout leaves an open subscription checkout alone", async () => {
    const { checkout, gateway } = setup();
    await checkout.start(1, { offer: offer("plus_1m"), ...accepted });
    await checkout.start(1, { offer: offer("boost_1"), ...accepted });
    expect(gateway.openSubscriptionCheckouts("cus_1")).toHaveLength(1);
  });

  test("two clicks at the same instant end with a single open subscription checkout", async () => {
    const { checkout, gateway } = setup();
    await Promise.all([checkout.start(1, { offer: offer("plus_1m"), ...accepted }), checkout.start(1, { offer: offer("plus_12m"), ...accepted })]);
    expect(gateway.openSubscriptionCheckouts("cus_1")).toHaveLength(1);
  });
});

describe("a second live subscription is cancelled and refunded", () => {
  test("a second Stripe subscription of the same member, started later", async () => {
    const { sync, gateway, repository } = setup();
    gateway.subscriptions.set("sub_first", subscriptionView({ id: "sub_first" }));
    gateway.subscriptions.set("sub_second", subscriptionView({ id: "sub_second", startedAt: new Date("2026-10-24T12:05:00.000Z") }));
    await sync.syncFromStripe("sub_first");
    await sync.syncFromStripe("sub_second");
    expect(gateway.cancelled).toEqual(["sub_second"]);
    expect(gateway.refunded).toEqual(["sub_second"]);
    expect(repository.entitlements.get(1)?.originalTransactionId).toBe("sub_first");
  });

  test("the older one is kept whatever order the events come in", async () => {
    const { sync, gateway } = setup();
    gateway.subscriptions.set("sub_first", subscriptionView({ id: "sub_first" }));
    gateway.subscriptions.set("sub_second", subscriptionView({ id: "sub_second", startedAt: new Date("2026-10-24T12:05:00.000Z") }));
    await sync.syncFromStripe("sub_second");
    await sync.syncFromStripe("sub_first");
    expect(gateway.cancelled).toEqual(["sub_second"]);
  });

  test("a Stripe subscription while an App Store mazl+ is live", async () => {
    const { sync, gateway, repository } = setup();
    repository.setApple(1, new Date("2027-06-01T00:00:00.000Z"));
    gateway.subscriptions.set("sub_1", subscriptionView());
    await sync.syncFromStripe("sub_1");
    expect(gateway.cancelled).toEqual(["sub_1"]);
    expect(gateway.refunded).toEqual(["sub_1"]);
    expect(repository.entitlements.get(1)?.store).toBe("apple");
  });

  test("a single subscription is left alone", async () => {
    const { sync, gateway } = setup();
    gateway.subscriptions.set("sub_1", subscriptionView());
    await sync.syncFromStripe("sub_1");
    expect(gateway.cancelled).toEqual([]);
    expect(gateway.refunded).toEqual([]);
  });
});
