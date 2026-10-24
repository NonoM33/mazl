import type { SubscriptionRow } from "../../shared/api/types";

// mazl+ = an active subscription whose expiry is still ahead
// (GET /api/subscription).
export function isPlus(subscription: SubscriptionRow | null | undefined, now: number): boolean {
  if (subscription?.status !== "active" || !subscription.expires_at) return false;
  const expires = Date.parse(subscription.expires_at);
  return Number.isFinite(expires) && expires > now;
}
