import { describe, expect, test } from "bun:test";
import {
  entitlementStatusFor,
  type EntitlementStatus,
  isLive,
  projectEntitlement,
  type StripeSubscriptionState,
  type StripeSubscriptionStatus,
} from "../../src/features/billing-web/domain/projection";
import { subscriptionOfferById, type SubscriptionOffer } from "../../src/features/billing-web/domain/offers";

const found = subscriptionOfferById("plus_6m");
if (found === undefined) throw new Error("fixture");
const offer: SubscriptionOffer = found;

function state(status: StripeSubscriptionStatus): StripeSubscriptionState {
  return {
    subscriptionId: "sub_9", userId: 7, customerId: "cus_7", priceId: "price_x", offer, status,
    currentPeriodEnd: new Date("2027-04-24T12:00:00Z"), cancelAtPeriodEnd: false, startedAt: new Date("2026-10-24T12:00:00Z"),
  };
}

describe("projection of a Stripe status onto the entitlement", () => {
  const expected: [StripeSubscriptionStatus, EntitlementStatus | undefined][] = [
    ["active", "active"], ["trialing", "active"], ["past_due", "billing_issue"],
    ["canceled", "expired"], ["unpaid", "expired"], ["incomplete_expired", "expired"], ["paused", "expired"],
    ["incomplete", undefined],
  ];
  for (const [status, entitlement] of expected) {
    test(`${status} -> ${entitlement ?? "nothing"}`, () => {
      expect(entitlementStatusFor(status)).toBe(entitlement);
      expect(projectEntitlement(state(status))?.status).toBe(entitlement);
    });
  }

  test("the row carries the logical product, the plan, the sub_ id and the period end", () => {
    expect(projectEntitlement(state("active"))).toEqual({
      userId: 7, status: "active", planType: "six_month", productId: "com.mazl.app.plus.6m",
      originalTransactionId: "sub_9", startedAt: new Date("2026-10-24T12:00:00Z"), expiresAt: new Date("2027-04-24T12:00:00Z"),
    });
  });

  test("live means active or trialing with a period end in the future", () => {
    const now = new Date("2026-12-01T00:00:00Z");
    expect(isLive(state("active"), now)).toBe(true);
    expect(isLive(state("trialing"), now)).toBe(true);
    expect(isLive(state("past_due"), now)).toBe(false);
    expect(isLive(state("active"), new Date("2027-05-01T00:00:00Z"))).toBe(false);
  });
});
