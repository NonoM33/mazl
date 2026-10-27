import type { Sql } from "postgres";
import type { ScheduleOutcome, ScheduleStore } from "../application/ports";

const DAY_MS = 24 * 3_600_000;

export class PgScheduleStore implements ScheduleStore {
  constructor(private readonly sql: Sql) {}

  async schedule(userId: number, runAt: Date): Promise<ScheduleOutcome> {
    // A schedule already run (claimed) is replaced; one still waiting is not.
    const rows = await this.sql`
      INSERT INTO boost_schedules (user_id, run_at) VALUES (${userId}, ${runAt})
      ON CONFLICT (user_id) DO UPDATE SET run_at = EXCLUDED.run_at, claimed_at = NULL, created_at = now()
        WHERE boost_schedules.claimed_at IS NOT NULL
      RETURNING user_id
    `;
    return rows.length > 0 ? "scheduled" : "already_scheduled";
  }

  async get(userId: number): Promise<Date | null> {
    const [row] = await this.sql<{ run_at: Date }[]>`SELECT run_at FROM boost_schedules WHERE user_id = ${userId} AND claimed_at IS NULL`;
    return row?.run_at ?? null;
  }

  async cancel(userId: number): Promise<void> {
    await this.sql`DELETE FROM boost_schedules WHERE user_id = ${userId} AND claimed_at IS NULL`;
  }

  async claimDue(now: Date, graceMs: number): Promise<number[]> {
    const tooLate = new Date(now.getTime() - graceMs);
    await this.sql`DELETE FROM boost_schedules WHERE claimed_at IS NULL AND run_at < ${tooLate}`;
    await this.sql`DELETE FROM boost_schedules WHERE claimed_at IS NOT NULL AND claimed_at < ${new Date(now.getTime() - DAY_MS)}`;
    const rows = await this.sql<{ user_id: number }[]>`
      UPDATE boost_schedules SET claimed_at = ${now}
      WHERE claimed_at IS NULL AND run_at <= ${now}
      RETURNING user_id
    `;
    return rows.map((row) => row.user_id);
  }

  async forgetRun(userIds: readonly number[]): Promise<void> {
    if (userIds.length === 0) return;
    await this.sql`DELETE FROM boost_schedules WHERE user_id IN ${this.sql(userIds)} AND claimed_at IS NOT NULL`;
  }
}
