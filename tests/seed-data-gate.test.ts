import { afterAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { bootSchema, createScratchDatabase, type ScratchDatabase } from "./support/scratch-database";

// Twenty fake members (provider 'seed', verified, complete, with photos) and a
// fictitious couple catalogue used to be created at EVERY start, production
// included: real members swiped on people who do not exist. The sample data now
// exists only when NODE_ENV is development or test, the same rule as /api/dev/*.

let scratch: ScratchDatabase | null = null;

async function counts(url: string): Promise<{ seedUsers: number; activities: number; events: number }> {
  const sql = postgres(url, { max: 1, onnotice: () => undefined });
  try {
    const [row] = await sql<{ seed_users: string; activities: string; events: string }[]>`
      SELECT (SELECT COUNT(*) FROM users WHERE provider = 'seed')::text AS seed_users,
             (SELECT COUNT(*) FROM couple_activities)::text AS activities,
             (SELECT COUNT(*) FROM couple_events)::text AS events`;
    if (row === undefined) throw new Error("no counts");
    return { seedUsers: Number(row.seed_users), activities: Number(row.activities), events: Number(row.events) };
  } finally {
    await sql.end({ timeout: 2 });
  }
}

async function bootedUnder(nodeEnv: string | undefined) {
  scratch = await createScratchDatabase();
  const booted = await bootSchema(scratch.url, nodeEnv ?? "");
  expect([booted.code, booted.code === 0 ? "" : booted.out]).toEqual([0, ""]);
  return counts(scratch.url);
}

afterAll(async () => {
  await scratch?.drop();
});

describe("sample data at start-up", () => {
  for (const nodeEnv of ["production", "staging", ""]) {
    test(`NODE_ENV=${nodeEnv === "" ? "(empty)" : nodeEnv}: an empty database stays empty of seed members and fictitious activities`, async () => {
      expect(await bootedUnder(nodeEnv)).toEqual({ seedUsers: 0, activities: 0, events: 0 });
      await scratch?.drop();
      scratch = null;
    }, 60_000);
  }

  for (const nodeEnv of ["development", "test"]) {
    test(`NODE_ENV=${nodeEnv}: the sample data is created`, async () => {
      const found = await bootedUnder(nodeEnv);
      expect(found.seedUsers).toBe(20);
      expect(found.activities).toBeGreaterThan(0);
      expect(found.events).toBeGreaterThan(0);
      await scratch?.drop();
      scratch = null;
    }, 60_000);
  }
});
