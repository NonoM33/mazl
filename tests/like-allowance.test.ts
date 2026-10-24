import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Integration: the 10-likes-a-day cap held by the server (docs/web/adr/W07).
// Needs TEST_API_URL and TEST_DATABASE_URL.

const swipe = (member: TestUser, target: number, action: "like" | "pass") =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(member.token), body: JSON.stringify({ target_user_id: target, action }) });

async function makeTargets(label: string, count: number): Promise<TestUser[]> {
  return await Promise.all(Array.from({ length: count }, (_, index) => makeUser(`${label}${index}`)));
}

interface Allowance { daily_allowance: number | null; remaining: number | null; resets_at: string }
const readAllowance = async (member: TestUser): Promise<Allowance> =>
  ((await (await fetch(`${BASE_URL}/api/likes/allowance`, { headers: auth(member.token) })).json()) as { allowance: Allowance }).allowance;

describe("like allowance", () => {
  test("a free member's 11th like is refused with 402 likes_exhausted, a pass and a re-like are not", async () => {
    const member = await makeUser("likes-free");
    const targets = await makeTargets("likes-free-t", 12);
    for (const target of targets.slice(0, 10)) expect((await swipe(member, target.id, "like")).status).toBe(200);

    const eleventh = await swipe(member, targets[10]!.id, "like");
    expect(eleventh.status).toBe(402);
    const body = (await eleventh.json()) as { success: boolean; error: string; allowance: Allowance };
    expect(body.success).toBe(false);
    expect(body.error).toBe("likes_exhausted");
    expect(body.allowance.daily_allowance).toBe(10);
    expect(body.allowance.remaining).toBe(0);
    expect(new Date(body.allowance.resets_at).getTime()).toBeGreaterThan(Date.now());
    expect(await db`SELECT 1 FROM swipes WHERE user_id = ${member.id} AND target_user_id = ${targets[10]!.id}`).toHaveLength(0);

    expect((await swipe(member, targets[11]!.id, "pass")).status).toBe(200);
    expect((await swipe(member, targets[0]!.id, "like")).status).toBe(200);
    expect(await readAllowance(member)).toMatchObject({ daily_allowance: 10, remaining: 0 });
  });

  test("the allowance goes down with each like", async () => {
    const member = await makeUser("likes-count");
    expect(await readAllowance(member)).toMatchObject({ daily_allowance: 10, remaining: 10 });
    const [target] = await makeTargets("likes-count-t", 1);
    await swipe(member, target!.id, "like");
    expect(await readAllowance(member)).toMatchObject({ remaining: 9 });
  });

  test("a mazl+ member passes the 11th like and has no cap", async () => {
    const member = await makeUser("likes-plus");
    await db`
      INSERT INTO subscriptions (user_id, plan_type, status, started_at, expires_at)
      VALUES (${member.id}, 'monthly', 'active', NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days')
    `;
    const targets = await makeTargets("likes-plus-t", 11);
    for (const target of targets) expect((await swipe(member, target.id, "like")).status).toBe(200);
    expect(await readAllowance(member)).toMatchObject({ daily_allowance: null, remaining: null });
  });

  test("the allowance route and the swipe route require authentication", async () => {
    expect((await fetch(`${BASE_URL}/api/likes/allowance`)).status).toBe(401);
    expect((await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" })).status).toBe(401);
  });

  test("a body the guard cannot read is still answered by the swipe handler", async () => {
    const member = await makeUser("likes-bad");
    const response = await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(member.token), body: "{broken" });
    expect(response.status).toBe(400);
  });
});

describe("the cap cannot be got round (security review M3)", () => {
  test("passing on someone already liked does not give a like back", async () => {
    const member = await makeUser("likes-pass-back");
    const targets = await makeTargets("likes-pass-back-t", 11);
    for (const target of targets.slice(0, 10)) expect((await swipe(member, target.id, "like")).status).toBe(200);
    // The swipe row of the first like becomes a pass: the day's likes stay ten.
    expect((await swipe(member, targets[0]!.id, "pass")).status).toBe(200);
    expect((await swipe(member, targets[10]!.id, "like")).status).toBe(402);
    expect(await readAllowance(member)).toMatchObject({ remaining: 0 });
  });

  test("fifteen likes sent at the same time: exactly ten go through", async () => {
    const member = await makeUser("likes-race");
    const targets = await makeTargets("likes-race-t", 15);
    const statuses = await Promise.all(targets.map((target) => swipe(member, target.id, "like").then((res) => res.status)));
    expect(statuses.filter((status) => status === 200)).toHaveLength(10);
    expect(statuses.filter((status) => status === 402)).toHaveLength(5);
    expect(await db`SELECT 1 FROM swipes WHERE user_id = ${member.id} AND action = 'like'`).toHaveLength(10);
  });

  test("a like the server refuses for another reason does not use the day's allowance", async () => {
    const member = await makeUser("likes-refused");
    expect((await swipe(member, 2_000_000_000, "like")).status).toBe(404);
    expect(await readAllowance(member)).toMatchObject({ remaining: 10 });
  });
});
