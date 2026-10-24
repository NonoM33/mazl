import type { Sql } from "postgres";

// docs/premium/CREDITS.md, "Données". Called from initDb, after the users table.
export async function createCreditTables(sql: Sql): Promise<void> {
  // The purchased balance. It can go negative: a refunded pack that was already
  // spent leaves a debt that the next purchase fills first.
  await sql`
    CREATE TABLE IF NOT EXISTS credit_balances (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      kind VARCHAR(20) NOT NULL,
      balance INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, kind)
    )
  `;
  // One line per consumable purchase, keyed by the transactionId of the JWS.
  await sql`
    CREATE TABLE IF NOT EXISTS credit_purchases (
      transaction_id VARCHAR(64) PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      product_id VARCHAR(100) NOT NULL,
      kind VARCHAR(20) NOT NULL,
      quantity INTEGER NOT NULL,
      environment VARCHAR(12) NOT NULL,
      purchased_at TIMESTAMP NOT NULL,
      refunded_at TIMESTAMP,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
  // The journal of debits. The allowance of the day is counted on its
  // source = 'daily' lines. A deleted target only loses its id here.
  await sql`
    CREATE TABLE IF NOT EXISTS credit_spends (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      kind VARCHAR(20) NOT NULL,
      source VARCHAR(10) NOT NULL CHECK (source IN ('daily', 'purchased')),
      target_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
  // A refund or revocation that Apple announced for a transaction the server had
  // not credited yet. recordPurchase refuses these ids, so a JWS kept back until
  // after the refund (it carries no revocationDate) cannot be credited. Keyed on
  // the transactionId, holds no member: nothing to erase with an account.
  await sql`
    CREATE TABLE IF NOT EXISTS credit_revocations (
      transaction_id VARCHAR(64) PRIMARY KEY,
      revoked_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_credit_spends_daily ON credit_spends (user_id, kind, created_at)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_credit_purchases_user ON credit_purchases (user_id)`;
}

// Account erasure: explicit, next to the cascade, like the subscriptions row.
export async function eraseCredits(tx: Sql, userId: number): Promise<void> {
  await tx`DELETE FROM credit_spends WHERE user_id = ${userId}`;
  await tx`DELETE FROM credit_purchases WHERE user_id = ${userId}`;
  await tx`DELETE FROM credit_balances WHERE user_id = ${userId}`;
}
