import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { grantPlus } from "./media-helpers";
import { BASE_URL, onlyRow, connect, db, expectNone, json, makeMatch, makeUser, send, sendText, type Pair, type Socket } from "./chat-helpers";

// CONTRAT.md §3: every change of a conversation reaches BOTH members as a
// {type, payload} frame, over real WebSocket connections.

let pair: Pair;
let alice: Socket;
let bob: Socket;
let eve: Socket;
const sockets: Socket[] = [];

beforeAll(async () => {
  pair = await makeMatch("rt");
  const stranger = await makeUser("rteve");
  [alice, bob, eve] = await Promise.all([connect(pair.a.token), connect(pair.b.token), connect(stranger.token)]);
  sockets.push(alice, bob, eve);
});
afterAll(() => { for (const s of sockets) s.close(); });

const post = (token: string, path: string, body?: unknown) =>
  fetch(`${BASE_URL}${path}`, { method: "POST", headers: json(token), body: body === undefined ? undefined : JSON.stringify(body) });

type Msg = { id: number; content: string; client_id: string | null; reactions: Array<{ emoji: string; user_ids: number[] }>; unsent: boolean; read_at: string | null };
const messageOf = (frame: { payload: Record<string, unknown> }): Msg => frame.payload.message as Msg;

describe("chat:message", () => {
  test("a REST send is pushed to the sender AND the recipient, with the §1 message", async () => {
    const sent = await sendText(pair.a.token, pair.conversationId, "bonjour", { client_id: "rt-1" });
    for (const socket of [alice, bob]) {
      const frame = await socket.next("chat:message");
      expect(messageOf(frame)).toMatchObject({ id: sent.id, content: "bonjour", client_id: "rt-1" });
      // fields installed apps already read
      expect(frame.payload).toMatchObject({ conversationId: pair.conversationId, messageId: sent.id, senderId: pair.a.id, content: "bonjour" });
    }
  });

  test("the retry of an idempotent send pushes nothing more", async () => {
    await sendText(pair.a.token, pair.conversationId, "once", { client_id: "rt-once" });
    await alice.next("chat:message");
    await bob.next("chat:message");
    await sendText(pair.a.token, pair.conversationId, "once", { client_id: "rt-once" });
    expect(await expectNone(bob, "chat:message")).toBe(true);
    expect(await expectNone(alice, "chat:message")).toBe(true);
  });

  test("a WebSocket chat:send (the old way) is stored and pushed to both", async () => {
    bob.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: "via ws", clientId: "ws-1" } });
    const [forAlice, forBob] = await Promise.all([alice.next("chat:message"), bob.next("chat:message")]);
    expect(messageOf(forAlice)).toMatchObject({ content: "via ws", client_id: "ws-1" });
    expect(messageOf(forBob).id).toBe(messageOf(forAlice).id);
    const { n } = onlyRow(await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE client_id = 'ws-1' AND sender_id = ${pair.b.id}`);
    expect(n).toBe("1");
  });

  test("a stranger receives nothing, and cannot send through the socket", async () => {
    eve.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: "intrusion" } });
    await sendText(pair.a.token, pair.conversationId, "entre nous");
    await alice.next("chat:message");
    await bob.next("chat:message");
    expect(await expectNone(eve, "chat:message")).toBe(true);
    const { n } = onlyRow(await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${pair.conversationId} AND content = 'intrusion'`);
    expect(n).toBe("0");
  });

  test("junk frames are ignored and the socket stays usable", async () => {
    bob.send({ type: "chat:send", payload: null });
    bob.send({ type: "chat:send", payload: { conversationId: "x", content: 5 } });
    bob.send({ type: "chat:send", payload: { conversationId: pair.conversationId, content: "" } });
    bob.send({ type: "chat:unknown", payload: {} });
    await sendText(pair.a.token, pair.conversationId, "still alive");
    expect(messageOf(await bob.next("chat:message")).content).toBe("still alive");
    await alice.next("chat:message");
  });

  test("a blocked sender through the socket is ignored", async () => {
    const blocked = await makeMatch("rtblock");
    const blockedSocket = await connect(blocked.a.token);
    sockets.push(blockedSocket);
    await db`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${blocked.b.id}, ${blocked.a.id})`;
    blockedSocket.send({ type: "chat:send", payload: { conversationId: blocked.conversationId, content: "hello?" } });
    await new Promise((r) => setTimeout(r, 500));
    const { n } = onlyRow(await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${blocked.conversationId}`);
    expect(n).toBe("0");
  });
});

describe("chat:typing", () => {
  test("goes to the other member only, with both spellings of the fields", async () => {
    alice.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: true } });
    const frame = await bob.next("chat:typing");
    expect(frame.payload).toMatchObject({
      conversation_id: pair.conversationId, user_id: pair.a.id, is_typing: true,
      conversationId: pair.conversationId, userId: pair.a.id, isTyping: true,
    });
    alice.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: false } });
    expect((await bob.next("chat:typing")).payload.is_typing).toBe(false);
    expect(await expectNone(alice, "chat:typing", 300)).toBe(true);
  });

  test("a stranger's typing reaches nobody", async () => {
    eve.send({ type: "chat:typing", payload: { conversationId: pair.conversationId, isTyping: true } });
    expect(await expectNone(alice, "chat:typing")).toBe(true);
    expect(await expectNone(bob, "chat:typing", 100)).toBe(true);
  });
});

describe("chat:read", () => {
  // The author is mazl+: only then is the reader's receipt pushed to them (docs/premium/MONETISATION.md section 4).
  test("PUT /read pushes up_to_id and read_at to both members; a repeat pushes nothing", async () => {
    await grantPlus(pair.a.id);
    const m = await sendText(pair.a.token, pair.conversationId, "à lire");
    await alice.next("chat:message");
    await bob.next("chat:message");
    const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: json(pair.b.token), body: JSON.stringify({ up_to_id: m.id }) });
    expect(res.status).toBe(200);
    for (const socket of [alice, bob]) {
      const frame = await socket.next("chat:read");
      expect(frame.payload).toMatchObject({ conversation_id: pair.conversationId, user_id: pair.b.id, up_to_id: m.id, conversationId: pair.conversationId, userId: pair.b.id });
      expect(Number.isNaN(Date.parse(String(frame.payload.read_at)))).toBe(false);
    }
    await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: json(pair.b.token), body: JSON.stringify({ up_to_id: m.id }) });
    expect(await expectNone(alice, "chat:read")).toBe(true);
  });

  test("the WebSocket chat:read (old way) is pushed too", async () => {
    await sendText(pair.a.token, pair.conversationId, "encore");
    await alice.next("chat:message");
    await bob.next("chat:message");
    bob.send({ type: "chat:read", payload: { conversationId: pair.conversationId } });
    const frame = await alice.next("chat:read");
    expect(frame.payload).toMatchObject({ user_id: pair.b.id, conversationId: pair.conversationId });
    expect(typeof frame.payload.up_to_id).toBe("number");
    await bob.next("chat:read");
  });
});

describe("chat:updated", () => {
  test("a reaction reaches both members", async () => {
    const m = await sendText(pair.a.token, pair.conversationId, "réagis");
    await alice.next("chat:message");
    await bob.next("chat:message");
    await post(pair.b.token, `/api/messages/${m.id}/reactions`, { emoji: "🔥" }); // refused: nothing pushed
    await post(pair.b.token, `/api/messages/${m.id}/reactions`, { emoji: "😮" });
    for (const socket of [alice, bob]) {
      const updated = messageOf(await socket.next("chat:updated"));
      expect(updated.id).toBe(m.id);
      expect(updated.reactions).toEqual([{ emoji: "😮", user_ids: [pair.b.id] }]);
    }
    expect(await expectNone(alice, "chat:updated", 300)).toBe(true);
  });

  test("an unsend reaches both members as an emptied message", async () => {
    const m = await sendText(pair.a.token, pair.conversationId, "à retirer");
    await alice.next("chat:message");
    await bob.next("chat:message");
    await post(pair.a.token, `/api/messages/${m.id}/unsend`);
    for (const socket of [alice, bob]) {
      expect(messageOf(await socket.next("chat:updated"))).toMatchObject({ id: m.id, unsent: true, content: "" });
    }
  });

  test("the stranger saw none of it", async () => {
    expect(eve.events.filter((e) => e.type.startsWith("chat:"))).toEqual([]);
  });
});

describe("link previews", () => {
  test("a link to a LOCAL server is refused: nothing is requested, no preview, the message is fine", async () => {
    const hits: string[] = [];
    const local = Bun.serve({
      port: 0,
      hostname: "127.0.0.1",
      fetch(req) {
        hits.push(req.url);
        return new Response(`<meta property="og:title" content="should never be read"><meta property="og:image" content="http://127.0.0.1/x.png">`, { headers: { "content-type": "text/html" } });
      },
    });
    try {
      const urls = [`http://127.0.0.1:${local.port}/page`, `http://localhost:${local.port}/page`, `http://[::1]:${local.port}/page`, `http://[::ffff:127.0.0.1]:${local.port}/page`];
      const fresh = await makeMatch("rtlink");
      const watcher = await connect(fresh.b.token);
      sockets.push(watcher);
      for (const url of urls) {
        const sent = await send(fresh.a.token, fresh.conversationId, { content: `regarde ${url}` });
        expect(sent.status).toBe(200);
        expect(sent.body.message!.link_preview).toBeNull();
        await watcher.next("chat:message");
        const [row] = await db<{ link_preview: unknown }[]>`SELECT link_preview FROM messages WHERE id = ${sent.body.message!.id}`;
        expect(row?.link_preview).toBeNull();
      }
      // wait: a preview job that wrongly fetched would have hit the server and pushed an update
      expect(await expectNone(watcher, "chat:updated", 1500)).toBe(true);
      expect(hits).toEqual([]);
      // the port is not 80/443, so these are refused before any DNS: the refusal is cached per URL
      const [cached] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM link_preview_cache WHERE url = ${urls[0]!}`;
      expect(cached?.n).toBe("1");
    } finally {
      local.stop(true);
    }
  });

  test("a link on a non-standard port or with credentials is refused as well", async () => {
    const fresh = await makeMatch("rtlink2");
    const sent = await send(fresh.a.token, fresh.conversationId, { content: "http://example.com:8080/ puis http://user:pw@example.com/" });
    expect(sent.status).toBe(200);
    await new Promise((r) => setTimeout(r, 500));
    const [row] = await db<{ link_preview: unknown }[]>`SELECT link_preview FROM messages WHERE id = ${sent.body.message!.id}`;
    expect(row?.link_preview).toBeNull();
  });
});

