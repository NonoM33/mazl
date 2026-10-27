import type { Sql } from "postgres";
import type { Ratings } from "../domain/checkin";
import type { Mood } from "../domain/mood";
import type { UpcomingDate, UpcomingEvent } from "../domain/upcoming";

export interface CheckinRow {
  readonly userId: number;
  readonly ratings: Ratings;
}

const isUniqueViolation = (error: unknown): boolean => typeof error === "object" && error !== null && (error as { code?: unknown }).code === "23505";

// Moods, check-ins and the small readers of the Today screen.
export class PgCoupleSpace {
  constructor(private readonly sql: Sql) {}

  async moods(coupleId: number, userId: number, partnerId: number, day: string): Promise<{ mine: Mood | null; partner: Mood | null }> {
    const rows = await this.sql<{ user_id: number; mood: Mood }[]>`
      SELECT user_id, mood FROM couple_moods WHERE couple_id = ${coupleId} AND day = ${day}::date AND user_id IN (${userId}, ${partnerId})`;
    return {
      mine: rows.find((row) => Number(row.user_id) === userId)?.mood ?? null,
      partner: rows.find((row) => Number(row.user_id) === partnerId)?.mood ?? null,
    };
  }

  // Returns the mood the member had set that day before, if any.
  async setMood(coupleId: number, userId: number, day: string, mood: Mood): Promise<Mood | null> {
    const [before] = await this.sql<{ mood: Mood }[]>`SELECT mood FROM couple_moods WHERE user_id = ${userId} AND day = ${day}::date`;
    await this.sql`
      INSERT INTO couple_moods (user_id, couple_id, day, mood) VALUES (${userId}, ${coupleId}, ${day}::date, ${mood})
      ON CONFLICT (user_id, day) DO UPDATE SET mood = EXCLUDED.mood, couple_id = EXCLUDED.couple_id`;
    return before?.mood ?? null;
  }

  async checkins(coupleId: number, period: string): Promise<CheckinRow[]> {
    const rows = await this.sql<{ user_id: number; talk: number; time: number; close: number }[]>`
      SELECT user_id, talk, time, close FROM couple_checkins WHERE couple_id = ${coupleId} AND period = ${period}`;
    return rows.map((row) => ({ userId: Number(row.user_id), ratings: { talk: Number(row.talk), time: Number(row.time), close: Number(row.close) } }));
  }

  // False when this member already answered this period.
  async saveCheckin(coupleId: number, userId: number, period: string, ratings: Ratings): Promise<boolean> {
    try {
      await this.sql`
        INSERT INTO couple_checkins (couple_id, user_id, period, talk, time, close)
        VALUES (${coupleId}, ${userId}, ${period}, ${ratings.talk}, ${ratings.time}, ${ratings.close})`;
      return true;
    } catch (error: unknown) {
      if (isUniqueViolation(error)) return false;
      throw error;
    }
  }

  async dates(coupleId: number): Promise<UpcomingDate[]> {
    const rows = await this.sql<{ id: number; title: string; type: string; date: string; is_recurring: boolean | null }[]>`
      SELECT id, title, type, to_char(date, 'YYYY-MM-DD') AS date, is_recurring FROM couple_dates WHERE couple_id = ${coupleId}`;
    return rows.map((row) => ({ id: Number(row.id), title: row.title, type: row.type, date: row.date, isRecurring: row.is_recurring ?? true }));
  }

  async registeredEvents(coupleId: number, fromDay: string): Promise<UpcomingEvent[]> {
    const rows = await this.sql<{ id: number; title: string; place: string | null; day: string; time: string | null }[]>`
      SELECT e.id, e.title, COALESCE(e.location, e.city, '') AS place, to_char(e.event_date, 'YYYY-MM-DD') AS day, to_char(e.event_time, 'HH24:MI') AS time
      FROM couple_event_registrations r JOIN couple_events e ON e.id = r.event_id
      WHERE r.couple_id = ${coupleId} AND r.status = 'registered' AND e.event_date >= ${fromDay}::date
      ORDER BY e.event_date LIMIT 20`;
    return rows.map((row) => ({ id: Number(row.id), title: row.title, place: row.place ?? "", day: row.day, time: row.time }));
  }
}
