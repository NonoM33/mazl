import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";
import { connect, expectNone } from "./chat-helpers";

// Attack scenarios against discover, swipes, likes, reports and blocks. Needs a
// running server (TEST_API_URL) and its database (TEST_DATABASE_URL).

async function discoverable(user: TestUser): Promise<TestUser> {
  await db`
    UPDATE profiles
    SET is_complete = true, display_name = ${`Membre ${user.id}`}, birthdate = '1995-04-12', gender = 'female'
    WHERE user_id = ${user.id}
  `;
  return user;
}

const get = (user: TestUser, path: string) => fetch(`${BASE_URL}${path}`, { headers: auth(user.token) });
const swipe = (user: TestUser, body: unknown) =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });
const like = (user: TestUser, target: number) => swipe(user, { target_user_id: target, action: "like" });
const block = (blocker: TestUser, blockedId: number) =>
  fetch(`${BASE_URL}/api/users/${blockedId}/block`, { method: "POST", headers: json(blocker.token) });

const idsOf = async (res: Response, key: string): Promise<number[]> => {
  const body = (await res.json()) as Record<string, Array<{ user_id: number }>>;
  return (body[key] ?? []).map((p) => p.user_id);
};

const count = async (query: Promise<Array<{ n: string }>>): Promise<number> => Number((await query)[0]?.n);

// ---------------------------------------------------------------------------
// Discover: the page size is the server's decision

