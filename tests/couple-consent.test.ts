import { test, expect, describe } from "bun:test";

// Integration tests for the consent-based couple mode (docs/couple/CONTRAT.md).
// Expectations are written from the contract, not from the implementation.
// Requires a running server (TEST_API_URL) with Postgres and dev endpoints on.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const WS_URL = process.env.TEST_WS_URL || BASE_URL.replace(/^http/, "ws") + "/ws";

interface TestUser { id: number; token: string; name: string }
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });

async function makeUser(label: string): Promise<TestUser> {
  const email = `cc-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const name = `Name${label}`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token, name };
}

const swipe = (t: string, target: number) =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(t), body: JSON.stringify({ target_user_id: target, action: "like" }) });

async function makeMatchedPair(label: string): Promise<[TestUser, TestUser]> {
  const a = await makeUser(`${label}a`);
  const b = await makeUser(`${label}b`);
  await swipe(a.token, b.id);
  await swipe(b.token, a.id);
  return [a, b];
}

const sendRequest = (t: string, target: number) =>
  fetch(`${BASE_URL}/api/couple/request`, { method: "POST", headers: H(t), body: JSON.stringify({ target_user_id: target }) });
const respond = (t: string, id: number, action: "accept" | "reject") =>
  fetch(`${BASE_URL}/api/couple/request/${id}`, { method: "PUT", headers: H(t), body: JSON.stringify({ action }) });
const getCouple = async (t: string) =>
  (await (await fetch(`${BASE_URL}/api/couple`, { headers: H(t) })).json()) as { success: boolean; couple: CoupleView | null; milestones?: unknown[] };

interface CoupleView {
  id: number; partner_id: number; partner_name: string; partner_picture: string | null;
  started_at: string; met_on_mazl_at: string; status: string;
}
interface RequestView {
  id: number; requester_id: number; target_id: number; status: string; created_at: string;
  target_name: string; target_picture: string | null;
}

class WsClient {
  readonly events: Array<{ type: string; payload: Record<string, unknown> }> = [];
  private constructor(private readonly ws: WebSocket) {
    ws.onmessage = (e) => {
      try {
        const m = JSON.parse(String(e.data)) as { type: string; payload: Record<string, unknown> };
        this.events.push(m);
      } catch { /* ignore non-JSON frames */ }
    };
  }
  static async connect(token: string): Promise<WsClient> {
    const ws = new WebSocket(`${WS_URL}?token=${token}`);
    await new Promise<void>((res, rej) => { ws.onopen = () => res(); ws.onerror = () => rej(new Error("ws error")); });
    return new WsClient(ws);
  }
  async waitFor(type: string, timeoutMs = 4000): Promise<{ type: string; payload: Record<string, unknown> }> {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      const found = this.events.find((e) => e.type === type);
      if (found) return found;
      await new Promise((r) => setTimeout(r, 50));
    }
    throw new Error(`no ${type} event received; got ${JSON.stringify(this.events.map((e) => e.type))}`);
  }
  close(): void { this.ws.close(); }
}

describe("unilateral creation is gone", () => {
  test("POST /api/couple answers 403 couple_request_required and creates nothing", async () => {
    const [a, b] = await makeMatchedPair("uni");
    const res = await fetch(`${BASE_URL}/api/couple`, { method: "POST", headers: H(a.token), body: JSON.stringify({ partnerId: b.id }) });
    expect(res.status).toBe(403);
    expect(await res.json()).toEqual({ success: false, error: "couple_request_required" });
    expect((await getCouple(a.token)).couple).toBeNull();
    expect((await getCouple(b.token)).couple).toBeNull();
  });
});

describe("a request needs a mutual match and no block", () => {
  test("non-matched users: 403 not_matched, nothing pending", async () => {
    const a = await makeUser("nma");
    const b = await makeUser("nmb");
    const res = await sendRequest(a.token, b.id);
    expect(res.status).toBe(403);
    expect(await res.json()).toEqual({ success: false, error: "not_matched" });
    const list = (await (await fetch(`${BASE_URL}/api/couple/requests`, { headers: H(b.token) })).json()) as { received: unknown[] };
    expect(list.received).toHaveLength(0);
  });

  test("a one-sided like is not a match", async () => {
    const a = await makeUser("osa");
    const b = await makeUser("osb");
    await swipe(a.token, b.id);
    const res = await sendRequest(a.token, b.id);
    expect(res.status).toBe(403);
    expect(((await res.json()) as { error: string }).error).toBe("not_matched");
  });

  for (const direction of ["requester blocked target", "target blocked requester"] as const) {
    test(`matched but blocked (${direction}): 403`, async () => {
      const [a, b] = await makeMatchedPair(direction === "requester blocked target" ? "bla" : "blb");
      const [blocker, blocked] = direction === "requester blocked target" ? [a, b] : [b, a];
      const blockRes = await fetch(`${BASE_URL}/api/users/${blocked.id}/block`, { method: "POST", headers: H(blocker.token) });
      expect(blockRes.status).toBe(200);
      const res = await sendRequest(a.token, b.id);
      expect(res.status).toBe(403);
      expect(((await res.json()) as { success: boolean }).success).toBe(false);
      const list = (await (await fetch(`${BASE_URL}/api/couple/requests`, { headers: H(b.token) })).json()) as { received: unknown[] };
      expect(list.received).toHaveLength(0);
    });
  }

  test("self-target stays a 400", async () => {
    const a = await makeUser("self");
    expect((await sendRequest(a.token, a.id)).status).toBe(400);
  });

  test("matched users: the request is created with target name and picture", async () => {
    const [a, b] = await makeMatchedPair("ok");
    const res = await sendRequest(a.token, b.id);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; request: RequestView };
    expect(body.success).toBe(true);
    expect(body.request).toMatchObject({ requester_id: a.id, target_id: b.id, status: "pending", target_name: b.name });
    expect(typeof body.request.id).toBe("number");
    expect(Number.isNaN(Date.parse(body.request.created_at))).toBe(false);
    expect(body.request.target_picture === null || typeof body.request.target_picture === "string").toBe(true);
  });
});

describe("acceptance and the couple shape", () => {
  test("accept returns the §1 shape seen from the accepter; GET /api/couple agrees for both sides", async () => {
    const [a, b] = await makeMatchedPair("acc");
    const reqId = ((await (await sendRequest(a.token, b.id)).json()) as { request: RequestView }).request.id;

    const res = await respond(b.token, reqId, "accept");
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; action: string; couple: CoupleView };
    expect(body.success).toBe(true);
    expect(body.action).toBe("accepted");
    expect(Object.keys(body.couple).sort()).toEqual(
      ["id", "met_on_mazl_at", "partner_id", "partner_name", "partner_picture", "started_at", "status"],
    );
    expect(body.couple.partner_id).toBe(a.id);
    expect(body.couple.partner_name).toBe(a.name);
    expect(typeof body.couple.status).toBe("string");
    expect(Number.isNaN(Date.parse(body.couple.started_at))).toBe(false);
    expect(Number.isNaN(Date.parse(body.couple.met_on_mazl_at))).toBe(false);

    const forB = await getCouple(b.token);
    expect(forB.success).toBe(true);
    expect(forB.couple).toEqual(body.couple);
    expect(Array.isArray(forB.milestones)).toBe(true);

    const forA = await getCouple(a.token);
    expect(forA.couple?.id).toBe(body.couple.id);
    expect(forA.couple?.partner_id).toBe(b.id);
    expect(forA.couple?.partner_name).toBe(b.name);
  });

  test("GET /api/couple is null before any acceptance", async () => {
    const [a, b] = await makeMatchedPair("none");
    await sendRequest(a.token, b.id);
    expect(await getCouple(a.token)).toMatchObject({ success: true, couple: null });
    expect(await getCouple(b.token)).toMatchObject({ success: true, couple: null });
  });

  test("DELETE /api/couple/:id ends the couple for both members; a stranger cannot", async () => {
    const [a, b] = await makeMatchedPair("end");
    const stranger = await makeUser("endx");
    const reqId = ((await (await sendRequest(a.token, b.id)).json()) as { request: RequestView }).request.id;
    const { couple } = (await (await respond(b.token, reqId, "accept")).json()) as { couple: CoupleView };

    const denied = await fetch(`${BASE_URL}/api/couple/${couple.id}`, { method: "DELETE", headers: H(stranger.token) });
    expect(denied.status).toBe(403);
    expect((await getCouple(a.token)).couple).not.toBeNull();

    const res = await fetch(`${BASE_URL}/api/couple/${couple.id}`, { method: "DELETE", headers: H(a.token) });
    expect(res.status).toBe(200);
    expect((await getCouple(a.token)).couple).toBeNull();
    expect((await getCouple(b.token)).couple).toBeNull();
  });
});

describe("realtime events (contract §3)", () => {
  test("couple:request reaches the target with the received-request shape", async () => {
    const [a, b] = await makeMatchedPair("wsr");
    const wsB = await WsClient.connect(b.token);
    const wsA = await WsClient.connect(a.token);
    const reqId = ((await (await sendRequest(a.token, b.id)).json()) as { request: RequestView }).request.id;

    const ev = await wsB.waitFor("couple:request");
    const request = ev.payload.request as Record<string, unknown>;
    expect(request).toMatchObject({ id: reqId, requester_id: a.id, target_id: b.id, status: "pending", requester_name: a.name });
    expect("requester_picture" in request).toBe(true);
    // the requester never receives their own request event
    await new Promise((r) => setTimeout(r, 200));
    expect(wsA.events.some((e) => e.type === "couple:request")).toBe(false);
    wsA.close();
    wsB.close();
  });

  test("couple:accepted reaches the requester with the couple seen from the requester", async () => {
    const [a, b] = await makeMatchedPair("wsa");
    const wsA = await WsClient.connect(a.token);
    const reqId = ((await (await sendRequest(a.token, b.id)).json()) as { request: RequestView }).request.id;
    const accepted = (await (await respond(b.token, reqId, "accept")).json()) as { couple: CoupleView };

    const ev = await wsA.waitFor("couple:accepted");
    const couple = ev.payload.couple as CoupleView;
    expect(couple.id).toBe(accepted.couple.id);
    expect(couple.partner_id).toBe(b.id);
    expect(couple.partner_name).toBe(b.name);
    expect(Object.keys(couple).sort()).toEqual(
      ["id", "met_on_mazl_at", "partner_id", "partner_name", "partner_picture", "started_at", "status"],
    );
    wsA.close();
  });

  test("couple:rejected reaches the requester with the request id", async () => {
    const [a, b] = await makeMatchedPair("wsj");
    const wsA = await WsClient.connect(a.token);
    const reqId = ((await (await sendRequest(a.token, b.id)).json()) as { request: RequestView }).request.id;
    expect((await respond(b.token, reqId, "reject")).status).toBe(200);

    const ev = await wsA.waitFor("couple:rejected");
    expect(ev.payload).toEqual({ request_id: reqId });
    wsA.close();
  });

  test("couple:ended reaches the other member only", async () => {
    const [a, b] = await makeMatchedPair("wse");
    const reqId = ((await (await sendRequest(a.token, b.id)).json()) as { request: RequestView }).request.id;
    const { couple } = (await (await respond(b.token, reqId, "accept")).json()) as { couple: CoupleView };
    const wsA = await WsClient.connect(a.token);
    const wsB = await WsClient.connect(b.token);

    expect((await fetch(`${BASE_URL}/api/couple/${couple.id}`, { method: "DELETE", headers: H(b.token) })).status).toBe(200);

    const ev = await wsA.waitFor("couple:ended");
    expect(ev.payload).toEqual({ couple_id: couple.id });
    await new Promise((r) => setTimeout(r, 200));
    expect(wsB.events.some((e) => e.type === "couple:ended")).toBe(false);
    wsA.close();
    wsB.close();
  });
});
