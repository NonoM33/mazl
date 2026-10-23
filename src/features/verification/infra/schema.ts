import type { Sql } from "postgres";

// Tables and columns of the level 1 selfie verification (CONTRAT.md §5).
// Every statement is idempotent and runs at boot, after initDb() has created
// users, profiles and profile_photos. The profile_photos and profiles columns
// are also declared by other features: IF NOT EXISTS makes the overlap safe.
export async function ensureVerificationSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS face_verification_sessions (
      id UUID PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      purpose VARCHAR(10) NOT NULL,
      challenges JSONB NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      expires_at TIMESTAMP NOT NULL,
      consumed_at TIMESTAMP,
      outcome VARCHAR(40)
    )
  `;
  await sql`
    CREATE INDEX IF NOT EXISTS face_verification_sessions_user_day
    ON face_verification_sessions (user_id, purpose, created_at)
  `;
  await sql`
    CREATE TABLE IF NOT EXISTS face_references (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      embedding_sealed BYTEA NOT NULL,
      model VARCHAR(40) NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_verified_at TIMESTAMP`;
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS identity_verified_at TIMESTAMP`;
  await sql`ALTER TABLE profile_photos ADD COLUMN IF NOT EXISTS face_match BOOLEAN`;
  await sql`ALTER TABLE profile_photos ADD COLUMN IF NOT EXISTS face_checked_at TIMESTAMP`;
}
