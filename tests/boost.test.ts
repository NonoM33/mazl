import { test, expect, describe, beforeAll } from "bun:test";

// Integration test for boost endpoints. Requires a running server (TEST_API_URL)
// with Postgres and dev endpoints enabled.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface TestUser { id: number; token: string }
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });

async function makeUser(): Promise<TestUser> {
  const email = `boost-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: "Boost User" }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser: ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

describe("Boost", () => {
  let user: TestUser;
  beforeAll(async () => { user = await makeUser(); });

  test("status → activate → status reflects active boost and decremented quota", async () => {
    let r = await fetch(`${BASE_URL}/api/boost/status`, { headers: H(user.token) });
    expect(r.status).toBe(200);
    let s = (await r.json()) as { is_active: boolean; remaining_boosts: number };
    expect(s.is_active).toBe(false);
    expect(s.remaining_boosts).toBe(3);

    r = await fetch(`${BASE_URL}/api/boost/activate`, { method: "POST", headers: H(user.token) });
    expect([200, 201]).toContain(r.status);
    const a = (await r.json()) as { is_active: boolean; expires_at: string | null };
    expect(a.is_active).toBe(true);
    expect(a.expires_at).toBeTruthy();

    r = await fetch(`${BASE_URL}/api/boost/status`, { headers: H(user.token) });
    s = (await r.json()) as { is_active: boolean; remaining_boosts: number };
    expect(s.is_active).toBe(true);
    expect(s.remaining_boosts).toBe(2);
  });
});
