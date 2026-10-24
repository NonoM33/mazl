import type { Sql } from "postgres";
import type { LikeLedger, Reservation } from "../application/ports";

// Key space of the advisory locks of the like ledger (one lock per member).
const LOCK_SPACE = 7_270_001;

export class PgLikeLedger implements LikeLedger {
  constructor(private readonly sql: Sql) {}

  async likesToday(userId: number): Promise<number> {
    const rows = await this.sql<{ used: number }[]>`
      SELECT COUNT(*)::int AS used FROM like_allowance_ledger WHERE user_id = ${userId} AND day = CURRENT_DATE
    `;
    return Number(rows[0]?.used ?? 0);
  }

  async hasLiked(userId: number, targetUserId: number): Promise<boolean> {
    const rows = await this.sql`
      SELECT 1 FROM swipes WHERE user_id = ${userId} AND target_user_id = ${targetUserId} AND action = 'like'
    `;
    return rows.length > 0;
  }

  async reserve(userId: number, targetUserId: number, limit: number): Promise<Reservation> {
    // The postgres types do not see a transaction as callable: the same cast
    // as the credits repository.
    return (await this.sql.begin((transaction) => this.reserveIn(transaction as unknown as Sql, userId, targetUserId, limit))) as Reservation;
  }

  private async reserveIn(tx: Sql, userId: number, targetUserId: number, limit: number): Promise<Reservation> {
    await tx`SELECT pg_advisory_xact_lock(${LOCK_SPACE}, ${userId})`;
    const counted = await tx`
      SELECT 1 FROM like_allowance_ledger WHERE user_id = ${userId} AND day = CURRENT_DATE AND target_user_id = ${targetUserId}
    `;
    if (counted.length > 0) return "already_counted";
    const [row] = await tx<{ used: number }[]>`
      SELECT COUNT(*)::int AS used FROM like_allowance_ledger WHERE user_id = ${userId} AND day = CURRENT_DATE
    `;
    if (Number(row?.used ?? 0) >= limit) return "exhausted";
    await tx`INSERT INTO like_allowance_ledger (user_id, day, target_user_id) VALUES (${userId}, CURRENT_DATE, ${targetUserId})`;
    // Only today matters: older rows of this member go, so the ledger keeps
    // no history of who was liked.
    await tx`DELETE FROM like_allowance_ledger WHERE user_id = ${userId} AND day < CURRENT_DATE - 1`;
    return "reserved";
  }

  async release(userId: number, targetUserId: number): Promise<void> {
    await this.sql`
      DELETE FROM like_allowance_ledger WHERE user_id = ${userId} AND day = CURRENT_DATE AND target_user_id = ${targetUserId}
    `;
  }

  async resetsAt(): Promise<Date> {
    const rows = await this.sql<{ resets_at: Date }[]>`SELECT DATE_TRUNC('day', NOW()) + INTERVAL '1 day' AS resets_at`;
    const resetsAt = rows[0]?.resets_at;
    if (resetsAt === undefined) throw new Error("like allowance: the database returned no reset time");
    return resetsAt;
  }
}
