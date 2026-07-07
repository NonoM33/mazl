import { test, expect, describe } from "bun:test";

// Integration test for real-time chat over WebSocket. Locks in that the extracted
// connection registry (src/shared/realtime/connections.ts) still delivers
// messages. Requires a running server (TEST_API_URL / TEST_WS_URL) with Postgres
// and dev endpoints on.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const WS_URL = process.env.TEST_WS_URL || BASE_URL.replace(/^http/, "ws") + "/ws";

interface TestUser { id: number; token: string }
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });

async function makeUser(label: string): Promise<TestUser> {
  const email = `ws-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: label }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}
const swipe = (t: string, target: number) =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: H(t), body: JSON.stringify({ target_user_id: target, action: "like" }) });
const open = (w: WebSocket) =>
  new Promise<void>((res, rej) => { w.onopen = () => res(); w.onerror = () => rej(new Error("ws error")); });

describe("WebSocket real-time chat", () => {
  test("a message sent by one member is delivered to the other", async () => {
    const a = await makeUser("a");
    const b = await makeUser("b");
    await swipe(a.token, b.id);
    await swipe(b.token, a.id); // reciprocal → match + conversation

    const conv = (await (await fetch(`${BASE_URL}/api/conversations`, { headers: H(a.token) })).json()) as {
      conversations: Array<{ id: number }>;
    };
    const convId = conv.conversations[0]!.id;

    const wsA = new WebSocket(`${WS_URL}?token=${a.token}`);
    const wsB = new WebSocket(`${WS_URL}?token=${b.token}`);
    await Promise.all([open(wsA), open(wsB)]);

    const received = new Promise<boolean>((resolve) => {
      const timer = setTimeout(() => resolve(false), 4000);
      wsB.onmessage = (e) => {
        try {
          const m = JSON.parse(String(e.data)) as { type?: string };
          if (m.type === "chat:message") { clearTimeout(timer); resolve(true); }
        } catch { /* ignore non-JSON frames */ }
      };
    });

    await new Promise((r) => setTimeout(r, 300));
    wsA.send(JSON.stringify({ type: "chat:send", payload: { conversationId: convId, content: "hello via ws" } }));

    expect(await received).toBe(true);
    wsA.close();
    wsB.close();
  });
});
