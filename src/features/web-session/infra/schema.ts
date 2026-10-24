import type { Sql } from "postgres";

// Idempotent, called at boot after the users table exists.
export async function ensureWebSessionSchema(sql: Sql): Promise<void> {
  // A QR sign-in in progress. Neither the code (shown in the QR) nor the
  // browser secret (kept by the browser) is stored in clear.
  await sql`
    CREATE TABLE IF NOT EXISTS web_pairings (
      id UUID PRIMARY KEY,
      code_hash TEXT NOT NULL,
      browser_secret_hash TEXT NOT NULL,
      browser_label VARCHAR(100) NOT NULL,
      status VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'scanned', 'approved', 'denied', 'consumed')),
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      expires_at TIMESTAMPTZ NOT NULL,
      scanned_at TIMESTAMPTZ,
      decided_at TIMESTAMPTZ
    )
  `;
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_web_pairings_code ON web_pairings (code_hash)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_web_pairings_expires ON web_pairings (expires_at)`;
  await sql`
    CREATE TABLE IF NOT EXISTS web_sessions (
      id UUID PRIMARY KEY,
      token_hash TEXT NOT NULL UNIQUE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      browser_label VARCHAR(100) NOT NULL,
      method VARCHAR(10) NOT NULL CHECK (method IN ('qr', 'google', 'apple')),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      idle_expires_at TIMESTAMPTZ NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      revoked_at TIMESTAMPTZ
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_web_sessions_user ON web_sessions (user_id, created_at DESC)`;
}