describe("GET /api/discover bounds limit and offset", () => {
  const tag = `${Date.now()}`;
  let viewer: TestUser;

  beforeAll(async () => {
    viewer = await makeUser("dis-viewer");
    await db`
      INSERT INTO users (email, name, provider, provider_id)
      SELECT 'bulk-' || g || '-${db.unsafe(tag)}@example.test', 'Bulk ' || g, 'test', 'bulk-' || g || '-${db.unsafe(tag)}'
      FROM generate_series(1, 60) g
    `;
    await db`
      INSERT INTO profiles (user_id, display_name, birthdate, gender, is_complete)
      SELECT id, name, '1995-04-12', 'female', true FROM users WHERE email LIKE ${`bulk-%-${tag}@example.test`}
    `;
  });

  afterAll(async () => {
    await db`DELETE FROM users WHERE email LIKE ${`bulk-%-${tag}@example.test`}`;
  });

  test("limit=100000 cannot pull the whole member base", async () => {
    const res = await get(viewer, "/api/discover?limit=100000");
    expect(res.status).toBe(200);
    expect((await idsOf(res, "profiles")).length).toBe(50);
  });

  test.each([
    ["negative", "limit=-5"],
    ["not a number", "limit=abc"],
    ["zero", "limit=0"],
    ["fractional", "limit=2.5"],
    ["negative offset", "limit=10&offset=-3"],
    ["offset not a number", "limit=10&offset=NaN"],
  ])("a %s value falls back to a default instead of a 500", async (_label, query) => {
    const res = await get(viewer, `/api/discover?${query}`);
    expect(res.status).toBe(200);
    const ids = await idsOf(res, "profiles");
    expect(ids.length).toBeGreaterThan(0);
    expect(ids.length).toBeLessThanOrEqual(50);
  });

  test("a regular page and its offset still work", async () => {
    const first = await idsOf(await get(viewer, "/api/discover?limit=10&offset=0"), "profiles");
    const second = await idsOf(await get(viewer, "/api/discover?limit=10&offset=10"), "profiles");
    expect(first).toHaveLength(10);
    expect(second).toHaveLength(10);
    expect(first.filter((id) => second.includes(id))).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// Feeds exclude closed accounts and blocks, in both directions

describe("feeds never show a deactivated or blocked member", () => {
  test("discover and daily picks drop an account the moment it is deactivated", async () => {
    const viewer = await makeUser("feed-viewer");
    const target = await discoverable(await makeUser("feed-target"));
    const feed = await idsOf(await get(viewer, "/api/discover?limit=50"), "profiles");
    expect(feed).toContain(target.id);
    // The feed is ranked by the matching engine: daily picks are its first five,
    // whoever they are, so the target is eligible for both before deactivation.
    expect(await idsOf(await get(viewer, "/api/daily-picks"), "picks")).toEqual(feed.slice(0, 5));

    await db`UPDATE users SET is_active = false WHERE id = ${target.id}`;
    expect(await idsOf(await get(viewer, "/api/discover?limit=50"), "profiles")).not.toContain(target.id);
    expect(await idsOf(await get(viewer, "/api/daily-picks"), "picks")).not.toContain(target.id);
  });

  test("a member blocked by the viewer, or who blocked the viewer, is not in discover or daily picks", async () => {
    const viewer = await makeUser("feed-block-viewer");
    const blockedByMe = await discoverable(await makeUser("feed-blocked"));
    const blocker = await discoverable(await makeUser("feed-blocker"));
    await block(viewer, blockedByMe.id);
    await block(blocker, viewer.id);
    for (const [path, key] of [["/api/discover?limit=50", "profiles"], ["/api/daily-picks", "picks"]] as const) {
      const ids = await idsOf(await get(viewer, path), key);
      expect([path, ids.includes(blockedByMe.id), ids.includes(blocker.id)]).toEqual([path, false, false]);
    }
  });

  test("received likes and their counter ignore deactivated accounts and blocks", async () => {
    const me = await makeUser("likes-me");
    const banned = await makeUser("likes-banned");
    const blocked = await makeUser("likes-blocked");
    const fine = await makeUser("likes-fine");
    for (const admirer of [banned, blocked, fine]) expect((await like(admirer, me.id)).status).toBe(200);
    expect((await get(me, "/api/likes/received/count").then((r) => r.json())) as { count: number }).toMatchObject({ count: 3 });

    await db`UPDATE users SET is_active = false WHERE id = ${banned.id}`;
    await block(me, blocked.id);

    expect(await idsOf(await get(me, "/api/likes/received"), "likes")).toEqual([fine.id]);
    expect((await get(me, "/api/likes/received/count").then((r) => r.json())) as { count: number }).toMatchObject({ count: 1 });
  });
});

// ---------------------------------------------------------------------------
// Swipes

const matchCount = (a: number, b: number) =>
  count(db`SELECT COUNT(*) AS n FROM matches WHERE (user1_id = ${a} AND user2_id = ${b}) OR (user1_id = ${b} AND user2_id = ${a})`);

describe("POST /api/swipes", () => {
  test("swiping on yourself is a 400 and creates neither a match nor a conversation", async () => {
    const user = await makeUser("sw-self");
    const res = await like(user, user.id);
    expect(res.status).toBe(400);
    expect(await matchCount(user.id, user.id)).toBe(0);
    expect(await count(db`SELECT COUNT(*) AS n FROM conversations WHERE user1_id = ${user.id} AND user2_id = ${user.id}`)).toBe(0);
    expect(await count(db`SELECT COUNT(*) AS n FROM swipes WHERE user_id = ${user.id}`)).toBe(0);
  });

  test.each([
    ["zero", 0],
    ["negative", -4],
    ["fractional", 1.5],
    ["a numeric string", "7"],
    ["beyond the id range", 3_000_000_000],
  ])("a target id that is %s is a 400", async (_label, target) => {
    const user = await makeUser("sw-id");
    expect((await swipe(user, { target_user_id: target, action: "like" })).status).toBe(400);
  });

  test("an unknown, a deactivated and a blocking target all get the very same 404", async () => {
    const user = await makeUser("sw-oracle");
    const inactive = await makeUser("sw-inactive");
    const blocker = await makeUser("sw-blocker");
    const blockedByMe = await makeUser("sw-blocked");
    await db`UPDATE users SET is_active = false WHERE id = ${inactive.id}`;
    await block(blocker, user.id);
    await block(user, blockedByMe.id);

    const missing = await like(user, 2_000_000_000);
    expect(missing.status).toBe(404);
    const expected = await missing.text();
    for (const target of [inactive, blocker, blockedByMe]) {
      const res = await like(user, target.id);
      expect([target.id, res.status, await res.text()]).toEqual([target.id, 404, expected]);
      expect(await count(db`SELECT COUNT(*) AS n FROM swipes WHERE user_id = ${user.id} AND target_user_id = ${target.id}`)).toBe(0);
    }
  });

  test("a like toward someone who blocked you creates no match and pushes nothing to them", async () => {
    const admirer = await makeUser("sw-admirer");
    const blocker = await makeUser("sw-blocker-ws");
    expect((await like(blocker, admirer.id)).status).toBe(200);
    expect((await block(blocker, admirer.id)).status).toBe(200);

    const socket = await connect(blocker.token);
    try {
      expect((await swipe(admirer, { target_user_id: blocker.id, action: "super_like" })).status).toBe(404);
      expect(await matchCount(admirer.id, blocker.id)).toBe(0);
      expect(await expectNone(socket, "match:new")).toBe(true);
    } finally {
      socket.close();
    }
  });

  test("a super like on a blocked target spends no credit", async () => {
    const admirer = await makeUser("sw-credit");
    const blocker = await makeUser("sw-credit-blocker");
    await block(blocker, admirer.id);
    const before = await (await get(admirer, "/api/credits")).text();
    expect((await swipe(admirer, { target_user_id: blocker.id, action: "super_like" })).status).toBe(404);
    expect(await (await get(admirer, "/api/credits")).text()).toBe(before);
  });

  test("a normal reciprocal like still matches", async () => {
    const a = await makeUser("sw-ok-a");
    const b = await makeUser("sw-ok-b");
    expect((await like(a, b.id)).status).toBe(200);
    const res = await like(b, a.id);
    expect(res.status).toBe(200);
    expect(((await res.json()) as { match: boolean }).match).toBe(true);
    expect(await matchCount(a.id, b.id)).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// Reports and blocks

const reportUser = (user: TestUser, targetId: number | string, body: unknown) =>
  fetch(`${BASE_URL}/api/users/${targetId}/report`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });
const reportLegacy = (user: TestUser, body: unknown) =>
  fetch(`${BASE_URL}/api/report`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });
const reportCount = (reporterId: number) =>
  count(db`SELECT COUNT(*) AS n FROM reports WHERE reporter_id = ${reporterId}`);

describe("POST /api/users/:id/report", () => {
  test("a reason that is not one of the app's categories is a 400, not a database error", async () => {
    const reporter = await makeUser("rep-reason");
    const target = await makeUser("rep-reason-target");
    expect((await reportUser(reporter, target.id, { category: "x".repeat(300) })).status).toBe(400);
    expect((await reportUser(reporter, target.id, { category: "because I said so" })).status).toBe(400);
    expect(await reportCount(reporter.id)).toBe(0);
  });

  test("every category the app offers is accepted", async () => {
    const reporter = await makeUser("rep-cats");
    const target = await makeUser("rep-cats-target");
    for (const category of ["fake_profile", "inappropriate_photos", "harassment", "spam", "underage", "offline_behavior", "other"]) {
      expect([category, (await reportUser(reporter, target.id, { category, comment: "Détail" })).status]).toEqual([category, 200]);
    }
  });

  test("the comment is bounded", async () => {
    const reporter = await makeUser("rep-comment");
    const target = await makeUser("rep-comment-target");
    expect((await reportUser(reporter, target.id, { category: "spam", comment: "x".repeat(1001) })).status).toBe(400);
    expect((await reportUser(reporter, target.id, { category: "spam", comment: "x".repeat(1000) })).status).toBe(200);
  });

  test("reporting yourself is a 400 and stores nothing", async () => {
    const reporter = await makeUser("rep-self");
    expect((await reportUser(reporter, reporter.id, { category: "spam" })).status).toBe(400);
    expect(await reportCount(reporter.id)).toBe(0);
  });

  test("an unknown member is a 404, a malformed id a 400", async () => {
    const reporter = await makeUser("rep-unknown");
    expect((await reportUser(reporter, 2_000_000_000, { category: "spam" })).status).toBe(404);
    expect((await reportUser(reporter, "12abc", { category: "spam" })).status).toBe(400);
    expect((await reportUser(reporter, 3_000_000_000, { category: "spam" })).status).toBe(400);
    expect(await reportCount(reporter.id)).toBe(0);
  });

  test("a member cannot flood the moderators: 20 reports an hour", async () => {
    const reporter = await makeUser("rep-flood");
    const target = await makeUser("rep-flood-target");
    for (let i = 0; i < 20; i++) expect((await reportUser(reporter, target.id, { category: "spam" })).status).toBe(200);
    const blocked = await reportUser(reporter, target.id, { category: "spam" });
    expect(blocked.status).toBe(429);
    expect((await reportLegacy(reporter, { reportedUserId: target.id, reason: "spam" })).status).toBe(429);
    expect(await reportCount(reporter.id)).toBe(20);
  });
});

describe("POST /api/report (legacy body)", () => {
  test("validates the reason, the target and the details like the other route", async () => {
    const reporter = await makeUser("leg-rep");
    const target = await makeUser("leg-target");
    expect((await reportLegacy(reporter, { reportedUserId: target.id, reason: "x".repeat(300) })).status).toBe(400);
    expect((await reportLegacy(reporter, { reportedUserId: reporter.id, reason: "spam" })).status).toBe(400);
    expect((await reportLegacy(reporter, { reportedUserId: "abc", reason: "spam" })).status).toBe(400);
    expect((await reportLegacy(reporter, { reportedUserId: 2_000_000_000, reason: "spam" })).status).toBe(404);
    expect((await reportLegacy(reporter, { reportedUserId: target.id, reason: "spam", details: "x".repeat(1001) })).status).toBe(400);
    expect((await reportLegacy(reporter, "not an object")).status).toBe(400);
    expect(await reportCount(reporter.id)).toBe(0);
    expect((await reportLegacy(reporter, { reportedUserId: target.id, reason: "other", details: "regression" })).status).toBe(200);
  });
});

describe("blocking", () => {
  test("blocking an id that does not exist is a 404, not a 500", async () => {
    const user = await makeUser("blk-unknown");
    expect((await block(user, 2_000_000_000)).status).toBe(404);
    expect((await block(user, "12abc" as unknown as number)).status).toBe(400);
  });

  test("a report with block_user toward an unknown member blocks nothing and fails cleanly", async () => {
    const user = await makeUser("blk-report");
    const res = await reportUser(user, 2_000_000_000, { category: "spam", block_user: true });
    expect(res.status).toBe(404);
    expect(await count(db`SELECT COUNT(*) AS n FROM blocked_users WHERE blocker_id = ${user.id}`)).toBe(0);
  });
});
