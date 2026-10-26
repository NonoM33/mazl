import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { bootServerSchema, createScratchDatabase, runBun, type ScratchDatabase } from "./support/scratch-database";

// scripts/purge-seed-data.ts removes what releases before the v1 left in a real
// database: the twenty fake members (provider 'seed') with everything that hangs
// on them, and the fictitious couple catalogue. Dry-run by default.
// Runs ONLY against a database created here, inside the throwaway Postgres.

let scratch: ScratchDatabase;
let sql: postgres.Sql;

const SCRIPT = "scripts/purge-seed-data.ts";
const purge = (...flags: string[]) => runBun([SCRIPT, ...flags], { DATABASE_URL: scratch.url, NODE_ENV: "production" });
const one = async <T extends object>(rows: Promise<T[]>): Promise<T> => {
  const [row] = await rows;
  if (row === undefined) throw new Error("no row");
  return row;
};
const count = async (query: Promise<{ n: string }[]>): Promise<number> => Number((await one(query)).n);

interface World {
  readonly realA: number;
  readonly realB: number;
  readonly realC: number;
  readonly seedWithRealMatch: number;
  readonly savedByRealCouple: string;
  readonly registeredByRealCouple: string;
}

async function insertReal(email: string, name: string): Promise<number> {
  const user = await one(sql<{ id: number }[]>`INSERT INTO users (email, name, provider, provider_id) VALUES (${email}, ${name}, 'apple', ${email}) RETURNING id`);
  await sql`INSERT INTO profiles (user_id, display_name, gender, is_complete) VALUES (${user.id}, ${name}, 'female', true)`;
  return user.id;
}

// 20 seed members and the sample catalogue come from the boot; real members, their
// links to seed members and a real couple's use of the catalogue are added here.
async function buildWorld(): Promise<World> {
  const [realA, realB, realC] = [await insertReal("alice@example.com", "Alice Exemple"), await insertReal("bruno@example.com", "Bruno Exemple"), await insertReal("chloe@example.com", "Chloe Exemple")];
  const seedIds = (await sql<{ id: number }[]>`SELECT id FROM users WHERE provider = 'seed' ORDER BY id`).map((row) => row.id);
  const [seedWithRealMatch, seedInCouple] = [seedIds[0], seedIds[1]];
  if (seedWithRealMatch === undefined || seedInCouple === undefined) throw new Error("no seed members");

  // A real member swiped on a seed member, matched, and the seed member wrote to them.
  await sql`INSERT INTO swipes (user_id, target_user_id, action) VALUES (${realA}, ${seedWithRealMatch}, 'like'), (${seedWithRealMatch}, ${realA}, 'like')`;
  const match = await one(sql<{ id: number }[]>`INSERT INTO matches (user1_id, user2_id) VALUES (${realA}, ${seedWithRealMatch}) RETURNING id`);
  const conversation = await one(sql<{ id: number }[]>`INSERT INTO conversations (match_id, user1_id, user2_id) VALUES (${match.id}, ${realA}, ${seedWithRealMatch}) RETURNING id`);
  await sql`INSERT INTO messages (conversation_id, sender_id, content) VALUES (${conversation.id}, ${seedWithRealMatch}, 'Shalom')`;

  // A real couple saved a sample activity and registered to a sample event: both stay.
  const realCouple = await one(sql<{ id: number }[]>`INSERT INTO couples (user1_id, user2_id) VALUES (${realB}, ${realC}) RETURNING id`);
  const saved = await one(sql<{ id: number; title: string }[]>`SELECT id, title FROM couple_activities WHERE title = 'Yoga en Duo'`);
  await sql`INSERT INTO couple_saved_activities (couple_id, activity_id) VALUES (${realCouple.id}, ${saved.id})`;
  const registered = await one(sql<{ id: number; title: string }[]>`SELECT id, title FROM couple_events WHERE title = 'Soirée Dansante Années 80'`);
  await sql`INSERT INTO couple_event_registrations (couple_id, event_id) VALUES (${realCouple.id}, ${registered.id})`;

  // A couple that includes a seed member saved another sample activity: it goes with them.
  const seedCouple = await one(sql<{ id: number }[]>`INSERT INTO couples (user1_id, user2_id) VALUES (${seedInCouple}, ${realA}) RETURNING id`);
  const other = await one(sql<{ id: number }[]>`SELECT id FROM couple_activities WHERE title = 'Massage aux Pierres Chaudes'`);
  await sql`INSERT INTO couple_saved_activities (couple_id, activity_id) VALUES (${seedCouple.id}, ${other.id})`;

  // A "coming soon" test event that a real member asked to be told about: it goes, with the alert.
  const testEvent = await one(sql<{ id: number }[]>`
    INSERT INTO events (fixture_key, title, date, is_published, availability) VALUES ('test-event-purge', 'Dîner de Shabbat des tests', CURRENT_DATE + 7, true, 'coming_soon') RETURNING id`);
  await sql`INSERT INTO event_open_alerts (event_id, user_id) VALUES (${testEvent.id}, ${realA})`;
  // A real event stays.
  await sql`INSERT INTO events (title, date, is_published) VALUES ('Soirée du partenaire', CURRENT_DATE + 7, true)`;

  // Content that is not sample data at all.
  await sql`INSERT INTO couple_activities (title, description, category, city, location) VALUES ('Atelier du quartier', 'Propose par un partenaire', 'diy', 'Lyon', 'Maison des associations')`;
  return { realA, realB, realC, seedWithRealMatch, savedByRealCouple: saved.title, registeredByRealCouple: registered.title };
}

