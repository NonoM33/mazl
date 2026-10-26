import type { Sql } from "postgres";
import { TEST_EVENTS, TEST_EVENT_ADDRESS, testEventDate } from "./test-event-roster";

// The fake events of the TestFlight phase, written at start-up with the test
// profiles (seedTestProfilesIfRequested) and removed by scripts/purge-seed-data.ts.
// Each row carries its fixture_key: the seed finds it again instead of writing
// it twice, and the purge removes exactly these rows.
//
// They are written "coming soon" and published. A later seed refreshes their
// text but never their availability (an administrator may have opened one),
// and moves their date only once it has passed.

type Db = Sql;

export interface TestEventRow {
  readonly id: number;
  readonly key: string;
  readonly title: string;
}

export async function applyTestEvents(db: Db, today = new Date()): Promise<TestEventRow[]> {
  return (await db.begin(async (transaction) => {
    const tx = transaction as unknown as Db;
    const rows: TestEventRow[] = [];
    for (const event of TEST_EVENTS) {
      const [row] = await tx<{ id: number }[]>`
        INSERT INTO events (fixture_key, title, description, event_type, location, address, date, time, end_time,
                            price, currency, max_attendees, image_url, is_published, availability)
        VALUES (${event.key}, ${event.title}, ${event.description}, ${event.kind}, ${event.venue}, ${TEST_EVENT_ADDRESS},
                ${testEventDate(event, today)}, ${event.time}, ${event.endTime}, ${event.price}, 'EUR', ${event.maxAttendees},
                NULL, true, 'coming_soon')
        ON CONFLICT (fixture_key) DO UPDATE SET
          title = EXCLUDED.title, description = EXCLUDED.description, event_type = EXCLUDED.event_type,
          location = EXCLUDED.location, address = EXCLUDED.address, time = EXCLUDED.time, end_time = EXCLUDED.end_time,
          price = EXCLUDED.price, currency = EXCLUDED.currency, max_attendees = EXCLUDED.max_attendees,
          image_url = NULL, is_published = true,
          date = CASE WHEN events.date < CURRENT_DATE THEN EXCLUDED.date ELSE events.date END,
          updated_at = NOW()
        RETURNING id`;
      if (row === undefined) throw new Error(`no row for ${event.key}`);
      rows.push({ id: row.id, key: event.key, title: event.title });
    }
    return rows;
  })) as TestEventRow[];
}

// The fake events present in the database, for the purge.
export async function presentTestEvents(db: Db): Promise<TestEventRow[]> {
  const rows = await db<{ id: number; fixture_key: string; title: string }[]>`
    SELECT id, fixture_key, title FROM events WHERE fixture_key IS NOT NULL ORDER BY id`;
  return rows.map((row) => ({ id: row.id, key: row.fixture_key, title: row.title }));
}
