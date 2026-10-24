import type { Sql } from "postgres";
import type { ActiveSubscription, SubscriptionRepository } from "../application/ports";
import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../domain/errors";
import type { SubscriptionStatus } from "../domain/status";

const UNIQUE_VIOLATION = "23505";
const ORIGINAL_TX_INDEX = "idx_subscriptions_original_tx";

// The subscriptions timestamps are TIMESTAMP (no zone) columns holding UTC:
// they are bound as ISO strings, as every writer of this table always did.
const iso = (date: Date | undefined): string | null => (date === undefined ? null : date.toISOString());

function isOriginalTransactionConflict(error: unknown): boolean {
  if (typeof error !== "object" || error === null) return false;
  const { code, constraint_name: constraint } = error as { code?: unknown; constraint_name?: unknown };
  return code === UNIQUE_VIOLATION && constraint === ORIGINAL_TX_INDEX;
}

export class PgSubscriptionRepository implements SubscriptionRepository {
  constructor(private readonly sql: Sql) {}

  // A transaction that Apple refunded or revoked (status 'revoked') is never
  // brought back by a JWS: the JWS the member kept from the purchase carries no
  // revocationDate, so only the stored state knows. The WHERE of the upsert
  // leaves such a row untouched and RETURNING then yields nothing. A new
  // purchase (another originalTransactionId) still replaces the row.
  async activate(userId: number, subscription: ActiveSubscription): Promise<void> {
    try {
      const written = await this.sql<{ id: number }[]>`
        INSERT INTO subscriptions
          (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
        VALUES
          (${userId}, ${subscription.planType}, 'active', 'apple', ${subscription.productId},
           ${subscription.originalTransactionId}, COALESCE(${iso(subscription.startedAt)}::timestamp, NOW()),
           ${iso(subscription.expiresAt)}::timestamp)
        ON CONFLICT (user_id) DO UPDATE SET
          plan_type = EXCLUDED.plan_type,
          status = 'active',
          store = 'apple',
          product_id = EXCLUDED.product_id,
          original_transaction_id = EXCLUDED.original_transaction_id,
          started_at = EXCLUDED.started_at,
          expires_at = EXCLUDED.expires_at,
          updated_at = NOW()
        WHERE NOT (
          subscriptions.status = 'revoked'
          AND subscriptions.original_transaction_id = EXCLUDED.original_transaction_id
        )
        RETURNING id
      `;
      if (written.length === 0) throw new InvalidTransactionError("revoked");
    } catch (error: unknown) {
      if (isOriginalTransactionConflict(error)) throw new TransactionOwnedByAnotherUserError();
      throw error;
    }
  }

  async findByUserId(userId: number): Promise<object | null> {
    const rows = await this.sql<object[]>`SELECT * FROM subscriptions WHERE user_id = ${userId}`;
    return rows[0] ?? null;
  }

  async findOwner(originalTransactionId: string): Promise<number | undefined> {
    const rows = await this.sql<{ user_id: number }[]>`
      SELECT user_id FROM subscriptions WHERE original_transaction_id = ${originalTransactionId}
    `;
    return rows[0]?.user_id;
  }

  // Notifications can arrive late or twice. A renewal only applies when it moves
  // the expiry forward, or repeats the current expiry on a still-active row: a
  // replayed old DID_RENEW must not undo a later EXPIRED, REFUND or billing issue.
  async renew(subscription: ActiveSubscription): Promise<void> {
    await this.sql`
      UPDATE subscriptions SET
        plan_type = ${subscription.planType},
        status = 'active',
        product_id = ${subscription.productId},
        expires_at = ${iso(subscription.expiresAt)}::timestamp,
        updated_at = NOW()
      WHERE original_transaction_id = ${subscription.originalTransactionId}
        AND (
          expires_at IS NULL
          OR expires_at < ${iso(subscription.expiresAt)}::timestamp
          OR (expires_at = ${iso(subscription.expiresAt)}::timestamp AND status = 'active')
        )
    `;
  }

  async markStatus(originalTransactionId: string, status: SubscriptionStatus): Promise<void> {
    await this.sql`
      UPDATE subscriptions SET status = ${status}, updated_at = NOW()
      WHERE original_transaction_id = ${originalTransactionId}
    `;
  }
}
