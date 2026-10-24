export type SubscriptionStatus = "active" | "expired" | "revoked" | "billing_issue";

// What an App Store Server Notification V2 type does to a subscription.
// Types absent here (TEST, DID_CHANGE_RENEWAL_PREF, REFUND_DECLINED...) leave
// the stored state alone.
const STATUS_BY_NOTIFICATION: Readonly<Record<string, SubscriptionStatus>> = {
  SUBSCRIBED: "active",
  DID_RENEW: "active",
  DID_CHANGE_RENEWAL_STATUS: "active",
  OFFER_REDEEMED: "active",
  EXPIRED: "expired",
  GRACE_PERIOD_EXPIRED: "expired",
  REFUND: "revoked",
  REVOKE: "revoked",
  DID_FAIL_TO_RENEW: "billing_issue",
};

export function statusForNotificationType(notificationType: string): SubscriptionStatus | undefined {
  return Object.hasOwn(STATUS_BY_NOTIFICATION, notificationType) ? STATUS_BY_NOTIFICATION[notificationType] : undefined;
}
