import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../../../src/features/subscriptions/domain/errors";
import type { JwsVerifier } from "../../../src/features/subscriptions/application/ports";
import type { ActiveSubscription, SubscriptionRepository } from "../../../src/features/subscriptions/application/ports";
import type { SubscriptionStatus } from "../../../src/features/subscriptions/domain/status";

// Test doubles for the subscriptions feature. Signed strings are opaque keys:
// the fake "verifier" returns whatever payload was registered for them.
export class FakeJwsVerifier implements JwsVerifier {
  private readonly known = new Map<string, Record<string, unknown>>();

  register(jws: string, payload: Record<string, unknown>): string {
    this.known.set(jws, payload);
    return jws;
  }

  verify(jws: string): Record<string, unknown> {
    const payload = this.known.get(jws);
    if (payload === undefined) throw new InvalidTransactionError("invalid_signature");
    return payload;
  }
}

export interface StoredSubscription extends ActiveSubscription {
  userId: number;
  status: SubscriptionStatus;
}

export class InMemorySubscriptions implements SubscriptionRepository {
  readonly rows = new Map<number, StoredSubscription>();

  private byOriginalTransaction(originalTransactionId: string): StoredSubscription | undefined {
    return [...this.rows.values()].find((row) => row.originalTransactionId === originalTransactionId);
  }

  async activate(userId: number, subscription: ActiveSubscription): Promise<void> {
    const owner = this.byOriginalTransaction(subscription.originalTransactionId);
    if (owner !== undefined && owner.userId !== userId) throw new TransactionOwnedByAnotherUserError();
    if (owner?.status === "revoked") throw new InvalidTransactionError("revoked");
    this.rows.set(userId,{ ...subscription, userId, status: "active" });
  }

  async findByUserId(userId: number): Promise<object | null> {
    return this.rows.get(userId) ?? null;
  }

  async findOwner(originalTransactionId: string): Promise<number | undefined> {
    return this.byOriginalTransaction(originalTransactionId)?.userId;
  }

  async renew(subscription: ActiveSubscription): Promise<void> {
    const row = this.byOriginalTransaction(subscription.originalTransactionId);
    if (row === undefined || subscription.expiresAt < row.expiresAt) return;
    if (subscription.expiresAt.getTime() === row.expiresAt.getTime() && row.status !== "active") return;
    this.rows.set(row.userId, { ...subscription, userId: row.userId, status: "active" });
  }

  async markStatus(originalTransactionId: string, status: SubscriptionStatus, periodEnd: Date): Promise<void> {
    const row = this.byOriginalTransaction(originalTransactionId);
    if (row !== undefined && periodEnd >= row.expiresAt) row.status = status;
  }
}
