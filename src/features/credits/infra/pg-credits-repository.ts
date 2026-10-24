import type { Sql } from "postgres";
import type { ConsumableRefundOutcome } from "../../subscriptions/application/ports";
import type {
  CreditsRepository,
  NewPurchase,
  PurchaseOutcome,
  SpendOutcome,
  SpendRequest,
  WalletSnapshot,
} from "../application/ports";
import { chooseDebitSource, type DebitSource } from "../domain/allowance";
import type { CreditKind } from "../domain/catalog";
import type { PerKind } from "../domain/view";

interface KindRow {
  readonly kind: CreditKind;
}

// postgres.js types a transaction handle as non-callable; it is the same tag.
function inTransaction<T>(sql: Sql, work: (tx: Sql) => Promise<T>): Promise<T> {
  return sql.begin((transaction) => work(transaction as unknown as Sql)) as Promise<T>;
}

const none: PerKind = { super_like: 0, boost: 0 };

function perKind<R extends KindRow>(rows: readonly R[], read: (row: R) => number): PerKind {
  const values: Record<CreditKind, number> = { ...none };
  for (const row of rows) values[row.kind] = read(row);
  return values;
}

// Adds `delta` to the purchased balance, creating the row when it is missing.
// A negative delta may push the balance below zero: that is the debt of a
// refunded pack that was already spent.
async function addToBalance(tx: Sql, userId: number, kind: CreditKind, delta: number): Promise<void> {
  await tx`
    INSERT INTO credit_balances (user_id, kind, balance)
    VALUES (${userId}, ${kind}, ${delta})
    ON CONFLICT (user_id, kind) DO UPDATE SET balance = credit_balances.balance + EXCLUDED.balance
  `;
}

export class PgCreditsRepository implements CreditsRepository {
  constructor(private readonly sql: Sql) {}

  async snapshot(userId: number): Promise<WalletSnapshot> {
    const [spends, balances, reset] = await Promise.all([
      this.sql<(KindRow & { used: number })[]>`
        SELECT kind, COUNT(*)::int AS used
        FROM credit_spends
        WHERE user_id = ${userId} AND source = 'daily' AND created_at >= DATE_TRUNC('day', NOW())
        GROUP BY kind
      `,
      this.sql<(KindRow & { balance: number })[]>`SELECT kind, balance FROM credit_balances WHERE user_id = ${userId}`,
      this.sql<{ resets_at: Date }[]>`SELECT DATE_TRUNC('day', NOW()) + INTERVAL '1 day' AS resets_at`,
    ]);
    const resetsAt = reset[0]?.resets_at;
    if (resetsAt === undefined) throw new Error("credits: the database returned no reset time");
    return { dailyUsed: perKind(spends, (row) => Number(row.used)), balances: perKind(balances, (row) => Number(row.balance)), resetsAt };
  }

  // The balance row is locked for the whole transaction, so two simultaneous
  // requests of one member cannot spend the same credit.
  async spend(request: SpendRequest): Promise<SpendOutcome> {
    const { userId, kind } = request;
    return await inTransaction(this.sql, async (tx): Promise<SpendOutcome> => {
      await tx`
        INSERT INTO credit_balances (user_id, kind, balance) VALUES (${userId}, ${kind}, 0)
        ON CONFLICT (user_id, kind) DO NOTHING
      `;
      const wallet = await tx<{ balance: number }[]>`
        SELECT balance FROM credit_balances WHERE user_id = ${userId} AND kind = ${kind} FOR UPDATE
      `;
      const spent = await tx<{ used: number }[]>`
        SELECT COUNT(*)::int AS used FROM credit_spends
        WHERE user_id = ${userId} AND kind = ${kind} AND source = 'daily' AND created_at >= DATE_TRUNC('day', NOW())
      `;
      const source = chooseDebitSource({
        allowance: request.allowance,
        dailyUsed: Number(spent[0]?.used ?? 0),
        purchasedBalance: Number(wallet[0]?.balance ?? 0),
      });
      if (source === undefined) return { ok: false };
      return { ok: true, spendId: await this.writeDebit(tx, request, source), source };
    });
  }

  private async writeDebit(tx: Sql, request: SpendRequest, source: DebitSource): Promise<number> {
    const { userId, kind, targetUserId } = request;
    const rows = await tx<{ id: number }[]>`
      INSERT INTO credit_spends (user_id, kind, source, target_user_id)
      VALUES (${userId}, ${kind}, ${source}, ${targetUserId ?? null})
      RETURNING id
    `;
    const id = rows[0]?.id;
    if (id === undefined) throw new Error("credits: the debit was not recorded");
    if (source === "purchased") {
      await tx`UPDATE credit_balances SET balance = balance - 1 WHERE user_id = ${userId} AND kind = ${kind}`;
    }
    return id;
  }

  async cancelSpend(userId: number, spendId: number): Promise<void> {
    await inTransaction(this.sql, async (tx) => {
      const rows = await tx<(KindRow & { source: DebitSource })[]>`
        DELETE FROM credit_spends WHERE id = ${spendId} AND user_id = ${userId} RETURNING kind, source
      `;
      const line = rows[0];
      if (line?.source === "purchased") {
        await tx`UPDATE credit_balances SET balance = balance + 1 WHERE user_id = ${userId} AND kind = ${line.kind}`;
      }
    });
  }

  async recordPurchase(userId: number, purchase: NewPurchase): Promise<PurchaseOutcome> {
    return await inTransaction(this.sql, async (tx): Promise<PurchaseOutcome> => {
      const inserted = await tx<{ transaction_id: string }[]>`
        INSERT INTO credit_purchases (transaction_id, user_id, product_id, kind, quantity, environment, purchased_at)
        VALUES (${purchase.transactionId}, ${userId}, ${purchase.productId}, ${purchase.kind}, ${purchase.quantity},
                ${purchase.environment}, ${purchase.purchasedAt.toISOString()}::timestamp)
        ON CONFLICT (transaction_id) DO NOTHING
        RETURNING transaction_id
      `;
      if (inserted.length > 0) {
        await addToBalance(tx, userId, purchase.kind, purchase.quantity);
        return "credited";
      }
      const owner = await tx<{ user_id: number }[]>`SELECT user_id FROM credit_purchases WHERE transaction_id = ${purchase.transactionId}`;
      return owner[0]?.user_id === userId ? "already_credited" : "owned_by_another_user";
    });
  }

  async refundPurchase(transactionId: string): Promise<ConsumableRefundOutcome> {
    return await inTransaction(this.sql, async (tx): Promise<ConsumableRefundOutcome> => {
      const marked = await tx<(KindRow & { user_id: number; quantity: number })[]>`
        UPDATE credit_purchases SET refunded_at = NOW()
        WHERE transaction_id = ${transactionId} AND refunded_at IS NULL
        RETURNING user_id, kind, quantity
      `;
      const purchase = marked[0];
      if (purchase !== undefined) {
        await addToBalance(tx, purchase.user_id, purchase.kind, -Number(purchase.quantity));
        return "refunded";
      }
      const known = await tx`SELECT 1 FROM credit_purchases WHERE transaction_id = ${transactionId}`;
      return known.length > 0 ? "already_refunded" : "unknown";
    });
  }
}
