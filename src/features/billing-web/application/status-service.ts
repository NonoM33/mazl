import { isLive, type StripeSubscriptionState } from "../domain/projection";
import type { Clock } from "./clock";
import type { BillingRepository, EntitlementRow } from "./ports";
import type { SubscriptionSync } from "./subscription-sync";

export interface BillingStatus {
  readonly plus: {
    readonly active: boolean;
    readonly source: "apple" | "stripe" | null;
    readonly plan_type: string | null;
    readonly expires_at: string | null;
    readonly status: string | null;
  };
  readonly stripe: {
    readonly subscription: {
      readonly offer: string;
      readonly status: string;
      readonly current_period_end: string;
      readonly cancel_at_period_end: boolean;
    } | null;
    readonly has_customer: boolean;
  };
  readonly conflict: "double_subscription" | null;
  readonly can_subscribe: boolean;
  readonly blocked_reason: "apple_active" | "stripe_active" | null;
}

function sourceOf(entitlement: EntitlementRow | undefined): "apple" | "stripe" | null {
  if (entitlement?.live !== true) return null;
  // Legacy rows without a store come from the App Store (RevenueCat era).
  return entitlement.store === "stripe" ? "stripe" : "apple";
}

export class StatusService {
  constructor(
    private readonly repository: BillingRepository,
    private readonly sync: SubscriptionSync,
    private readonly clock: Clock,
  ) {}

  async status(userId: number): Promise<BillingStatus> {
    const now = this.clock();
    const subscriptions = await this.repository.subscriptionsOf(userId);
    const live = subscriptions.find((state) => isLive(state, now));
    let entitlement = await this.repository.entitlementOf(userId);
    if (live !== undefined && entitlement?.originalTransactionId !== live.subscriptionId) {
      // A live Stripe subscription that the entitlement row does not show:
      // project it again (it is a no-op while another source protects the row).
      await this.sync.reprojectStored(userId);
      entitlement = await this.repository.entitlementOf(userId);
    }
    const source = sourceOf(entitlement);
    return {
      plus: {
        active: source !== null,
        source,
        plan_type: entitlement?.planType ?? null,
        expires_at: entitlement?.expiresAt?.toISOString() ?? null,
        status: entitlement?.status ?? null,
      },
      stripe: {
        subscription: describe(live ?? subscriptions[0]),
        has_customer: (await this.repository.customerIdOf(userId)) !== undefined,
      },
      conflict: source === "apple" && live !== undefined ? "double_subscription" : null,
      can_subscribe: source === null,
      blocked_reason: source === null ? null : source === "stripe" ? "stripe_active" : "apple_active",
    };
  }
}

function describe(state: StripeSubscriptionState | undefined): BillingStatus["stripe"]["subscription"] {
  if (state === undefined) return null;
  return {
    offer: state.offer.id,
    status: state.status,
    current_period_end: state.currentPeriodEnd.toISOString(),
    cancel_at_period_end: state.cancelAtPeriodEnd,
  };
}
