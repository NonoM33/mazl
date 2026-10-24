import type { Sql } from "postgres";
import type { LikeLedger } from "../application/ports";

export class PgLikeLedger implements LikeLedger {
  constructor(private readonly sql: Sql) {}

  async likesToday(userId: number): Promise<number> {
    const rows = await this.sql<{ used: number }[]>`
      SELECT COUNT(*)::int AS used FROM swipes
      WHERE user_id = ${userId} AND action = 'like' AND created_at >= DATE_TRUNC('day', NOW())
    `;
    return Number(rows[0]?.used ?? 0);
  }

  async hasLiked(userId: number, targetUserId: number): Promise<boolean> {
    const rows = await this.sql`
      SELECT 1 FROM swipes WHERE user_id = ${userId} AND target_user_id = ${targetUserId} AND action = 'like'
    `;
    return rows.length > 0;
  }

  async resetsAt(): Promise<Date> {
    const rows = await this.sql<{ resets_at: Date }[]>`SELECT DATE_TRUNC('day', NOW()) + INTERVAL '1 day' AS resets_at`;
    const resetsAt = rows[0]?.resets_at;
    if (resetsAt === undefined) throw new Error("like allowance: the database returned no reset time");
    return resetsAt;
  }
}
