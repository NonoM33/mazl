import type { SubscriptionOffer } from "./offers";

export type StripeSubscriptionStatus =
  | "incomplete"
  | "incomplete_expired"
  | "trialing"
  | "active"
  | "past_due"
  | "canceled"
  | "unpaid"
  | "paused";

// What the `subscriptions` row (the mazl+ entitlement) can say.
export type EntitlementStatus = "active" | "billing_issue" | "expired";

export interface StripeSubscriptionState {
  readonly subscriptionId: string;
  readonly userId: number;
  readonly customerId: string;
  readonly priceId: string;
  readonly offer: SubscriptionOffer;
  readonly status: StripeSubscriptionStatus;
  readonly currentPeriodEnd: Date;
  readonly cancelAtPeriodEnd: boolean;
  readonly startedAt: Date;
}

export interface EntitlementProjection {
  readonly userId: number;
  readonly status: EntitlementStatus;
  readonly planType: SubscriptionOffer["planType"];
  readonly productId: string;
  readonly originalTransactionId: string;
  readonly startedAt: Date;
  readonly expiresAt: Date;
}

// "paused" gives no access, so it is treated as expired. "incomplete" (first
// payment pending) projects nothing: the member has not paid yet.
export function entitlementStatusFor(status: StripeSubscriptionStatus): EntitlementStatus | undefined {
  switch (status) {
    case "active":
    case "trialing":
      return "active";
    case "past_due":
      return "billing_issue";
    case "canceled":
    case "unpaid":
    case "incomplete_expired":
    case "paused":
      return "expired";
    case "incomplete":
      return undefined;
  }
}

export function projectEntitlement(state: StripeSubscriptionState): EntitlementProjection | undefined {
  const status = entitlementStatusFor(state.status);
  if (status === undefined) return undefined;
  return {
    userId: state.userId,
    status,
    planType: state.offer.planType,
    productId: state.offer.productId,
    originalTransactionId: state.subscriptionId,
    startedAt: state.startedAt,
    expiresAt: state.currentPeriodEnd,
  };
}

// A Stripe subscription that currently gives the member mazl+.
export function isLive(state: Pick<StripeSubscriptionState, "status" | "currentPeriodEnd">, now: Date): boolean {
  return (state.status === "active" || state.status === "trialing") && state.currentPeriodEnd.getTime() > now.getTime();
}
