import { test, expect, describe, beforeAll } from "bun:test";
import { THROWAWAY_CREDENTIAL } from "./throwaway-credential";

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
    body: JSON.stringify({ email, password: THROWAWAY_CREDENTIAL, name: "Boost User" }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser: ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

describe("Boost", () => {
  let user: TestUser;
  beforeAll(async () => { user = await makeUser(); });

  // docs/premium/CREDITS.md: a free member has no boost included (it used to be
  // 3 a day, enforced nowhere), so the first activation is refused with 402 until
  // boosts are bought or mazl+ is active. The nominal flow (debit, 409 while a
  // boost runs, undo on failure) is covered without a server in
  // tests/unit/credits-boost.test.ts.
  test("a free member has no boost: status says 0, activation is refused with 402", async () => {
    let r = await fetch(`${BASE_URL}/api/boost/status`, { headers: H(user.token) });
    expect(r.status).toBe(200);
    const s = (await r.json()) as { is_active: boolean; remaining_boosts: number; credits: { boost: { available: number } } };
    expect(s.is_active).toBe(false);
    expect(s.remaining_boosts).toBe(0);
    expect(s.credits.boost.available).toBe(0);

    r = await fetch(`${BASE_URL}/api/boost/activate`, { method: "POST", headers: H(user.token) });
    expect(r.status).toBe(402);
    const refused = (await r.json()) as { success: boolean; error: string; credits: { boost: { available: number } } };
    expect(refused.error).toBe("boosts_exhausted");
    expect(refused.credits.boost.available).toBe(0);
  });
});
