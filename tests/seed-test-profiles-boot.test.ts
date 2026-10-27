import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { TEST_EVENTS } from "../src/features/fixtures/test-event-roster";
import { createScratchDatabase, startServer, type RunningServer, type ScratchDatabase } from "./support/scratch-database";

// The hosting has no shell: on staging and production the test profiles are written
// by the API itself at start-up, when SEED_TEST_PROFILES=true (src/db.ts), with the
// "coming soon" fake events.

const ADMIN_EMAIL = "boot-admin@example.com";
const REVIEW_USERNAME = "relecteur-boot";

// The App Store review account (provider 'review') and what the seed gave it.
async function reviewAccount(url: string): Promise<{ profiles: number; matches: number; messages: number } | null> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    const [row] = await sql<{ id: number; profiles: string; matches: string; messages: string }[]>`
      SELECT u.id,
        (SELECT COUNT(*) FROM profiles p WHERE p.user_id = u.id AND p.is_complete)::text AS profiles,
        (SELECT COUNT(*) FROM matches m WHERE u.id IN (m.user1_id, m.user2_id))::text AS matches,
        (SELECT COUNT(*) FROM messages x JOIN conversations c ON c.id = x.conversation_id WHERE u.id IN (c.user1_id, c.user2_id))::text AS messages
      FROM users u WHERE u.provider = 'review' AND u.provider_id = ${REVIEW_USERNAME}`;
    return row === undefined ? null : { profiles: Number(row.profiles), matches: Number(row.matches), messages: Number(row.messages) };
  } finally {
    await sql.end({ timeout: 2 });
  }
}

async function countSeedMembersWithPhotos(url: string): Promise<number> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    const [row] = await sql<{ n: string }[]>`
      SELECT COUNT(DISTINCT u.id) AS n FROM users u
      JOIN profile_photos p ON p.user_id = u.id
      WHERE u.provider = 'seed' AND u.is_active = true AND p.url LIKE 'https://images.unsplash.com/%'`;
    return Number(row?.n ?? 0);
  } finally {
    await sql.end({ timeout: 2 });
  }
}

interface FixtureEventRow {
  id: number;
  fixture_key: string;
  availability: string;
  is_published: boolean;
  in_future: boolean;
  image_url: string | null;
  latitude: string | null;
  longitude: string | null;
  date: string;
}

async function fixtureEvents(url: string): Promise<FixtureEventRow[]> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    return await sql<FixtureEventRow[]>`
      SELECT id, fixture_key, availability, is_published, date > CURRENT_DATE AS in_future, image_url, latitude, longitude, to_char(date, 'YYYY-MM-DD') AS date
      FROM events WHERE fixture_key IS NOT NULL ORDER BY fixture_key`;
  } finally {
    await sql.end({ timeout: 2 });
  }
}

async function openOne(url: string, key: string): Promise<void> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    await sql`UPDATE events SET availability = 'open' WHERE fixture_key = ${key}`;
    // A feast written on a wrong date by an earlier seed (2026-12-13, after Hanukkah).
    await sql`UPDATE events SET date = '2026-12-13' WHERE fixture_key = 'test-event-hanukkah-paris'`;
  } finally {
    await sql.end({ timeout: 2 });
  }
}

