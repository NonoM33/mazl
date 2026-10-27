import type { Sql } from "postgres";
import { COUPLE_ACTIVITY_FIXTURES, COUPLE_EVENT_FIXTURES, coupleEventDate } from "./couple-outing-roster";

// The fake outings of the couple space during the TestFlight phase (12 activities
// and 6 couple events with free Unsplash photos), written at start-up with the
// test profiles (seedTestProfilesIfRequested) and removed by
// scripts/purge-seed-data.ts. Each row carries its fixture_key: the seed finds it
// again instead of writing it twice, and the purge removes exactly these rows.
// A later seed refreshes their text and moves an event only once its date passed.

type Db = Sql;

export interface TestOutingRow {
  readonly kind: "activity" | "event";
  readonly id: number;
  readonly key: string;
  readonly title: string;
}

export async function applyTestCoupleOutings(db: Db, today = new Date()): Promise<TestOutingRow[]> {
  return (await db.begin(async (transaction) => {
    const tx = transaction as unknown as Db;
    const rows: TestOutingRow[] = [];
    for (const activity of COUPLE_ACTIVITY_FIXTURES) {
      const [row] = await tx<{ id: number }[]>`
        INSERT INTO couple_activities (fixture_key, title, description, category, subcategory, image_url, price_cents, location, city,
                                       latitude, longitude, is_kosher, duration_minutes, tags, is_active)
        VALUES (${activity.key}, ${activity.title}, ${activity.description}, ${activity.category}, ${activity.subcategory ?? null}, ${activity.imageUrl},
                ${activity.priceCents}, ${activity.location}, ${activity.city}, ${activity.latitude}, ${activity.longitude}, ${activity.isKosher},
                ${activity.durationMinutes}, ${tx.json([...activity.tags])}, true)
        ON CONFLICT (fixture_key) WHERE fixture_key IS NOT NULL DO UPDATE SET
          title = EXCLUDED.title, description = EXCLUDED.description, category = EXCLUDED.category, subcategory = EXCLUDED.subcategory,
          image_url = EXCLUDED.image_url, price_cents = EXCLUDED.price_cents, location = EXCLUDED.location, city = EXCLUDED.city,
          latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, is_kosher = EXCLUDED.is_kosher,
          duration_minutes = EXCLUDED.duration_minutes, tags = EXCLUDED.tags, is_active = true, updated_at = NOW()
        RETURNING id`;
      if (row === undefined) throw new Error(`no row for ${activity.key}`);
      rows.push({ kind: "activity", id: row.id, key: activity.key, title: activity.title });
    }
    for (const event of COUPLE_EVENT_FIXTURES) {
      const date = coupleEventDate(event, today);
      const [row] = await tx<{ id: number }[]>`
        INSERT INTO couple_events (fixture_key, title, description, category, image_url, event_date, event_time, end_time, location, city,
                                   latitude, longitude, price_cents, max_couples, is_kosher, dress_code, what_included, is_featured, is_published)
        VALUES (${event.key}, ${event.title}, ${event.description}, ${event.category}, ${event.imageUrl}, ${date}::date, ${event.time}, ${event.endTime},
                ${event.location}, ${event.city}, ${event.latitude}, ${event.longitude}, ${event.priceCents}, ${event.maxCouples}, ${event.isKosher},
                ${event.dressCode ?? null}, ${event.whatIncluded ?? null}, ${event.isFeatured}, true)
        ON CONFLICT (fixture_key) WHERE fixture_key IS NOT NULL DO UPDATE SET
          title = EXCLUDED.title, description = EXCLUDED.description, category = EXCLUDED.category, image_url = EXCLUDED.image_url,
          event_time = EXCLUDED.event_time, end_time = EXCLUDED.end_time, location = EXCLUDED.location, city = EXCLUDED.city,
          latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, price_cents = EXCLUDED.price_cents, max_couples = EXCLUDED.max_couples,
          is_kosher = EXCLUDED.is_kosher, dress_code = EXCLUDED.dress_code, what_included = EXCLUDED.what_included,
          is_featured = EXCLUDED.is_featured, is_published = true,
          event_date = CASE WHEN couple_events.event_date < CURRENT_DATE THEN EXCLUDED.event_date ELSE couple_events.event_date END,
          updated_at = NOW()
        RETURNING id`;
      if (row === undefined) throw new Error(`no row for ${event.key}`);
      rows.push({ kind: "event", id: row.id, key: event.key, title: event.title });
    }
    return rows;
  })) as TestOutingRow[];
}

// The fake outings present in the database, for the purge.
export async function presentTestCoupleOutings(db: Db): Promise<TestOutingRow[]> {
  const activities = await db<{ id: number; fixture_key: string; title: string }[]>`SELECT id, fixture_key, title FROM couple_activities WHERE fixture_key IS NOT NULL ORDER BY id`;
  const events = await db<{ id: number; fixture_key: string; title: string }[]>`SELECT id, fixture_key, title FROM couple_events WHERE fixture_key IS NOT NULL ORDER BY id`;
  return [
    ...activities.map((row): TestOutingRow => ({ kind: "activity", id: row.id, key: row.fixture_key, title: row.title })),
    ...events.map((row): TestOutingRow => ({ kind: "event", id: row.id, key: row.fixture_key, title: row.title })),
  ];
}
