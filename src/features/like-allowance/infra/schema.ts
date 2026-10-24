import type { Sql } from "postgres";

// The day's likes, append-only: a later pass or upsert of the swipe row does
// not give a like back (security review M3). One row per member, day and
// target. The target is a plain id (a like to an unknown member must reach
// the swipe route and its 404), and rows older than two days are purged.
export async function ensureLikeAllowanceSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS like_allowance_ledger (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      day DATE NOT NULL,
      target_user_id INTEGER NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (user_id, day, target_user_id)
    )
  `;
}
