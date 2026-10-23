import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, VOICE_FIXTURE, WAVEFORM, auth, db, json, makeMatch, makeUser, sendText, upload, type Pair, type TestUser } from "./chat-helpers";
import { jpegWithGps } from "./media-helpers";

// CONTRAT.md §0.1: only the two members of a conversation may read, write or
// react. Everything else is a 404 that looks like "does not exist".

describe("non-members on every route", () => {
  let pair: Pair;
  let eve: TestUser;
  let messageId: number;

  beforeAll(async () => {
    pair = await makeMatch("access");
    eve = await makeUser("eve");
    messageId = (await sendText(pair.a.token, pair.conversationId, "message privé")).id;
  });

  const call = (method: string, path: string, token: string, body?: unknown) =>
    fetch(`${BASE_URL}${path}`, { method, headers: json(token), body: body === undefined ? undefined : JSON.stringify(body) });

  test("conversation detail, history, send, read", async () => {
    const id = pair.conversationId;
    expect((await call("GET", `/api/conversations/${id}`, eve.token)).status).toBe(404);
    expect((await call("GET", `/api/conversations/${id}/messages`, eve.token)).status).toBe(404);
    expect((await call("POST", `/api/conversations/${id}/messages`, eve.token, { content: "intrusion" })).status).toBe(404);
    expect((await call("PUT", `/api/conversations/${id}/read`, eve.token, { up_to_id: messageId })).status).toBe(404);
  });

  test("media upload, reaction, unsend, report", async () => {
    const id = pair.conversationId;
    expect((await upload(eve.token, id, { kind: "photo", file: await jpegWithGps(50, 50, 1) })).status).toBe(404);
    expect((await upload(eve.token, id, { kind: "voice", file: VOICE_FIXTURE, durationMs: 1000, waveform: WAVEFORM })).status).toBe(404);
    expect((await call("POST", `/api/messages/${messageId}/reactions`, eve.token, { emoji: "❤️" })).status).toBe(404);
    expect((await call("POST", `/api/messages/${messageId}/unsend`, eve.token)).status).toBe(404);
    expect((await call("POST", `/api/messages/${messageId}/report`, eve.token, { reason: "spam" })).status).toBe(404);
  });

  test("nothing the stranger tried left a trace", async () => {
    const rows = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${pair.conversationId}`;
    expect(rows[0]?.n).toBe("1");
    const reactions = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_reactions WHERE message_id = ${messageId}`;
    expect(reactions[0]?.n).toBe("0");
    const media = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_media WHERE conversation_id = ${pair.conversationId}`;
    expect(media[0]?.n).toBe("0");
    const reports = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM reports WHERE message_id = ${messageId}`;
    expect(reports[0]?.n).toBe("0");
  });

  test("a missing id, a malformed id and a missing token", async () => {
    expect((await call("GET", `/api/conversations/999999999/messages`, pair.a.token)).status).toBe(404);
    expect((await call("GET", `/api/conversations/abc/messages`, pair.a.token)).status).toBe(404);
    expect((await call("POST", `/api/messages/999999999/reactions`, pair.a.token, { emoji: "❤️" })).status).toBe(404);
    const anonymous = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`);
    expect(anonymous.status).toBe(401);
  });

  test("the members themselves are served", async () => {
    expect((await call("GET", `/api/conversations/${pair.conversationId}`, pair.b.token)).status).toBe(200);
    expect((await call("GET", `/api/conversations/${pair.conversationId}/messages`, pair.b.token)).status).toBe(200);
  });
});

describe("old app versions keep working", () => {
  test("POST {content} without client_id, and the legacy fields of GET", async () => {
    const pair = await makeMatch("legacy");
    const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, {
      method: "POST", headers: json(pair.a.token), body: JSON.stringify({ content: "salut" }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; message: { id: number; content: string; sender_id: number; created_at: string; type: string; client_id: string | null } };
    expect(body.success).toBe(true);
    expect(body.message).toMatchObject({ content: "salut", sender_id: pair.a.id, type: "text", client_id: null });

    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages?limit=50&offset=0`, { headers: auth(pair.b.token) })).json()) as {
      messages: Array<{ id: number; sender_id: number; content: string; is_read: boolean; created_at: string }>;
    };
    expect(listed.messages[0]).toMatchObject({ content: "salut", sender_id: pair.a.id, is_read: false });
    expect(Number.isNaN(Date.parse(listed.messages[0]!.created_at))).toBe(false);
  });

  test("rows written before the redesign are read as text, and is_read becomes read_at", async () => {
    const pair = await makeMatch("backfill");
    // A row exactly as the old code wrote it: no new column filled in.
    const [old] = await db<{ id: number }[]>`
      INSERT INTO messages (conversation_id, sender_id, content, is_read, created_at)
      VALUES (${pair.conversationId}, ${pair.a.id}, 'ancien', true, NOW() - INTERVAL '3 days') RETURNING id`;
    const { ensureChatSchema } = await import("../src/features/chat");
    await ensureChatSchema(); // boot task, idempotent
    await ensureChatSchema();
    const [row] = await db<{ type: string; read_at: Date | null; created_at: Date }[]>`SELECT type, read_at, created_at FROM messages WHERE id = ${old!.id}`;
    expect(row?.type).toBe("text");
    expect(row?.read_at).not.toBeNull();
    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.b.token) })).json()) as {
      messages: Array<{ content: string; type: string; read_at: string | null; unsent: boolean }>;
    };
    expect(listed.messages[0]).toMatchObject({ content: "ancien", type: "text", unsent: false });
    expect(listed.messages[0]!.read_at).not.toBeNull();
  });
});
