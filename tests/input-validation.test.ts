import { test, expect, describe, beforeAll } from "bun:test";

// Regression: write endpoints reject malformed input with 400 (permissive zod
// validation), while legitimate payloads keep working (covered by the other
// suites). Requires a running server (TEST_API_URL) with dev endpoints on.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

let token = "";
beforeAll(async () => {
  const email = `zod-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: "Zod" }),
  });
  token = ((await res.json()) as { token: string }).token;
});
const H = (): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${token}` });

describe("Input validation (400 on malformed bodies)", () => {
  test("swipe with non-numeric target is rejected", async () => {
    const r = await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(), body: JSON.stringify({ target_user_id: "NaN", action: "like" }) });
    expect(r.status).toBe(400);
  });
  test("swipe with unknown action is rejected", async () => {
    const r = await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(), body: JSON.stringify({ target_user_id: 5, action: "bogus" }) });
    expect(r.status).toBe(400);
  });
  test("couple request without target is rejected", async () => {
    const r = await fetch(`${BASE_URL}/api/couple/request`, { method: "POST", headers: H(), body: JSON.stringify({}) });
    expect(r.status).toBe(400);
  });
  test("invalid JSON body is rejected", async () => {
    const r = await fetch(`${BASE_URL}/api/couple/request`, { method: "POST", headers: H(), body: "not json" });
    expect(r.status).toBe(400);
  });
});
