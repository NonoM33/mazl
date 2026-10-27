// MAZL Couple (docs/couple/ESPACE-COUPLE.md section 1): one partner pays, both
// have the rights. Pure rules; the SQL lives in ../infra/pg-couple-premium.ts.

export const COUPLE_PLAN_TYPE = "couple_monthly";

// A subscription row as the rule reads it.
export interface MemberSubscription {
  readonly userId: number;
  readonly planType: string | null;
  readonly status: string;
  // Instant, or null when the row has none.
  readonly expiresAt: Date | null;
}

export interface CouplePremium {
  readonly active: boolean;
  readonly paidBy: "me" | "partner" | null;
  readonly renewsAt: string | null;
}

export const NO_PREMIUM: CouplePremium = { active: false, paidBy: null, renewsAt: null };

export function isLiveCoupleSubscription(subscription: MemberSubscription, now: Date): boolean {
  return (
    subscription.planType === COUPLE_PLAN_TYPE &&
    subscription.status === "active" &&
    subscription.expiresAt !== null &&
    subscription.expiresAt.getTime() > now.getTime()
  );
}

// `subscriptions` are those of the two members of the couple. When both pay,
// the caller is shown as the payer and the later expiry is the renewal.
export function coupleSubscriptionOf(viewerId: number, subscriptions: readonly MemberSubscription[], now: Date): CouplePremium {
  const live = subscriptions.filter((subscription) => isLiveCoupleSubscription(subscription, now));
  if (live.length === 0) return NO_PREMIUM;
  const mine = live.find((subscription) => subscription.userId === viewerId);
  const chosen = mine ?? live[0];
  if (chosen === undefined || chosen.expiresAt === null) return NO_PREMIUM;
  return { active: true, paidBy: mine === undefined ? "partner" : "me", renewsAt: chosen.expiresAt.toISOString() };
}