const counters = async () => ({
  seedUsers: await count(sql`SELECT COUNT(*)::text AS n FROM users WHERE provider = 'seed'`),
  realUsers: await count(sql`SELECT COUNT(*)::text AS n FROM users WHERE provider <> 'seed'`),
  activities: await count(sql`SELECT COUNT(*)::text AS n FROM couple_activities`),
  events: await count(sql`SELECT COUNT(*)::text AS n FROM couple_events`),
  messages: await count(sql`SELECT COUNT(*)::text AS n FROM messages`),
  testEvents: await count(sql`SELECT COUNT(*)::text AS n FROM events WHERE fixture_key IS NOT NULL`),
  realEvents: await count(sql`SELECT COUNT(*)::text AS n FROM events WHERE fixture_key IS NULL`),
  eventAlerts: await count(sql`SELECT COUNT(*)::text AS n FROM event_open_alerts`),
});

let world: World;
beforeAll(async () => {
  scratch = await createScratchDatabase();
  await bootServerSchema(scratch.url, "development");
  sql = postgres(scratch.url, { max: 2, onnotice: () => undefined });
  world = await buildWorld();
}, 60_000);

afterAll(async () => {
  await sql?.end({ timeout: 2 });
  await scratch?.drop();
});

describe("scripts/purge-seed-data.ts", () => {
  test("refuses to run without DATABASE_URL, and on a flag it does not know", async () => {
    const noDatabase = await runBun([SCRIPT], { DATABASE_URL: "" });
    expect(noDatabase.code).toBe(2);
    expect(noDatabase.out).toContain("DATABASE_URL");
    const unknown = await purge("--force");
    expect(unknown.code).toBe(2);
    expect((await counters()).seedUsers).toBe(20);
  });

  test("a dry-run (the default) lists the accounts and the catalogue and changes nothing", async () => {
    const before = await counters();
    expect(before).toMatchObject({ seedUsers: 20, realUsers: 3 });
    for (const flags of [[], ["--dry-run"]]) {
      const run = await purge(...flags);
      expect(run.code).toBe(0);
      expect(run.out).toContain("fake.female.1@mazl.seed");
      expect(run.out).toContain("fake.male.10@mazl.seed");
      expect(run.out.toLowerCase()).toContain("dry-run");
      // The catalogue rows a real couple uses are reported as kept, with the reason.
      expect(run.out).toContain(world.savedByRealCouple);
      expect(run.out).toContain(world.registeredByRealCouple);
      expect(run.out).toContain("test-event-purge (Dîner de Shabbat des tests)");
      expect(await counters()).toEqual(before);
    }
  }, 30_000);

  test("--apply is atomic: a failure on one account leaves every account and the catalogue in place", async () => {
    const before = await counters();
    await sql`
      CREATE FUNCTION refuse_last_seed() RETURNS trigger AS $$
      BEGIN IF OLD.email = 'fake.male.10@mazl.seed' THEN RAISE EXCEPTION 'refused for the test'; END IF; RETURN OLD; END $$ LANGUAGE plpgsql`;
    await sql`CREATE TRIGGER refuse_last_seed BEFORE DELETE ON users FOR EACH ROW EXECUTE FUNCTION refuse_last_seed()`;
    try {
      const run = await purge("--apply");
      expect(run.code).not.toBe(0);
      expect(await counters()).toEqual(before);
    } finally {
      await sql`DROP TRIGGER refuse_last_seed ON users`;
      await sql`DROP FUNCTION refuse_last_seed()`;
    }
  }, 30_000);

  test("--apply removes the seed members with everything attached, and only the unused sample catalogue", async () => {
    const run = await purge("--apply");
    expect([run.code, run.code === 0 ? "" : run.out]).toEqual([0, ""]);

    expect(await counters()).toEqual({
      seedUsers: 0,
      realUsers: 3,
      activities: 2,
      events: 1,
      messages: 0,
      testEvents: 0,
      realEvents: 1,
      eventAlerts: 0,
    });
    // Of the whole sample catalogue only what a real couple uses stays, next to the partner's own entry.
    expect((await sql<{ title: string }[]>`SELECT title FROM couple_activities ORDER BY title`).map((row) => row.title)).toEqual([world.savedByRealCouple, "Atelier du quartier"].sort());
    expect((await sql<{ title: string }[]>`SELECT title FROM couple_events`).map((row) => row.title)).toEqual([world.registeredByRealCouple]);
    // What hung on the seed member is gone, the real member is intact.
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM matches WHERE ${world.seedWithRealMatch} IN (user1_id, user2_id)`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM conversations`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM swipes WHERE ${world.realA} IN (user_id, target_user_id)`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM profile_photos`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM profiles WHERE user_id IN (${world.realA}, ${world.realB}, ${world.realC})`)).toBe(3);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couples WHERE ${world.realB} IN (user1_id, user2_id)`)).toBe(1);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_saved_activities`)).toBe(1);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM couple_event_registrations`)).toBe(1);
    expect(run.out).toContain(world.savedByRealCouple);
  }, 30_000);

  test("running it again finds nothing to do", async () => {
    const before = await counters();
    const run = await purge("--apply");
    expect(run.code).toBe(0);
    expect(await counters()).toEqual(before);
  }, 30_000);
});
