import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Subprocess } from "bun";
import { join } from "node:path";
import { db, json, makeUser, type TestUser } from "./media-helpers";

// The push notifications as gorush receives them (V1-CONTRAT section 1),
// through a second API server pointed at a fake gorush of this file: the app's
// device declaration (PUT /api/push/devices) and the real hooks (new match,
// stored message, HTTP and WebSocket) with nothing leaving the machine.

// One gorush notification, as the server posts it: one per device.
interface Received {
  readonly secret: string | null;
  readonly body: {
    tokens?: string[];
    topic?: string;
    production?: boolean;
    data?: Record<string, unknown>;
    collapse_id?: string;
    title?: string;
    message?: string;
  };
}

const received: Received[] = [];
let providerDelayMs = 0;
let gorush: ReturnType<typeof Bun.serve>;
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
  gorush = Bun.serve({
    port: 0,
    hostname: "127.0.0.1",
    async fetch(request) {
      await Bun.sleep(providerDelayMs);
      const secret = request.headers.get("x-neo-push-secret");
      const { notifications } = (await request.json()) as { notifications: Received["body"][] };
      for (const body of notifications) received.push({ secret, body });
      return Response.json({ success: "ok", counts: notifications.length, logs: [] });
    },
  });
  const port = await freePort();
  API = `http://127.0.0.1:${port}`;
  api = Bun.spawn(["bun", join(import.meta.dir, "../src/index.ts")], {
    env: {
      ...(process.env as Record<string, string>),
      PORT: String(port),
      GORUSH_URL: `http://127.0.0.1:${gorush.port}`,
      GORUSH_SHARED_SECRET: "fake-gorush-secret",
      BOOST_END_SWEEP_MS: "300",
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
  await gorush?.stop(true);
});

const EMOJI = /\p{Extended_Pictographic}/u;

// The APNs token of a test member's phone: 64 hexadecimal characters from their id.
const tokenOf = (user: TestUser): string => user.id.toString(16).padStart(64, "0");

// A member with a display name and a phone declared as the app does.
async function named(label: string, displayName: string): Promise<TestUser> {
  const user = await makeUser(label);
  await db`
    INSERT INTO profiles (user_id, display_name) VALUES (${user.id}, ${displayName})
    ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name`;
  const declared = await fetch(`${API}/api/push/devices`, {
    method: "PUT",
    headers: json(user.token),
    body: JSON.stringify({ token: tokenOf(user), environment: "production" }),
  });
  if (declared.status !== 200) throw new Error(`device declaration failed: ${declared.status}`);
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

const pushesTo = (user: TestUser): Received[] => received.filter((push) => push.body.tokens?.includes(tokenOf(user)));

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
  test("both members are pushed, each with the other's id and the conversation; the first like is told as a like only", async () => {
    const a = await named("matcha", "Sarah Cohen");
    const b = await named("matchb", "Daniel Lévy");
    await swipe(a, b.id);
    await waitForPushes(b, 1);
    expect(pushesTo(a)).toHaveLength(0);
    expect(pushesTo(b).map((push) => push.body.data)).toEqual([{ type: "new_like" }]);
    expect(JSON.stringify(pushesTo(b)[0]?.body)).not.toContain("Sarah");

    await swipe(b, a.id);
    const conversationId = await conversationOf(a);
    const ofMatch = (pushes: Received[]) => pushes.filter((push) => push.body.data?.type === "new_match");
    const [toA, toB] = [ofMatch(await waitForPushes(a, 1)), ofMatch(await waitForPushes(b, 2))];
    expect(toA).toHaveLength(1);
    expect(toB).toHaveLength(1);
    expect(toA[0]?.secret).toBe("fake-gorush-secret");
    expect(toA[0]?.body.topic).toBe("com.mazl.app");
    expect(toA[0]?.body.production).toBe(true);
    expect(toA[0]?.body.data).toEqual({ type: "new_match", match_user_id: b.id, conversation_id: conversationId });
    expect(toB[0]?.body.data).toEqual({ type: "new_match", match_user_id: a.id, conversation_id: conversationId });
    expect(toA[0]?.body.message).toContain("Daniel");
    expect(toA[0]?.body.message).not.toContain("Lévy");
    expect(`${toA[0]?.body.title} ${toA[0]?.body.message}`).not.toMatch(EMOJI);
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
    expect(push?.body.message).toContain("Sarah");
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

describe("likes", () => {
  test("a second like within six hours does not push the same member again", async () => {
    const target = await named("liked", "Rachel Azoulay");
    await swipe(await named("liker1", "Sarah Cohen"), target.id);
    await swipe(await named("liker2", "Léa Benhamou"), target.id);
    expect((await waitForPushes(target, 2)).map((push) => push.body.data)).toEqual([{ type: "new_like" }]);
  }, 20_000);

  test("a like from a member the target blocked pushes nothing", async () => {
    const target = await named("blocker", "Rachel Azoulay");
    const liker = await named("blocked", "Sarah Cohen");
    await db`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${target.id}, ${liker.id})`;
    await swipe(liker, target.id);
    expect(await waitForPushes(target, 1)).toHaveLength(0);
  }, 20_000);
});

describe("the end of a Boost", () => {
  test("the member is pushed once when it ends; one that ended long ago is not", async () => {
    const member = await named("boosted", "Sarah Cohen");
    const old = await named("oldboost", "Daniel Lévy");
    await db`INSERT INTO boosts (user_id, activated_at, expires_at) VALUES (${member.id}, NOW() - INTERVAL '31 minutes', NOW() - INTERVAL '1 minute')`;
    await db`INSERT INTO boosts (user_id, activated_at, expires_at) VALUES (${old.id}, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours')`;
    const pushes = await waitForPushes(member, 1);
    await Bun.sleep(700);
    expect(pushesTo(member).map((push) => push.body.data)).toEqual([{ type: "boost_ended" }]);
    expect(pushes[0]?.body.title).toBe("Votre Boost est terminé");
    expect(pushesTo(old)).toHaveLength(0);
  }, 20_000);

  test("a Boost still running pushes nothing", async () => {
    const member = await named("running", "Sarah Cohen");
    await db`INSERT INTO boosts (user_id, activated_at, expires_at) VALUES (${member.id}, NOW(), NOW() + INTERVAL '30 minutes')`;
    expect(await waitForPushes(member, 1)).toHaveLength(0);
  }, 20_000);
});

describe("the administrators' pushes", () => {
  let adminToken = "";
  const admin = () => ({ "Content-Type": "application/json", Authorization: `Bearer ${adminToken}` });

  beforeAll(async () => {
    const res = await fetch(`${API}/api/admin/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: process.env.ADMIN_EMAIL ?? "admin@example.com", password: process.env.ADMIN_PASSWORD ?? "" }),
    });
    adminToken = ((await res.json()) as { token?: string }).token ?? "";
    if (adminToken === "") throw new Error("admin login failed: check ADMIN_EMAIL / ADMIN_PASSWORD");
  });

  test("a published event is announced to the reachable members of the list, with the event to open", async () => {
    const [a, b, off] = [await named("eva", "Sarah Cohen"), await named("evb", "Daniel Lévy"), await named("evoff", "Léa Benhamou")];
    await db`UPDATE users SET is_active = false WHERE id = ${off.id}`;
    const [event] = await db<{ id: number }[]>`
      INSERT INTO events (title, date, is_published, organizer_id) VALUES ('Shabbat à Paris', CURRENT_DATE + 7, true, ${a.id}) RETURNING id`;
    const res = await fetch(`${API}/api/admin/push/event-available`, {
      method: "POST",
      headers: admin(),
      body: JSON.stringify({ event_id: event?.id, user_ids: [a.id, b.id, off.id] }),
    });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, requested: 3, sent: 2, skipped: 1, failed: 0 });
    for (const member of [a, b]) {
      const push = (await waitForPushes(member, 1)).find((p) => p.body.data?.type === "event_available");
      expect(push?.body.data).toEqual({ type: "event_available", event_id: event?.id });
      expect(push?.body.message).toContain("Shabbat à Paris");
    }
    expect(pushesTo(off)).toHaveLength(0);
  }, 20_000);

  test("a draft event is not announced, and a member cannot announce one", async () => {
    const a = await named("evdraft", "Sarah Cohen");
    const [draft] = await db<{ id: number }[]>`
      INSERT INTO events (title, date, is_published, organizer_id) VALUES ('Brouillon', CURRENT_DATE + 7, false, ${a.id}) RETURNING id`;
    const body = JSON.stringify({ event_id: draft?.id, user_ids: [a.id] });
    expect((await fetch(`${API}/api/admin/push/event-available`, { method: "POST", headers: admin(), body })).status).toBe(404);
    expect((await fetch(`${API}/api/admin/push/event-available`, { method: "POST", headers: json(a.token), body })).status).toBe(401);
    expect(await waitForPushes(a, 1)).toHaveLength(0);
  }, 20_000);

  test("a test push reaches the member, and the status says pushes are configured", async () => {
    const a = await named("evtest", "Sarah Cohen");
    const res = await fetch(`${API}/api/admin/push/test`, { method: "POST", headers: admin(), body: JSON.stringify({ user_id: a.id }) });
    expect(await res.json()).toEqual({ success: true, sent: true });
    expect((await waitForPushes(a, 1)).map((push) => push.body.data)).toEqual([{ type: "admin_test" }]);
    expect(await (await fetch(`${API}/api/admin/push/status`, { headers: admin() })).json()).toEqual({ success: true, configured: true });
  }, 20_000);
});

describe("the devices the app declares", () => {
  test("a withdrawn device gets nothing more; a token declared by another member moves to them", async () => {
    const a = await named("deva", "Sarah Cohen");
    const b = await named("devb", "Daniel Lévy");
    const withdrawn = await fetch(`${API}/api/push/devices`, { method: "DELETE", headers: json(a.token), body: JSON.stringify({ token: tokenOf(a) }) });
    expect(withdrawn.status).toBe(200);
    await swipe(b, a.id);
    expect(await waitForPushes(a, 1)).toHaveLength(0);

    // b's phone is now used by a: only a is pushed on it.
    await fetch(`${API}/api/push/devices`, { method: "PUT", headers: json(a.token), body: JSON.stringify({ token: tokenOf(b), environment: "sandbox" }) });
    const owners = await db<{ user_id: number; environment: string }[]>`SELECT user_id, environment FROM push_devices WHERE token = ${tokenOf(b)}`;
    expect([...owners]).toEqual([{ user_id: a.id, environment: "sandbox" }]);
  }, 20_000);
});
