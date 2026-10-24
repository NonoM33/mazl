import { afterAll, describe, expect, test } from "bun:test";
import { BASE_URL, WS_URL, auth, connect, db, expectNone, json, makeMatch, makeUser, onlyRow, send, sendText, type Pair, type Socket } from "./chat-helpers";

// Security of the chat, replayed as an attacker (or a blocked user) would do it,
// over real HTTP and WebSocket connections. Needs the running server.

const sockets: Socket[] = [];
const raw: WebSocket[] = [];
afterAll(() => {
  for (const s of sockets) s.close();
  for (const w of raw) w.close();
});

async function open(token: string): Promise<Socket> {
  const socket = await connect(token);
  sockets.push(socket);
  return socket;
}

const settle = (ms = 800): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

async function countMessages(conversationId: number, senderId: number): Promise<number> {
  const { n } = onlyRow(await db<{ n: string }[]>`
    SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${conversationId} AND sender_id = ${senderId}`);
  return Number(n);
}

async function block(blocker: number, blocked: number): Promise<void> {
  await db`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${blocker}, ${blocked})`;
}

describe("WebSocket chat:send size", () => {
  test("a 1 MB frame is not stored, and the next normal frame still is", async () => {
    const pair = await makeMatch("secsize");
    const alice = await open(pair.a.token);
    alice.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: "x".repeat(1_000_000), clientId: "big-1" } });
    alice.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: "x".repeat(5001), clientId: "big-2" } });
    alice.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: "ok", clientId: "ok-1" } });
    await alice.next("chat:message");
    await settle();
    expect(await countMessages(pair.conversationId, pair.a.id)).toBe(1);
  });
});

describe("WebSocket chat:send rate", () => {
  test("200 frames in a burst store 90 messages, and the REST quota is spent too", async () => {
    const pair = await makeMatch("secflood");
    const alice = await open(pair.a.token);
    for (let i = 0; i < 200; i++) {
      alice.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: `spam ${i}`, clientId: `flood-${i}` } });
    }
    await settle(2500);
    expect(await countMessages(pair.conversationId, pair.a.id)).toBe(90);
    const viaRest = await send(pair.a.token, pair.conversationId, { content: "one more" });
    expect(viaRest.status).toBe(429);
  });
});

describe("WebSocket chat:typing rate", () => {
  test("150 typing frames reach the other member at most 60 times", async () => {
    const pair = await makeMatch("sectype");
    const alice = await open(pair.a.token);
    const bob = await open(pair.b.token);
    for (let i = 0; i < 150; i++) alice.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: i % 2 === 0 } });
    await settle(1500);
    const received = bob.events.filter((e) => e.type === "chat:typing").length;
    expect(received).toBeGreaterThan(0);
    expect(received).toBeLessThanOrEqual(60);
  });
});

describe("sockets per user", () => {
  test("the 6th connection closes the oldest with 4008, the five others stay usable", async () => {
    const user = await makeUser("secconn");
    const opened: Array<{ ws: WebSocket; closed: Promise<{ code: number; reason: string }> }> = [];
    for (let i = 0; i < 6; i++) {
      const ws = new WebSocket(`${WS_URL}?token=${user.token}`);
      raw.push(ws);
      const closed = new Promise<{ code: number; reason: string }>((resolve) => { ws.onclose = (e) => resolve({ code: e.code, reason: e.reason }); });
      await new Promise<void>((resolve, reject) => { ws.onopen = () => resolve(); ws.onerror = () => reject(new Error("ws error")); });
      await settle(80);
      opened.push({ ws, closed });
    }
    const first = opened[0];
    if (first === undefined) throw new Error("no socket");
    expect(await first.closed).toEqual({ code: 4008, reason: "too_many_connections" });
    for (const { ws } of opened.slice(1)) expect(ws.readyState).toBe(WebSocket.OPEN);
  });
});

