import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Subprocess } from "bun";
import { join } from "node:path";
import { db, json, makeUser, type TestUser } from "./media-helpers";

// The push notifications as OneSignal receives them (V1-CONTRAT section 1),
// through a second API server started with a key and pointed at a fake OneSignal
// of this file: the real hooks (new match, stored message, HTTP and WebSocket)
// with nothing leaving the machine.

interface Received {
  readonly authorization: string | null;
  readonly body: {
    include_external_user_ids?: string[];
    data?: Record<string, unknown>;
    collapse_id?: string;
    headings?: { fr?: string };
    contents?: { fr?: string };
  };
}

const received: Received[] = [];
let providerDelayMs = 0;
let oneSignal: ReturnType<typeof Bun.serve>;
let api: Subprocess;
let API = "";

async function freePort(): Promise<number> {
  const probe = Bun.serve({ port: 0, fetch: () => new Response("") });
  const port = probe.port;
  await probe.stop(true);
  if (port === undefined) throw new Error("no free port");
  return port;
}

beforeAll(async () => {
  oneSignal = Bun.serve({
    port: 0,
    hostname: "127.0.0.1",
    async fetch(request) {
      await Bun.sleep(providerDelayMs);
      received.push({ authorization: request.headers.get("authorization"), body: (await request.json()) as Received["body"] });
      return Response.json({ id: `fake-${received.length}`, recipients: 1 });
    },
  });
  const port = await freePort();
  API = `http://127.0.0.1:${port}`;
  api = Bun.spawn(["bun", join(import.meta.dir, "../src/index.ts")], {
    env: {
      ...(process.env as Record<string, string>),
      PORT: String(port),
      ONESIGNAL_REST_API_KEY: "fake-onesignal-key",
      ONESIGNAL_API_BASE: `http://127.0.0.1:${oneSignal.port}/api/v1`,
    },
    stdout: "ignore",
    stderr: "ignore",
  });
  for (let attempt = 0; attempt < 150; attempt += 1) {
    try {
      if ((await fetch(`${API}/api/health`)).ok) return;
    } catch {
      // not listening yet
    }
    await Bun.sleep(200);
  }
  throw new Error("the push API server did not start");
}, 40_000);

afterAll(async () => {
  api?.kill();
  await api?.exited;
  await oneSignal?.stop(true);
});

const EMOJI = /\p{Extended_Pictographic}/u;

async function named(label: string, displayName: string): Promise<TestUser> {
  const user = await makeUser(label);
  await db`
    INSERT INTO profiles (user_id, display_name) VALUES (${user.id}, ${displayName})
    ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name`;
  return user;
}

const swipe = (user: TestUser, target: number) =>
  fetch(`${API}/api/swipes`, { method: "POST", headers: json(user.token), body: JSON.stringify({ target_user_id: target, action: "like" }) });

async function conversationOf(user: TestUser): Promise<number> {
  const listed = (await (await fetch(`${API}/api/conversations`, { headers: json(user.token) })).json()) as { conversations: Array<{ id: number }> };
  const id = listed.conversations[0]?.id;
  if (id === undefined) throw new Error("no conversation");
  return id;
}

async function matched(label: string): Promise<{ a: TestUser; b: TestUser; conversationId: number }> {
  const a = await named(`${label}a`, "Sarah Cohen");
  const b = await named(`${label}b`, "Daniel Lévy");
  await swipe(a, b.id);
  await swipe(b, a.id);
  const conversationId = await conversationOf(a);
  await settle();
  return { a, b, conversationId };
}

const message = (user: TestUser, conversationId: number, content: string) =>
  fetch(`${API}/api/conversations/${conversationId}/messages`, { method: "POST", headers: json(user.token), body: JSON.stringify({ content }) });

const pushesTo = (user: TestUser): Received[] => received.filter((push) => push.body.include_external_user_ids?.includes(`user_${user.id}`));

// Pushes leave in the background: wait for the expected count, then a little
// longer so that an unexpected extra one would show.
async function waitForPushes(user: TestUser, count: number): Promise<Received[]> {
  for (let attempt = 0; attempt < 40 && pushesTo(user).length < count; attempt += 1) await Bun.sleep(100);
  await Bun.sleep(300);
  return pushesTo(user);
}

const settle = () => Bun.sleep(500);

function openSocket(user: TestUser): Promise<WebSocket> {
  const ws = new WebSocket(`${API.replace(/^http/, "ws")}/ws?token=${user.token}`);
  return new Promise((resolve, reject) => {
    ws.onopen = () => setTimeout(() => resolve(ws), 150);
    ws.onerror = () => reject(new Error("ws error"));
  });
}

