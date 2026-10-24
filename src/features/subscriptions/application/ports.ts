import type { PlanType } from "../domain/plan";
import type { SubscriptionStatus } from "../domain/status";

// Checks the cryptographic envelope of a signed App Store payload (compact
// JWS) and returns its JSON payload. Throws InvalidTransactionError.
export interface JwsVerifier {
  verify(jws: string): Record<string, unknown>;
}

export interface ActiveSubscription {
  readonly originalTransactionId: string;
  readonly productId: string;
  readonly planType: PlanType;
  readonly startedAt: Date | undefined;
  readonly expiresAt: Date;
}

export interface SubscriptionRepository {
  // Binds the Apple subscription to the user and marks it active. Throws
  // TransactionOwnedByAnotherUserError when another user already holds it.
  activate(userId: number, subscription: ActiveSubscription): Promise<void>;
  // The stored subscription row of a user, as served by GET /api/subscription.
  findByUserId(userId: number): Promise<object | null>;
  findOwner(originalTransactionId: string): Promise<number | undefined>;
  // Renews an existing subscription; a notification older than the stored
  // expiry (delivered out of order) must not shorten it.
  renew(subscription: ActiveSubscription): Promise<void>;
  // Applies the status the notification announces, unless the notification
  // speaks of a period older than the stored one (`periodEnd` before the stored
  // expiry): Apple does not deliver in order, and a late EXPIRED must not cut
  // a subscription that was renewed since.
  markStatus(originalTransactionId: string, status: SubscriptionStatus, periodEnd: Date): Promise<void>;
}

export type ConsumableRefundOutcome = "refunded" | "already_refunded" | "unknown";

// What the subscriptions notification handler needs from whoever sells
// consumables (the credits feature), so that it never imports it.
export interface ConsumableRefunds {
  // True when the product is a consumable sold by this app.
  sells(productId: string): boolean;
  // Takes a refunded purchase back, once only. "unknown" when never credited.
  refund(transactionId: string): Promise<ConsumableRefundOutcome>;
}
