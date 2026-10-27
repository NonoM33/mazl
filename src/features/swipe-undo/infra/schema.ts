import type { Sql } from "postgres";

// The undos a free member used today: a count per member and day, no history of
// who was taken back. Rows older than two days are purged by the next undo.
export async function ensureSwipeUndoSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS swipe_undo_ledger (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      day DATE NOT NULL,
      used INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, day)
    )
  `;
}
