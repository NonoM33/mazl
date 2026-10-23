import { sql } from "../../../db";

// CONTRAT.md §5, "media" block, plus the two profile columns the badge queries
// read (the verification feature writes them).
export async function ensureMediaSchema(): Promise<void> {
  await sql`ALTER TABLE profile_photos ADD COLUMN IF NOT EXISTS face_match BOOLEAN`;
  await sql`ALTER TABLE profile_photos ADD COLUMN IF NOT EXISTS face_checked_at TIMESTAMP`;
  await sql`
    CREATE TABLE IF NOT EXISTS location_updates (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_location_updates_user_time ON location_updates (user_id, created_at)`;
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_verified_at TIMESTAMP`;
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS identity_verified_at TIMESTAMP`;
  // false = the stored position may still be exact (see location-backfill).
  await sql`ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_fuzzed BOOLEAN NOT NULL DEFAULT false`;
}
