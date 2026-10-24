import type { BillingStatus, ReceivedLike, SubscriptionRow } from "../../shared/api/types";
import { displayName } from "../../shared/lib/format";

// mazl+ comes from the billing status; when the billing routes are not
// served, the app's own subscription row decides (active and not expired).
export function hasPlus(billing: BillingStatus | null, subscription: SubscriptionRow | null, now: Date = new Date()): boolean {
  if (billing !== null) return billing.plus.active;
  if (subscription?.status !== "active") return false;
  return subscription.expires_at === null || new Date(subscription.expires_at) > now;
}

// Without mazl+: first name only, no age.
export const firstName = (like: Pick<ReceivedLike, "display_name">): string => displayName(like.display_name).split(/\s+/)[0] ?? "Membre";

export function likeCaption(like: ReceivedLike, plus: boolean): string {
  if (!plus) return firstName(like);
  const name = displayName(like.display_name);
  return like.age === null ? name : `${name}, ${Math.floor(like.age)}`;
}

export const tabLabel = (count: number): string => `Ils vous ont aimé · ${count}`;
