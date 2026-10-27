import type { Sql } from "postgres";
import { zonedInstant } from "../domain/local-time";
import type { OutingCandidate } from "../domain/outings";

interface ActivityRow {
  id: number; title: string; location: string | null; city: string | null; image_url: string | null;
  price_cents: number | null; is_kosher: boolean | null; is_partner: boolean | null; saved: boolean;
}
interface EventRow {
  id: number; title: string; location: string | null; city: string | null; image_url: string | null;
  price_cents: number | null; is_kosher: boolean | null; is_featured: boolean | null; day: string; time: string | null; saved: boolean;
}

// Every outing a couple can see: the active activities it did not pass and the
// published couple events still to come. An event counts as saved once the
// couple registered. Dates are Paris wall-clock times.
export class PgOutings {
  constructor(private readonly sql: Sql) {}

  async candidates(coupleId: number, today: string, timeZone: string): Promise<OutingCandidate[]> {
    const activities = await this.sql<ActivityRow[]>`
      SELECT a.id, a.title, a.location, a.city, a.image_url, a.price_cents, a.is_kosher, a.is_partner,
             EXISTS (SELECT 1 FROM couple_saved_activities s WHERE s.couple_id = ${coupleId} AND s.activity_id = a.id) AS saved
      FROM couple_activities a
      WHERE a.is_active = true
        AND NOT EXISTS (SELECT 1 FROM couple_passed_activities p WHERE p.couple_id = ${coupleId} AND p.activity_id = a.id)
      ORDER BY a.is_partner DESC NULLS LAST, a.id`;
    const events = await this.sql<EventRow[]>`
      SELECT e.id, e.title, e.location, e.city, e.image_url, e.price_cents, e.is_kosher, e.is_featured,
             to_char(e.event_date, 'YYYY-MM-DD') AS day, to_char(e.event_time, 'HH24:MI') AS time,
             EXISTS (SELECT 1 FROM couple_event_registrations r WHERE r.couple_id = ${coupleId} AND r.event_id = e.id AND r.status = 'registered') AS saved
      FROM couple_events e
      WHERE e.is_published = true AND e.event_date >= ${today}::date
      ORDER BY e.event_date, e.event_time NULLS FIRST, e.id`;
    const fromEvents = events.map((row): OutingCandidate => {
      const [year, month, day] = row.day.split("-").map(Number);
      const [hour, minute] = (row.time ?? "00:00").split(":").map(Number);
      return {
        id: Number(row.id), kind: "event", title: row.title, subtitle: row.location ?? row.city ?? "", imageUrl: row.image_url, city: row.city,
        startsAt: zonedInstant(year ?? 1970, month ?? 1, day ?? 1, hour ?? 0, minute ?? 0, timeZone).toISOString(),
        priceCents: row.price_cents === null ? null : Number(row.price_cents), kosher: row.is_kosher === true, saved: row.saved,
        partner: false, featured: row.is_featured === true,
      };
    });
    const fromActivities = activities.map((row): OutingCandidate => ({
      id: Number(row.id), kind: "activity", title: row.title, subtitle: row.location ?? row.city ?? "", imageUrl: row.image_url, city: row.city,
      startsAt: null, priceCents: row.price_cents === null ? null : Number(row.price_cents), kosher: row.is_kosher === true, saved: row.saved,
      partner: row.is_partner === true, featured: false,
    }));
    return [...fromEvents, ...fromActivities];
  }
}
