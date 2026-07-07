import { test, expect, describe, beforeAll } from "bun:test";

// Security regression for the RevenueCat webhook: it must reject unauthenticated
// events (previously anyone could grant themselves premium) and map plans
// correctly. Requires a running server (TEST_API_URL) started with the SAME
// REVENUECAT_WEBHOOK_SECRET this test uses.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const SECRET = process.env.REVENUECAT_WEBHOOK_SECRET || "whsec_test";

interface TestUser { id: number; token: string }

async function makeUser(): Promise<TestUser> {
  const email = `wh-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: "Webhook User" }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser: ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

function event(userId: number, productId: string) {
  return JSON.stringify({
    event: {
      app_user_id: String(userId),
      product_id: productId,
      type: "INITIAL_PURCHASE",
      expiration_at_ms: Date.now() + 1000 * 60 * 60 * 24 * 180,
    },
  });
}

describe("RevenueCat webhook security", () => {
  let user: TestUser;
  beforeAll(async () => { user = await makeUser(); });

  test("rejects missing / wrong secret (401)", async () => {
    let r = await fetch(`${BASE_URL}/api/subscriptions/webhook`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: event(user.id, "mazl_six_month"),
    });
    expect(r.status).toBe(401);

    r = await fetch(`${BASE_URL}/api/subscriptions/webhook`, {
      method: "POST", headers: { "Content-Type": "application/json", Authorization: "nope" }, body: event(user.id, "mazl_six_month"),
    });
    expect(r.status).toBe(401);
  });

  test("accepts a signed event and maps the six-month plan", async () => {
    const r = await fetch(`${BASE_URL}/api/subscriptions/webhook`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: SECRET },
      body: event(user.id, "mazl_six_month"),
    });
    expect(r.status).toBe(200);

    const sub = await fetch(`${BASE_URL}/api/subscription`, { headers: { Authorization: `Bearer ${user.token}` } });
    const data = (await sub.json()) as { subscription?: { plan_type?: string; status?: string } };
    expect(data.subscription?.plan_type).toBe("six_month");
    expect(data.subscription?.status).toBe("active");
  });

  test("acknowledges anonymous ids without error (200)", async () => {
    const r = await fetch(`${BASE_URL}/api/subscriptions/webhook`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: SECRET },
      body: JSON.stringify({ event: { app_user_id: "$RCAnonymousID:abc", product_id: "x" } }),
    });
    expect(r.status).toBe(200);
  });
});