describe("test profiles at start-up", () => {
  let withFlag: ScratchDatabase;
  let withoutFlag: ScratchDatabase;
  let servers: RunningServer[] = [];
  // The test files share one process: the administrator of these servers must
  // not leak into the files that run after this one (their admin sign-in then
  // failed with 401, 2026-10-27).
  const previousAdminEmail = process.env.ADMIN_EMAIL;

  beforeAll(async () => {
    withFlag = await createScratchDatabase();
    withoutFlag = await createScratchDatabase();
    process.env.ADMIN_EMAIL = ADMIN_EMAIL;
    process.env.SEED_TEST_PROFILES = "true";
    process.env.REVIEW_LOGIN_USERNAME = REVIEW_USERNAME;
    process.env.REVIEW_LOGIN_PASSWORD_HASH = await Bun.password.hash("exemple-motdepasse");
    servers.push(await startServer(withFlag.url, "test"));
    delete process.env.SEED_TEST_PROFILES;
    servers.push(await startServer(withoutFlag.url, "test"));
    delete process.env.REVIEW_LOGIN_USERNAME;
    delete process.env.REVIEW_LOGIN_PASSWORD_HASH;
  }, 120_000);

  afterAll(async () => {
    if (previousAdminEmail === undefined) delete process.env.ADMIN_EMAIL;
    else process.env.ADMIN_EMAIL = previousAdminEmail;
    for (const server of servers) await server.stop();
    servers = [];
    await withFlag.drop();
    await withoutFlag.drop();
  });

  test("SEED_TEST_PROFILES=true: the API writes the test members, with their photos", async () => {
    expect(await countSeedMembersWithPhotos(withFlag.url)).toBe(25);
  });

  test("SEED_TEST_PROFILES=true: the App Store review account exists with a complete profile, matches and conversations", async () => {
    const account = await reviewAccount(withFlag.url);
    expect(account?.profiles).toBe(1);
    expect(account?.matches ?? 0).toBeGreaterThan(0);
    expect(account?.messages ?? 0).toBeGreaterThan(0);
  });

  test("without the flag: the review account is only created at its first sign-in", async () => {
    expect(await reviewAccount(withoutFlag.url)).toBeNull();
  });

  test("without the flag: no test member gets the stock photos", async () => {
    expect(await countSeedMembersWithPhotos(withoutFlag.url)).toBe(0);
  });

  test("SEED_TEST_PROFILES=true: the API writes the fake events, published, coming soon, in the future, with their picture and place", async () => {
    const rows = await fixtureEvents(withFlag.url);
    expect(rows.map((row) => row.fixture_key)).toEqual(TEST_EVENTS.map((event) => event.key).sort());
    expect(rows.every((row) => row.availability === "coming_soon" && row.is_published && row.in_future)).toBe(true);
    for (const event of TEST_EVENTS) {
      const row = rows.find((candidate) => candidate.fixture_key === event.key);
      expect(row?.image_url).toBe(event.imageUrl);
      expect(Number(row?.latitude)).toBeCloseTo(event.latitude, 4);
      expect(Number(row?.longitude)).toBeCloseTo(event.longitude, 4);
    }
    expect(await fixtureEvents(withoutFlag.url)).toEqual([]);
  });

  test("the events list and the event detail serve the picture and the coordinates", async () => {
    const base = servers[0]?.baseUrl ?? "";
    const listed = (await (await fetch(`${base}/api/events?limit=50`)).json()) as { events: Array<Record<string, unknown>> };
    const rows = await fixtureEvents(withFlag.url);
    for (const event of TEST_EVENTS) {
      const id = rows.find((row) => row.fixture_key === event.key)?.id;
      const inList = listed.events.find((candidate) => candidate.id === id);
      const detail = ((await (await fetch(`${base}/api/events/${id}`)).json()) as { event: Record<string, unknown> }).event;
      for (const served of [inList, detail]) {
        expect(served?.image_url).toBe(event.imageUrl);
        expect(Number(served?.latitude)).toBeCloseTo(event.latitude, 4);
        expect(Number(served?.longitude)).toBeCloseTo(event.longitude, 4);
      }
    }
  });

  test("a restart writes nothing twice and keeps an event an administrator opened", async () => {
    const key = TEST_EVENTS[0]?.key ?? "";
    await openOne(withFlag.url, key);
    const before = await fixtureEvents(withFlag.url);
    await servers[0]?.stop();
    process.env.SEED_TEST_PROFILES = "true";
    servers[0] = await startServer(withFlag.url, "test");
    delete process.env.SEED_TEST_PROFILES;
    const after = await fixtureEvents(withFlag.url);
    const feast = (rows: FixtureEventRow[]) => rows.find((row) => row.fixture_key === "test-event-hanukkah-paris");
    // Until Hanukkah 2026, a restart puts the feast back on its own date.
    if (new Date().toISOString().slice(0, 10) < "2026-12-06") expect(feast(after)?.date).toBe("2026-12-06");
    const others = (rows: FixtureEventRow[]) => rows.filter((row) => row !== feast(rows));
    expect(others(after)).toEqual(others(before));
    expect(after.find((row) => row.fixture_key === key)?.availability).toBe("open");
  }, 60_000);
});