describe("blocked pairs: typing and read", () => {
  let pair: Pair;
  let alice: Socket;
  let bob: Socket;

  async function setUp(label: string): Promise<void> {
    pair = await makeMatch(label);
    alice = await open(pair.a.token);
    bob = await open(pair.b.token);
  }

  test("typing does not cross a block, in either direction", async () => {
    await setUp("secblocktype");
    await block(pair.b.id, pair.a.id);
    alice.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: true } });
    bob.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: true } });
    expect(await expectNone(bob, "chat:typing")).toBe(true);
    expect(await expectNone(alice, "chat:typing")).toBe(true);
  });

  test("typing still works between people who are not blocked (control)", async () => {
    await setUp("secblockctl");
    alice.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: true } });
    expect((await bob.next("chat:typing")).payload).toMatchObject({ user_id: pair.a.id, is_typing: true });
  });

  test("reading a blocked person's message tells them nothing: no chat:read, no read_at", async () => {
    await setUp("secblockread");
    const message = await sendText(pair.a.token, pair.conversationId, "avant le blocage");
    await alice.next("chat:message");
    await bob.next("chat:message");
    await block(pair.b.id, pair.a.id);

    bob.send({ type: "chat:read", payload: { conversationId: pair.conversationId, upToId: message.id } });
    const viaRest = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, {
      method: "PUT", headers: json(pair.b.token), body: JSON.stringify({ up_to_id: message.id }),
    });
    expect(viaRest.status).toBe(200);

    expect(await expectNone(alice, "chat:read")).toBe(true);
    const row = onlyRow(await db<{ read_at: Date | null }[]>`SELECT read_at FROM messages WHERE id = ${message.id}`);
    expect(row.read_at).toBeNull();
  });

  test("reading works between people who are not blocked (control)", async () => {
    await setUp("secreadctl");
    const message = await sendText(pair.a.token, pair.conversationId, "lis-moi");
    await alice.next("chat:message");
    await bob.next("chat:message");
    bob.send({ type: "chat:read", payload: { conversationId: pair.conversationId, upToId: message.id } });
    expect((await alice.next("chat:read")).payload).toMatchObject({ up_to_id: message.id });
  });
});

describe("REST limits", () => {
  test("a JSON message body over 16 KiB is refused with 413", async () => {
    const pair = await makeMatch("secbody");
    const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, {
      method: "POST", headers: json(pair.a.token), body: JSON.stringify({ content: "hi", padding: "x".repeat(20_000) }),
    });
    expect(res.status).toBe(413);
    expect(await countMessages(pair.conversationId, pair.a.id)).toBe(0);
  });

  test("a normal message body is not affected by the limit (control)", async () => {
    const pair = await makeMatch("secbodyok");
    const { status } = await send(pair.a.token, pair.conversationId, { content: "y".repeat(4000) });
    expect(status).toBe(200);
  });

  test("history reads are limited per user: 130 reads in a burst end in 429", async () => {
    const pair = await makeMatch("sechist");
    const statuses: number[] = [];
    for (let i = 0; i < 130; i++) {
      const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.a.token) });
      statuses.push(res.status);
    }
    expect(statuses.filter((s) => s === 200)).toHaveLength(120);
    expect(statuses.at(-1)).toBe(429);
  });

  test("reactions are limited per user: 130 toggles in a burst end in 429", async () => {
    const pair = await makeMatch("secreact");
    const message = await sendText(pair.a.token, pair.conversationId, "réagis");
    const statuses: number[] = [];
    for (let i = 0; i < 130; i++) {
      const res = await fetch(`${BASE_URL}/api/messages/${message.id}/reactions`, {
        method: "POST", headers: json(pair.b.token), body: JSON.stringify({ emoji: "❤️" }),
      });
      statuses.push(res.status);
    }
    expect(statuses.filter((s) => s === 200)).toHaveLength(120);
    expect(statuses.at(-1)).toBe(429);
  });

  test("marking as read is limited per user: 130 PUTs in a burst end in 429", async () => {
    const pair = await makeMatch("secreadrest");
    const statuses: number[] = [];
    for (let i = 0; i < 130; i++) {
      const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: json(pair.a.token), body: "{}" });
      statuses.push(res.status);
    }
    expect(statuses.filter((s) => s === 200)).toHaveLength(120);
    expect(statuses.at(-1)).toBe(429);
  });

  test("unsend is limited per user: 130 attempts in a burst end in 429", async () => {
    const pair = await makeMatch("secunsend");
    const message = await sendText(pair.a.token, pair.conversationId, "retire-moi");
    const statuses: number[] = [];
    for (let i = 0; i < 130; i++) {
      const res = await fetch(`${BASE_URL}/api/messages/${message.id}/unsend`, { method: "POST", headers: auth(pair.a.token) });
      statuses.push(res.status);
    }
    expect(statuses.filter((s) => s === 429).length).toBeGreaterThan(0);
    expect(statuses.at(-1)).toBe(429);
  });
});
