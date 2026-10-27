import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres, { type Sql } from "postgres";
import { applyTestCoupleOutings } from "../src/features/fixtures/couple-outings";
import { applySeedPurge, planSeedPurge } from "../src/features/fixtures/seed-purge";
import { bootServerSchema, createScratchDatabase, type ScratchDatabase } from "./support/scratch-database";

// The fake outings of the TestFlight phase: written once however many restarts,
// dated in the future, and removed exactly by the purge.

let scratch: ScratchDatabase;
let sql: Sql;

beforeAll(async () => {
  scratch = await createScratchDatabase();
  await bootServerSchema(scratch.url, "test");
  sql = postgres(scratch.url, { max: 2, onnotice: () => undefined });
}, 60_000);

afterAll(async () => {
  await sql?.end({ timeout: 2 });
  await scratch?.drop();
});

const count = async (query: Promise<{ n: string }[]>): Promise<number> => Number((await query)[0]?.n);

describe("seeding", () => {
  test("12 activities and 6 events, once, however many times", async () => {
    await applyTestCoupleOutings(sql);
    await applyTestCoupleOutings(sql);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_activities WHERE fixture_key IS NOT NULL`)).toBe(12);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_events WHERE fixture_key IS NOT NULL`)).toBe(6);
  });

  test("events are in the future, published, with a photo; activities are active with a photo and coordinates", async () => {
    const events = await sql<{ future: boolean; published: boolean; image_url: string; city: string }[]>`SELECT event_date > CURRENT_DATE AS future, is_published AS published, image_url, city FROM couple_events WHERE fixture_key IS NOT NULL`;
    expect(events.every((e) => e.future && e.published && e.image_url.startsWith("https://images.unsplash.com/photo-"))).toBe(true);
    const activities = await sql<{ is_active: boolean; image_url: string; latitude: string; longitude: string }[]>`SELECT is_active, image_url, latitude, longitude FROM couple_activities WHERE fixture_key IS NOT NULL`;
    expect(activities.every((a) => a.is_active && a.image_url.startsWith("https://images.unsplash.com/photo-") && Number(a.latitude) > 41)).toBe(true);
    const photos = [...events.map((e) => e.image_url), ...activities.map((a) => a.image_url)];
    expect(new Set(photos).size).toBe(18);
  });

  test("a later seed refreshes the text but does not move an event that is still to come", async () => {
    await sql`UPDATE couple_events SET title = 'Modifié', event_date = event_date + 3 WHERE fixture_key = 'test-couple-event-shabbat-paris'`;
    const [before] = await sql<{ d: string }[]>`SELECT event_date::text AS d FROM couple_events WHERE fixture_key = 'test-couple-event-shabbat-paris'`;
    await applyTestCoupleOutings(sql);
    const [after] = await sql<{ d: string; title: string }[]>`SELECT event_date::text AS d, title FROM couple_events WHERE fixture_key = 'test-couple-event-shabbat-paris'`;
    expect(after?.d).toBe(before?.d);
    expect(after?.title).not.toBe("Modifié");
    await sql`UPDATE couple_events SET event_date = CURRENT_DATE - 10 WHERE fixture_key = 'test-couple-event-shabbat-paris'`;
    await applyTestCoupleOutings(sql);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_events WHERE fixture_key = 'test-couple-event-shabbat-paris' AND event_date > CURRENT_DATE`)).toBe(1);
  });
});

describe("the purge", () => {
  test("removes exactly the fake outings, with what hangs on them, and keeps a real couple's own content", async () => {
    const users = await sql<{ id: number }[]>`INSERT INTO users (email, name, provider, provider_id) VALUES ('seed-out-a@example.com', 'a', 'test', 'a'), ('seed-out-b@example.com', 'b', 'test', 'b') RETURNING id`;
    const userA = users[0]?.id ?? 0;
    const userB = users[1]?.id ?? 0;
    const [couple] = await sql<{ id: number }[]>`INSERT INTO couples (user1_id, user2_id) VALUES (${userA}, ${userB}) RETURNING id`;
    const [fakeActivity] = await sql<{ id: number }[]>`SELECT id FROM couple_activities WHERE fixture_key IS NOT NULL LIMIT 1`;
    const [fakeEvent] = await sql<{ id: number }[]>`SELECT id FROM couple_events WHERE fixture_key IS NOT NULL LIMIT 1`;
    await sql`INSERT INTO couple_saved_activities (couple_id, activity_id) VALUES (${couple?.id ?? 0}, ${fakeActivity?.id ?? 0})`;
    await sql`INSERT INTO couple_event_registrations (couple_id, event_id) VALUES (${couple?.id ?? 0}, ${fakeEvent?.id ?? 0})`;
    await sql`INSERT INTO couple_bookings (couple_id, activity_id, booking_date) VALUES (${couple?.id ?? 0}, ${fakeActivity?.id ?? 0}, CURRENT_DATE)`;
    await sql`INSERT INTO couple_activities (title, category, city) VALUES ('Atelier du voisin', 'diy', 'Lyon')`;
    await sql`INSERT INTO couple_events (title, event_date) VALUES ('Soirée du voisin', CURRENT_DATE + 5)`;

    const plan = await planSeedPurge(sql);
    expect(plan.testCoupleOutings).toHaveLength(18);
    expect(plan.testCoupleOutings.filter((o) => o.kind === "activity")).toHaveLength(12);

    await applySeedPurge(sql);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_activities WHERE fixture_key IS NOT NULL`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_events WHERE fixture_key IS NOT NULL`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_saved_activities`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_event_registrations`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_bookings`)).toBe(0);
    expect((await sql<{ title: string }[]>`SELECT title FROM couple_activities`).map((r) => r.title)).toContain("Atelier du voisin");
    expect((await sql<{ title: string }[]>`SELECT title FROM couple_events`).map((r) => r.title)).toContain("Soirée du voisin");
  });
});
