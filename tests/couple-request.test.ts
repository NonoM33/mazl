import { test, expect, describe } from "bun:test";

// Integration test for the couple request/accept/reject/cancel flow.
// Requires a running server (TEST_API_URL) with Postgres and dev endpoints on.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface TestUser { id: number; token: string }
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });

async function makeUser(label: string): Promise<TestUser> {
  const email = `cr-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: label }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}
const send = (t: string, target: number) =>
  fetch(`${BASE_URL}/api/couple/request`, { method: "POST", headers: H(t), body: JSON.stringify({ target_user_id: target }) });
async function checkStatus(t: string, other: number): Promise<string> {
  const r = await fetch(`${BASE_URL}/api/couple/check/${other}`, { headers: H(t) });
  return ((await r.json()) as { status: string }).status;
}

describe("Couple request flow", () => {
  test("accept creates the couple, with IDOR + duplicate + self-target guards", async () => {
    const a = await makeUser("A");
    const b = await makeUser("B");

    let r = await send(a.token, b.id);
    const sent = (await r.json()) as { success: boolean; request?: { id: number } };
    expect(r.status).toBe(200);
    expect(sent.request?.id).toBeTruthy();
    const reqId = sent.request!.id;

    expect(await checkStatus(a.token, b.id)).toBe("pending_sent");
    expect(await checkStatus(b.token, a.id)).toBe("pending_received");

    r = await fetch(`${BASE_URL}/api/couple/requests`, { headers: H(b.token) });
    const list = (await r.json()) as { received?: Array<{ id: number; requester_id: number }> };
    expect(list.received?.some((x) => x.id === reqId && x.requester_id === a.id)).toBe(true);

    // duplicate pending is refused
    expect((await send(a.token, b.id)).status).toBeGreaterThanOrEqual(400);
    // self-target refused
    expect((await send(a.token, a.id)).status).toBe(400);

    // a third party cannot accept (IDOR)
    const c = await makeUser("C");
    r = await fetch(`${BASE_URL}/api/couple/request/${reqId}`, { method: "PUT", headers: H(c.token), body: JSON.stringify({ action: "accept" }) });
    expect([403, 404]).toContain(r.status);

    // target accepts → couple created
    r = await fetch(`${BASE_URL}/api/couple/request/${reqId}`, { method: "PUT", headers: H(b.token), body: JSON.stringify({ action: "accept" }) });
    const acc = (await r.json()) as { success: boolean; couple?: unknown };
    expect(r.status).toBe(200);
    expect(acc.success).toBe(true);
    expect(acc.couple).toBeTruthy();
    expect(await checkStatus(a.token, b.id)).toBe("coupled");
  });

  test("reject clears the pending request", async () => {
    const d = await makeUser("D");
    const e = await makeUser("E");
    let r = await send(d.token, e.id);
    const reqId = ((await r.json()) as { request: { id: number } }).request.id;
    r = await fetch(`${BASE_URL}/api/couple/request/${reqId}`, { method: "PUT", headers: H(e.token), body: JSON.stringify({ action: "reject" }) });
    expect(r.status).toBe(200);
    expect(await checkStatus(d.token, e.id)).toBe("none");
  });

  test("requester can cancel", async () => {
    const f = await makeUser("F");
    const g = await makeUser("G");
    let r = await send(f.token, g.id);
    const reqId = ((await r.json()) as { request: { id: number } }).request.id;
    r = await fetch(`${BASE_URL}/api/couple/request/${reqId}`, { method: "DELETE", headers: H(f.token) });
    expect(r.status).toBe(200);
    expect(await checkStatus(f.token, g.id)).toBe("none");
  });
});
