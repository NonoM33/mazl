import type { Sql } from "postgres";
import type { EventAlertStore, OpenedEvent } from "../application/ports";
import { isEventAvailability, type EventAvailability } from "../domain/event-availability";

// The alerts (« Me prévenir ») and the availability of events, in Postgres.
// Only members whose account is active and carries no restriction, suspension
// or ban in force are told when an event opens; the others keep their alert.
export class PgEventAlertStore implements EventAlertStore {
  constructor(private readonly sql: Sql) {}

  async availabilityOf(eventId: number): Promise<EventAvailability | null> {
    const [row] = await this.sql<{ availability: string }[]>`SELECT availability FROM events WHERE id = ${eventId} AND is_published = true`;
    return row !== undefined && isEventAvailability(row.availability) ? row.availability : null;
  }

  async request(eventId: number, userId: number): Promise<void> {
    await this.sql`INSERT INTO event_open_alerts (event_id, user_id) VALUES (${eventId}, ${userId}) ON CONFLICT (event_id, user_id) DO NOTHING`;
  }

  async withdraw(eventId: number, userId: number): Promise<void> {
    await this.sql`DELETE FROM event_open_alerts WHERE event_id = ${eventId} AND user_id = ${userId}`;
  }

  async isRequested(eventId: number, userId: number): Promise<boolean> {
    const [row] = await this.sql<{ found: boolean }[]>`
      SELECT EXISTS (SELECT 1 FROM event_open_alerts WHERE event_id = ${eventId} AND user_id = ${userId}) AS found`;
    return row?.found === true;
  }

  async open(eventId: number): Promise<OpenedEvent | null> {
    // The previous availability is read in the same statement as the update.
    const [row] = await this.sql<{ title: string; is_published: boolean | null; was_open: boolean }[]>`
      UPDATE events e SET availability = 'open', updated_at = NOW()
      FROM (SELECT id, availability = 'open' AS was_open FROM events WHERE id = ${eventId} FOR UPDATE) before
      WHERE e.id = before.id
      RETURNING e.title, e.is_published, before.was_open`;
    if (row === undefined) return null;
    return { title: row.title, published: row.is_published === true, alreadyOpen: row.was_open };
  }

  async pendingRecipients(eventId: number): Promise<number[]> {
    const rows = await this.sql<{ user_id: number }[]>`
      SELECT a.user_id FROM event_open_alerts a JOIN users u ON u.id = a.user_id
      WHERE a.event_id = ${eventId} AND a.notified_at IS NULL AND u.is_active IS NOT FALSE
        AND NOT EXISTS (
          SELECT 1 FROM member_sanctions s
          WHERE s.user_id = u.id AND s.revoked_at IS NULL AND s.starts_at <= now()
            AND (s.ends_at IS NULL OR s.ends_at > now())
            AND s.kind IN ('restriction', 'suspension', 'ban'))
      ORDER BY a.created_at, a.user_id`;
    return rows.map((row) => row.user_id);
  }

  async markNotified(eventId: number, userIds: readonly number[]): Promise<void> {
    if (userIds.length === 0) return;
    await this.sql`UPDATE event_open_alerts SET notified_at = NOW() WHERE event_id = ${eventId} AND user_id IN ${this.sql(userIds as number[])}`;
  }
}
