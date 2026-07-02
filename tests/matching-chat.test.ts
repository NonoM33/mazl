import { test, expect, describe, beforeAll } from "bun:test";

// Integration test: reciprocal swipe creates a match + conversation, and
// conversation messages are protected against non-members.
// Requires a running server (TEST_API_URL) with Postgres and dev endpoints on.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface TestUser { id: number; token: string }
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });

async function makeUser(label: string): Promise<TestUser> {
  const email = `mc-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: label }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}
const swipe = (t: string, target: number, action = "like") =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(t), body: JSON.stringify({ target_user_id: target, action }) });

describe("Matching & chat access control", () => {
  let a: TestUser, b: TestUser, c: TestUser;
  beforeAll(async () => { a = await makeUser("a"); b = await makeUser("b"); c = await makeUser("c"); });

  test("reciprocal like creates a match", async () => {
    await swipe(a.token, b.id);
    const r = await swipe(b.token, a.id);
    expect(r.status).toBe(200);
    const body = (await r.json()) as { match?: boolean; isMatch?: boolean };
    expect(body.match ?? body.isMatch).toBe(true);
  });

  test("conversation messages are readable by members, blocked for others", async () => {
    // A's conversation with B now exists
    let r = await fetch(`${BASE_URL}/api/conversations`, { headers: H(a.token) });
    expect(r.status).toBe(200);
    const conv = (await r.json()) as { conversations?: Array<{ id: number }> };
    expect(conv.conversations?.length ?? 0).toBeGreaterThan(0);
    const convId = conv.conversations![0]!.id;

    // member A can read
    r = await fetch(`${BASE_URL}/api/conversations/${convId}/messages`, { headers: H(a.token) });
    expect(r.status).toBe(200);

    // member A can post
    r = await fetch(`${BASE_URL}/api/conversations/${convId}/messages`, {
      method: "POST", headers: H(a.token), body: JSON.stringify({ content: "hi" }),
    });
    expect([200, 201]).toContain(r.status);

    // non-member C cannot read
    r = await fetch(`${BASE_URL}/api/conversations/${convId}/messages`, { headers: H(c.token) });
    expect([403, 404]).toContain(r.status);

    // non-member C cannot post
    r = await fetch(`${BASE_URL}/api/conversations/${convId}/messages`, {
      method: "POST", headers: H(c.token), body: JSON.stringify({ content: "intrusion" }),
    });
    expect([403, 404]).toContain(r.status);
  });
});
