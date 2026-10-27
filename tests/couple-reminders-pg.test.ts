import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres, { type Sql } from "postgres";
import { PgReminderStore } from "../src/features/couple/infra/pg-reminder-store";
import { PgRituals, seedDefaultRituals } from "../src/features/couple/infra/pg-rituals";
import { bootSchema, createScratchDatabase, type ScratchDatabase } from "./support/scratch-database";

// The Postgres side of the reminders: who is reminded (a live MAZL Couple
// subscription among the two members), the place of the member who made the
// couple, the dedupe table, and the default rituals given once.

let scratch: ScratchDatabase;
let sql: Sql;

async function user(email: string): Promise<number> {
  const [row] = await sql<{ id: number }[]>`INSERT INTO users (email, name, provider, provider_id) VALUES (${email}, ${email}, 'test', ${email}) RETURNING id`;
  return (row as { id: number }).id;
}
async function couple(a: number, b: number): Promise<number> {
  const [low, high] = a < b ? [a, b] : [b, a];
  const [row] = await sql<{ id: number }[]>`INSERT INTO couples (user1_id, user2_id, started_at) VALUES (${low}, ${high}, CURRENT_DATE) RETURNING id`;
  return (row as { id: number }).id;
}
async function plan(userId: number, planType: string, expires: string): Promise<void> {
  await sql`INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
    VALUES (${userId}, ${planType}, 'active', 'apple', 'p', ${`tx-${userId}`}, NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + ${expires}::interval)`;
}

beforeAll(async () => {
  scratch = await createScratchDatabase();
  const booted = await bootSchema(scratch.url, "test");
  if (booted.code !== 0) throw new Error(booted.out);
  sql = postgres(scratch.url, { max: 2, onnotice: () => undefined });
}, 60_000);

afterAll(async () => {
  await sql?.end({ timeout: 2 });
  await scratch?.drop();
});

describe("who is reminded", () => {
  test("only couples where one member has a live MAZL Couple subscription", async () => {
    const [a1, b1, a2, b2, a3, b3, a4, b4] = await Promise.all(["a1", "b1", "a2", "b2", "a3", "b3", "a4", "b4"].map((n) => user(`rem-${n}@example.com`)));
    const paying = await couple(a1 as number, b1 as number);
    const plusOnly = await couple(a2 as number, b2 as number);
    const expired = await couple(a3 as number, b3 as number);
    const none = await couple(a4 as number, b4 as number);
    await plan(b1 as number, "couple_monthly", "30 days");
    await plan(a2 as number, "monthly", "30 days");
    await plan(a3 as number, "couple_monthly", "-1 hour");

    const ids = (await new PgReminderStore(sql).couplesWithPremium()).map((c) => c.id);
    expect(ids).toContain(paying);
    for (const excluded of [plusOnly, expired, none]) expect(ids).not.toContain(excluded);
    expect([...((await new PgReminderStore(sql).couplesWithPremium()).find((c) => c.id === paying)?.memberIds ?? [])]).toEqual([a1 as number, b1 as number].sort((x, y) => x - y));
  });

  test("an ended couple is no longer reminded", async () => {
    const a = await user("rem-end-a@example.com");
    const b = await user("rem-end-b@example.com");
    const id = await couple(a, b);
    await plan(a, "couple_monthly", "30 days");
    expect((await new PgReminderStore(sql).couplesWithPremium()).map((c) => c.id)).toContain(id);
    await sql`UPDATE couples SET status = 'ended' WHERE id = ${id}`;
    expect((await new PgReminderStore(sql).couplesWithPremium()).map((c) => c.id)).not.toContain(id);
  });

  test("the place is the one of the member who asked for the couple, else none", async () => {
    const asker = await user("rem-place-a@example.com");
    const accepter = await user("rem-place-b@example.com");
    const id = await couple(asker, accepter);
    await plan(accepter, "couple_monthly", "30 days");
    await sql`INSERT INTO profiles (user_id, display_name, latitude, longitude) VALUES (${asker}, 'Asker', 31.7683, 35.2137), (${accepter}, 'Accepter', 45.76, 4.83)`;
    await sql`INSERT INTO couple_requests (requester_id, target_id, status) VALUES (${asker}, ${accepter}, 'accepted')`;
    const found = (await new PgReminderStore(sql).couplesWithPremium()).find((c) => c.id === id);
    expect([found?.latitude, found?.longitude]).toEqual([31.7683, 35.2137]);
  });
});

describe("never twice", () => {
  test("the first claim wins, the same reminder is refused, another occurrence is new", async () => {
    const a = await user("rem-claim-a@example.com");
    const b = await user("rem-claim-b@example.com");
    const id = await couple(a, b);
    const store = new PgReminderStore(sql);
    const eve = { source: "date", refId: 4, occurrence: "2026-11-05:eve", daysAway: 1 } as const;
    expect(await store.claim(id, eve)).toBe(true);
    expect(await store.claim(id, eve)).toBe(false);
    expect(await store.claim(id, { ...eve, occurrence: "2027-11-05:eve" })).toBe(true);
    expect(await store.claim(id, { source: "ritual", refId: 4, occurrence: "2026-11-05", kind: "weekly", startsAt: new Date() })).toBe(true);
    const racing = await Promise.all(Array.from({ length: 8 }, () => store.claim(id, { ...eve, refId: 99 })));
    expect(racing.filter(Boolean)).toHaveLength(1);
  });
});

describe("default rituals", () => {
  test("given once to a couple, however many times it is asked, and not given back after deletion", async () => {
    const a = await user("rem-rit-a@example.com");
    const b = await user("rem-rit-b@example.com");
    const id = await couple(a, b);
    await seedDefaultRituals(sql, id);
    await seedDefaultRituals(sql, id);
    const rituals = new PgRituals(sql);
    expect((await rituals.list(id)).map((r) => [r.kind, r.enabled])).toEqual([["shabbat", true], ["weekly", false], ["weekly", false]]);
    for (const ritual of await rituals.list(id)) await rituals.remove(id, ritual.id);
    await seedDefaultRituals(sql, id);
    expect(await rituals.list(id)).toEqual([]);
  });

  test("the boot migration gives them to couples that already existed", async () => {
    const a = await user("rem-mig-a@example.com");
    const b = await user("rem-mig-b@example.com");
    const id = await couple(a, b);
    expect(await new PgRituals(sql).list(id)).toEqual([]);
    const { ensureCoupleSpaceSchema } = await import("../src/features/couple/infra/schema");
    await ensureCoupleSpaceSchema(sql);
    expect((await new PgRituals(sql).list(id)).map((r) => r.title)).toEqual(["Shabbat ensemble", "Soirée sans écran", "Appeler les parents"]);
    await ensureCoupleSpaceSchema(sql); // idempotent
    expect(await new PgRituals(sql).list(id)).toHaveLength(3);
  });
});
