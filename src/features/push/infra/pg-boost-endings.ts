import type { Sql } from "postgres";

// The Boosts that ended and whose member was not told yet, claimed at once so
// that two sweeps (or two servers) never tell the same end twice. A Boost that
// ended more than an hour ago is never told: after a long stop of the server,
// "your Boost is over" would come too late to mean anything.
export class PgBoostEndings {
  constructor(private readonly sql: Sql) {}

  async claimEnded(): Promise<number[]> {
    const rows = await this.sql<{ user_id: number }[]>`
      UPDATE boosts SET end_notified_at = NOW()
      WHERE id IN (
        SELECT id FROM boosts
        WHERE end_notified_at IS NULL AND expires_at <= NOW() AND expires_at > NOW() - INTERVAL '1 hour'
        FOR UPDATE SKIP LOCKED
      )
      RETURNING user_id`;
    return [...new Set(rows.map((row) => row.user_id))];
  }
}
