import type { Sql } from "postgres";

// docs/web/adr/W06-rgpd-article9.md. Idempotent, runs at every boot after initDb().
export async function ensurePrivacySchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS user_consents (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      purpose VARCHAR(40) NOT NULL,
      granted BOOLEAN NOT NULL,
      version VARCHAR(20) NOT NULL,
      source VARCHAR(10) NOT NULL CHECK (source IN ('web', 'app')),
      decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (user_id, purpose)
    )
  `;
  // Every decision is appended: the proof that consent was asked, given and withdrawn.
  await sql`
    CREATE TABLE IF NOT EXISTS user_consent_events (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      purpose VARCHAR(40) NOT NULL,
      granted BOOLEAN NOT NULL,
      version VARCHAR(20) NOT NULL,
      source VARCHAR(10) NOT NULL CHECK (source IN ('web', 'app')),
      decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_user_consent_events_user ON user_consent_events (user_id, id)`;
}
