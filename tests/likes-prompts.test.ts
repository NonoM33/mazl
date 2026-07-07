import { test, expect, describe, beforeAll } from "bun:test";

// Integration test for "received likes" and profile prompts.
// Requires a running server (TEST_API_URL) with Postgres and dev endpoints on.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface TestUser { id: number; token: string }

async function makeUser(label: string): Promise<TestUser> {
  const email = `lp-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: `LP ${label}` }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });

describe("Received likes", () => {
  let a: TestUser, b: TestUser;
  beforeAll(async () => { a = await makeUser("a"); b = await makeUser("b"); });

  test("a liker apparaît, puis disparaît après match", async () => {
    let r = await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(b.token), body: JSON.stringify({ target_user_id: a.id, action: "like" }) });
    expect(r.status).toBe(200);

    r = await fetch(`${BASE_URL}/api/likes/received`, { headers: H(a.token) });
    expect(r.status).toBe(200);
    const likes = (await r.json()) as { likes?: Array<{ user_id: number }> };
    expect(likes.likes?.some((u) => u.user_id === b.id)).toBe(true);

    r = await fetch(`${BASE_URL}/api/likes/received/count`, { headers: H(a.token) });
    const c = (await r.json()) as { count: number };
    expect(c.count).toBeGreaterThanOrEqual(1);

    // reciprocal like → match → B should leave A's received likes
    await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(a.token), body: JSON.stringify({ target_user_id: b.id, action: "like" }) });
    r = await fetch(`${BASE_URL}/api/likes/received`, { headers: H(a.token) });
    const likes2 = (await r.json()) as { likes?: Array<{ user_id: number }> };
    expect(likes2.likes?.some((u) => u.user_id === b.id) ?? false).toBe(false);
  });
});

describe("Profile prompts", () => {
  let user: TestUser;
  let catalog: Array<{ id: string }>;
  beforeAll(async () => {
    user = await makeUser("prompts");
    const r = await fetch(`${BASE_URL}/api/prompts`);
    catalog = ((await r.json()) as { prompts?: Array<{ id: string }> }).prompts ?? [];
  });

  test("catalogue non vide", () => { expect(catalog.length).toBeGreaterThan(0); });

  test("CRUD + limite de 3", async () => {
    const add = (pid: string, ans: string, pos: number) =>
      fetch(`${BASE_URL}/api/profile/prompts`, { method: "POST", headers: H(user.token), body: JSON.stringify({ prompt_id: pid, answer: ans, position: pos }) });

    for (let i = 0; i < 3; i++) {
      const r = await add(catalog[i]!.id, `answer ${i}`, i);
      expect([200, 201]).toContain(r.status);
    }
    const over = await add(catalog[3]!.id, "answer 4", 3);
    expect(over.status).toBe(400);

    let r = await fetch(`${BASE_URL}/api/profile/prompts`, { headers: H(user.token) });
    expect(r.status).toBe(200);
    const mine = (await r.json()) as { prompts?: Array<{ id: number }> };
    expect(mine.prompts?.length).toBe(3);

    const firstId = mine.prompts![0]!.id;
    r = await fetch(`${BASE_URL}/api/profile/prompts/${firstId}`, { method: "PUT", headers: H(user.token), body: JSON.stringify({ answer: "updated" }) });
    expect(r.status).toBe(200);
    r = await fetch(`${BASE_URL}/api/profile/prompts/${firstId}`, { method: "DELETE", headers: H(user.token) });
    expect(r.status).toBe(200);

    r = await fetch(`${BASE_URL}/api/profile/prompts`, { headers: H(user.token) });
    const after = (await r.json()) as { prompts?: unknown[] };
    expect(after.prompts?.length).toBe(2);
  });
});
