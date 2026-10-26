import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { createScratchDatabase, startServer, type RunningServer, type ScratchDatabase } from "./support/scratch-database";

// The hosting has no shell: on staging and production the test profiles are written
// by the API itself at start-up, when SEED_TEST_PROFILES=true (src/db.ts).

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
    expect(await countSeedMembersWithPhotos(withFlag.url)).toBe(16);
  });

  test("without the flag: no test member gets the stock photos", async () => {
    expect(await countSeedMembersWithPhotos(withoutFlag.url)).toBe(0);
  });
});
