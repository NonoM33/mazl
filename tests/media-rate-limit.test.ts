import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, makeUser, type TestUser } from "./media-helpers";

// Integration tests of CONTRAT.md §2.3 (anti-scraping). Needs a running server.
// Each test uses fresh users: the limiter is per user and lives in memory.

interface Limited { success: boolean; error: string; retry_after: number }

async function expectBlocked(res: Response): Promise<void> {
  expect(res.status).toBe(429);
  const body = (await res.json()) as Limited;
  expect(body.success).toBe(false);
  expect(body.error).toBe("rate_limited");
  expect(body.retry_after).toBeGreaterThan(0);
  expect(body.retry_after).toBeLessThanOrEqual(3600);
}

describe("profile views: 120 per hour", () => {
  let viewer: TestUser;
  let target: TestUser;
  beforeAll(async () => { viewer = await makeUser("rlview"); target = await makeUser("rltarget"); });

  test("the 121st view is a 429, another user is unaffected", async () => {
    for (let i = 0; i < 120; i++) {
      const res = await fetch(`${BASE_URL}/api/profile/${target.id}`, { headers: auth(viewer.token) });
      expect(res.status).toBe(200);
    }
    await expectBlocked(await fetch(`${BASE_URL}/api/profile/${target.id}`, { headers: auth(viewer.token) }));

    const bystander = await makeUser("rlbystander");
    expect((await fetch(`${BASE_URL}/api/profile/${target.id}`, { headers: auth(bystander.token) })).status).toBe(200);
  });

  test("other profile routes are not counted against the budget", async () => {
    const user = await makeUser("rlother");
    for (let i = 0; i < 125; i++) {
      const res = await fetch(`${BASE_URL}/api/profile/photos`, { headers: auth(user.token) });
      expect(res.status).toBe(200);
    }
  });
});

describe("discover and daily picks: 300 per hour", () => {
  test("the 301st feed request is a 429; daily picks share the budget", async () => {
    const user = await makeUser("rlfeed");
    for (let i = 0; i < 300; i++) {
      const res = await fetch(`${BASE_URL}/api/discover`, { headers: auth(user.token) });
      expect(res.status).toBe(200);
    }
    await expectBlocked(await fetch(`${BASE_URL}/api/discover`, { headers: auth(user.token) }));
    await expectBlocked(await fetch(`${BASE_URL}/api/daily-picks`, { headers: auth(user.token) }));
  });

  test("an unauthenticated request is a 401, not counted", async () => {
    expect((await fetch(`${BASE_URL}/api/discover`)).status).toBe(401);
  });
});