describe("new match", () => {
  test("both members are pushed, each with the other's id and the conversation; the first like pushes nobody", async () => {
    const a = await named("matcha", "Sarah Cohen");
    const b = await named("matchb", "Daniel Lévy");
    await swipe(a, b.id);
    await settle();
    expect([pushesTo(a).length, pushesTo(b).length]).toEqual([0, 0]);

    await swipe(b, a.id);
    const conversationId = await conversationOf(a);
    const [toA, toB] = [await waitForPushes(a, 1), await waitForPushes(b, 1)];
    expect(toA).toHaveLength(1);
    expect(toB).toHaveLength(1);
    expect(toA[0]?.authorization).toBe("Basic fake-onesignal-key");
    expect(toA[0]?.body.data).toEqual({ type: "new_match", match_user_id: b.id, conversation_id: conversationId });
    expect(toB[0]?.body.data).toEqual({ type: "new_match", match_user_id: a.id, conversation_id: conversationId });
    expect(toA[0]?.body.contents?.fr).toContain("Daniel");
    expect(toA[0]?.body.contents?.fr).not.toContain("Lévy");
    expect(`${toA[0]?.body.headings?.fr} ${toA[0]?.body.contents?.fr}`).not.toMatch(EMOJI);
  }, 20_000);

  test("a match with a deactivated member pushes nobody", async () => {
    const a = await named("matchoffa", "Sarah Cohen");
    const b = await named("matchoffb", "Daniel Lévy");
    await db`UPDATE users SET is_active = false WHERE id = ${b.id}`;
    await swipe(a, b.id);
    await swipe(b, a.id);
    await settle();
    expect([pushesTo(a).length, pushesTo(b).length]).toEqual([0, 0]);
  }, 20_000);
});

describe("new message", () => {
  test("the recipient with no open socket is pushed once: new_message, the conversation, grouped, never the content", async () => {
    const { a, b, conversationId } = await matched("msg");
    const before = pushesTo(b).length;
    const res = await message(a, conversationId, "Rendez-vous chez Mamie vendredi soir");
    expect(res.status).toBe(200);
    const pushes = await waitForPushes(b, before + 1);
    expect(pushes).toHaveLength(before + 1);
    const push = pushes[pushes.length - 1];
    expect(push?.body.data).toEqual({ type: "new_message", conversation_id: conversationId });
    expect(push?.body.collapse_id).toBe(`conv-${conversationId}`);
    expect(push?.body.contents?.fr).toContain("Sarah");
    expect(JSON.stringify(push?.body)).not.toContain("Mamie");
    expect(JSON.stringify(push?.body)).not.toContain("Cohen");
    expect(pushesTo(a).filter((p) => p.body.data?.type === "new_message")).toHaveLength(0);
  }, 20_000);

  test("a recipient with an open socket is not pushed; once it closes, they are again", async () => {
    const { a, b, conversationId } = await matched("live");
    const socket = await openSocket(b);
    const before = pushesTo(b).length;
    await message(a, conversationId, "tu es là ?");
    expect((await waitForPushes(b, before + 1)).length).toBe(before);

    socket.close();
    await Bun.sleep(400);
    await message(a, conversationId, "et maintenant ?");
    expect((await waitForPushes(b, before + 1)).length).toBe(before + 1);
  }, 20_000);

  test("a message sent over the WebSocket (chat:send) pushes the recipient too", async () => {
    const { a, b, conversationId } = await matched("wssend");
    const socket = await openSocket(a);
    const before = pushesTo(b).length;
    socket.send(JSON.stringify({ type: "chat:send", payload: { conversationId, content: "par la socket", clientId: "ws-push-1" } }));
    const pushes = await waitForPushes(b, before + 1);
    socket.close();
    expect(pushes).toHaveLength(before + 1);
    expect(pushes[pushes.length - 1]?.body.data).toEqual({ type: "new_message", conversation_id: conversationId });
  }, 20_000);

  test("a deactivated recipient is not pushed", async () => {
    const { a, b, conversationId } = await matched("off");
    await db`UPDATE users SET is_active = false WHERE id = ${b.id}`;
    const before = pushesTo(b).length;
    await message(a, conversationId, "Shalom");
    expect((await waitForPushes(b, before + 1)).length).toBe(before);
  }, 20_000);

  test("the sender's request answers at once even though the push provider takes seconds", async () => {
    const { a, b, conversationId } = await matched("slow");
    providerDelayMs = 3000;
    try {
      const before = pushesTo(b).length;
      const started = performance.now();
      const res = await message(a, conversationId, "vite");
      expect(res.status).toBe(200);
      expect(performance.now() - started).toBeLessThan(1500);
      expect(pushesTo(b).length).toBe(before);
      expect((await waitForPushes(b, before + 1)).length).toBe(before + 1);
    } finally {
      providerDelayMs = 0;
    }
  }, 30_000);
});
