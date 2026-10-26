import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { TEST_EVENTS } from "../src/features/fixtures/test-event-roster";
import { createScratchDatabase, startServer, type RunningServer, type ScratchDatabase } from "./support/scratch-database";

// The hosting has no shell: on staging and production the test profiles are written
// by the API itself at start-up, when SEED_TEST_PROFILES=true (src/db.ts), with the
// "coming soon" fake events.

const ADMIN_EMAIL = "boot-admin@example.com";

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
}

async function fixtureEvents(url: string): Promise<FixtureEventRow[]> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    return await sql<FixtureEventRow[]>`
      SELECT id, fixture_key, availability, is_published, date > CURRENT_DATE AS in_future, image_url
      FROM events WHERE fixture_key IS NOT NULL ORDER BY fixture_key`;
  } finally {
    await sql.end({ timeout: 2 });
  }
}

async function openOne(url: string, key: string): Promise<void> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    await sql`UPDATE events SET availability = 'open' WHERE fixture_key = ${key}`;
  } finally {
    await sql.end({ timeout: 2 });
  }
}

describe("test profiles at start-up", () => {
  let withFlag: ScratchDatabase;
  let withoutFlag: ScratchDatabase;
  let servers: RunningServer[] = [];

  beforeAll(async () => {
    withFlag = await createScratchDatabase();
    withoutFlag = await createScratchDatabase();
    process.env.ADMIN_EMAIL = ADMIN_EMAIL;
    process.env.SEED_TEST_PROFILES = "true";
    servers.push(await startServer(withFlag.url, "test"));
    delete process.env.SEED_TEST_PROFILES;
    servers.push(await startServer(withoutFlag.url, "test"));
  }, 120_000);

  afterAll(async () => {
    for (const server of servers) await server.stop();
    servers = [];
    await withFlag.drop();
    await withoutFlag.drop();
  });

  test("SEED_TEST_PROFILES=true: the API writes the test members, with their photos", async () => {
    expect(await countSeedMembersWithPhotos(withFlag.url)).toBe(25);
  });

  test("without the flag: no test member gets the stock photos", async () => {
    expect(await countSeedMembersWithPhotos(withoutFlag.url)).toBe(0);
  });

  test("SEED_TEST_PROFILES=true: the API writes the fake events, published, coming soon, in the future, without picture", async () => {
    const rows = await fixtureEvents(withFlag.url);
    expect(rows.map((row) => row.fixture_key)).toEqual(TEST_EVENTS.map((event) => event.key).sort());
    expect(rows.every((row) => row.availability === "coming_soon" && row.is_published && row.in_future && row.image_url === null)).toBe(true);
    expect(await fixtureEvents(withoutFlag.url)).toEqual([]);
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
    expect(after).toEqual(before);
    expect(after.find((row) => row.fixture_key === key)?.availability).toBe("open");
  }, 60_000);
});
