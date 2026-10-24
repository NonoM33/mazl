import type { Sql } from "postgres";

// Web payments (docs/web/adr/W04-stripe.md). The waiver proof outlives the
// member: user_id is set to NULL on erasure, the hash and the dates stay.
export async function ensureBillingWebSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS stripe_customers (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      customer_id TEXT NOT NULL UNIQUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
  await sql`
    CREATE TABLE IF NOT EXISTS stripe_subscriptions (
      subscription_id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      customer_id TEXT NOT NULL,
      price_id TEXT NOT NULL,
      offer TEXT NOT NULL,
      status TEXT NOT NULL,
      current_period_end TIMESTAMPTZ NOT NULL,
      cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
      started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_stripe_subscriptions_user ON stripe_subscriptions(user_id)`;
  await sql`
    CREATE TABLE IF NOT EXISTS stripe_events (
      event_id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      processed_at TIMESTAMPTZ
    )
  `;
  await sql`
    CREATE TABLE IF NOT EXISTS billing_withdrawal_waivers (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      offer TEXT NOT NULL,
      text_version TEXT NOT NULL,
      text_sha256 TEXT NOT NULL,
      accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      checkout_session_id TEXT
    )
  `;
}
