import { test, expect, describe, beforeAll } from "bun:test";

// Integration test for selfie verification endpoints (flow + server-side 3/day
// limit). Requires a running server (TEST_API_URL) with Postgres and dev on.
// Note: no real face-matching is performed server-side (out of scope) — the flow
// and the daily quota are what this test locks in.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface TestUser { id: number; token: string }
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });
const GESTURES = ["hand_up", "smile", "thumbs_up"];

async function makeUser(label: string): Promise<TestUser> {
  const email = `vf-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: label }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

describe("Selfie verification", () => {
  test("start → submit marks verified", async () => {
    const u = await makeUser("verify");
    let r = await fetch(`${BASE_URL}/api/verification/status`, { headers: H(u.token) });
    expect(r.status).toBe(200);
    let s = (await r.json()) as { is_verified: boolean; attempts_today: number };
    expect(s.is_verified).toBe(false);
    expect(s.attempts_today).toBe(0);

    r = await fetch(`${BASE_URL}/api/verification/start`, { method: "POST", headers: H(u.token) });
    expect(r.status).toBe(200);
    const st = (await r.json()) as { gesture_id?: string };
    expect(GESTURES).toContain(st.gesture_id);

    r = await fetch(`${BASE_URL}/api/verification/submit`, {
      method: "POST",
      headers: H(u.token),
      body: JSON.stringify({ selfie: "data:image/png;base64,AAAA", gesture_id: st.gesture_id }),
    });
    expect(r.status).toBe(200);
    const sub = (await r.json()) as { verified: boolean };
    expect(sub.verified).toBe(true);

    r = await fetch(`${BASE_URL}/api/verification/status`, { headers: H(u.token) });
    s = (await r.json()) as { is_verified: boolean; attempts_today: number };
    expect(s.is_verified).toBe(true);
  });

  test("server enforces 3 attempts per day", async () => {
    const u = await makeUser("quota");
    for (let i = 0; i < 3; i++) {
      const r = await fetch(`${BASE_URL}/api/verification/start`, { method: "POST", headers: H(u.token) });
      expect(r.status).toBe(200);
    }
    const r = await fetch(`${BASE_URL}/api/verification/start`, { method: "POST", headers: H(u.token) });
    expect(r.status).toBe(429);
    const body = (await r.json()) as { next_attempt_time?: string };
    expect(body.next_attempt_time).toBeTruthy();
  });
});
