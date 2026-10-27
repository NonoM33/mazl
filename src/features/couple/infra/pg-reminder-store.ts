import type { Sql } from "postgres";
import type { ReminderCouple, ReminderStore } from "../application/reminder-ports";
import type { CoupleDate, ReminderPlan } from "../domain/reminders";
import type { Ritual } from "../domain/rituals";
import { PgRituals } from "./pg-rituals";

const toNumber = (value: string | number | null): number | null => (value === null ? null : Number(value));

export class PgReminderStore implements ReminderStore {
  private readonly rituals: PgRituals;

  constructor(private readonly sql: Sql) {
    this.rituals = new PgRituals(sql);
  }

  async couplesWithPremium(): Promise<ReminderCouple[]> {
    const rows = await this.sql<{ id: number; user1_id: number; user2_id: number; latitude: string | null; longitude: string | null }[]>`
      SELECT c.id, c.user1_id, c.user2_id, p.latitude, p.longitude
      FROM couples c
      LEFT JOIN profiles p ON p.user_id = COALESCE(
        (SELECT r.requester_id FROM couple_requests r
          WHERE r.status = 'accepted'
            AND LEAST(r.requester_id, r.target_id) = LEAST(c.user1_id, c.user2_id)
            AND GREATEST(r.requester_id, r.target_id) = GREATEST(c.user1_id, c.user2_id)
          ORDER BY r.id DESC LIMIT 1),
        c.user1_id)
      WHERE c.status = 'active' AND EXISTS (
        SELECT 1 FROM subscriptions s
        WHERE s.user_id IN (c.user1_id, c.user2_id) AND s.plan_type = 'couple_monthly'
          AND s.status = 'active' AND s.expires_at > (NOW() AT TIME ZONE 'UTC'))`;
    return rows.map((row) => ({
      id: Number(row.id),
      memberIds: [Number(row.user1_id), Number(row.user2_id)] as const,
      latitude: toNumber(row.latitude),
      longitude: toNumber(row.longitude),
    }));
  }

  async dates(coupleId: number): Promise<CoupleDate[]> {
    const rows = await this.sql<{ id: number; date: string; is_recurring: boolean | null; remind_days_before: number | null }[]>`
      SELECT id, to_char(date, 'YYYY-MM-DD') AS date, is_recurring, remind_days_before
      FROM couple_dates WHERE couple_id = ${coupleId}`;
    return rows.map((row) => ({
      id: Number(row.id),
      date: row.date,
      isRecurring: row.is_recurring ?? true,
      remindDaysBefore: Number(row.remind_days_before ?? 7),
    }));
  }

  enabledRituals(coupleId: number): Promise<Ritual[]> {
    return this.rituals.enabled(coupleId);
  }

  async claim(coupleId: number, plan: ReminderPlan): Promise<boolean> {
    const rows = await this.sql`
      INSERT INTO couple_reminders_sent (couple_id, source, ref_id, occurrence)
      VALUES (${coupleId}, ${plan.source}, ${plan.refId}, ${plan.occurrence})
      ON CONFLICT (couple_id, source, ref_id, occurrence) DO NOTHING
      RETURNING id`;
    return rows.length > 0;
  }
}
