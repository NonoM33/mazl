import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeMatch, send, sendText, uploadOk, WAVEFORM, VOICE_FIXTURE, type ApiMessage, type Pair } from "./chat-helpers";
import { jpegWithGps } from "./media-helpers";

// CONTRAT.md §1-§2 over HTTP, against a real server and database.

const post = (token: string, path: string, body?: unknown) =>
  fetch(`${BASE_URL}${path}`, { method: "POST", headers: json(token), body: body === undefined ? undefined : JSON.stringify(body) });

describe("history: cursor pagination", () => {
  let pair: Pair;
  beforeAll(async () => {
    pair = await makeMatch("page");
    for (let i = 1; i <= 7; i++) await sendText(i % 2 ? pair.a.token : pair.b.token, pair.conversationId, `m${i}`);
  });

  const page = async (query: string) => {
    const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages?${query}`, { headers: auth(pair.a.token) });
    return { status: res.status, body: (await res.json()) as { success: boolean; messages: ApiMessage[]; has_more: boolean; error?: string } };
  };

  test("newest first, before=<id> walks back, has_more tells when to stop", async () => {
    const first = await page("limit=3");
    expect(first.body.messages.map((m) => m.content)).toEqual(["m7", "m6", "m5"]);
    expect(first.body.has_more).toBe(true);
    const second = await page(`limit=3&before=${first.body.messages.at(-1)!.id}`);
    expect(second.body.messages.map((m) => m.content)).toEqual(["m4", "m3", "m2"]);
    expect(second.body.has_more).toBe(true);
    const third = await page(`limit=3&before=${second.body.messages.at(-1)!.id}`);
    expect(third.body.messages.map((m) => m.content)).toEqual(["m1"]);
    expect(third.body.has_more).toBe(false);
  });

  test("the default page is 30, the maximum is 50", async () => {
    for (let i = 8; i <= 60; i++) await sendText(pair.a.token, pair.conversationId, `m${i}`);
    expect((await page("")).body.messages).toHaveLength(30);
    expect((await page("limit=500")).body.messages).toHaveLength(50);
    expect((await page("limit=500")).body.has_more).toBe(true);
  });

  test("a message carries the full §1 shape", async () => {
    const [newest] = (await page("limit=1")).body.messages;
    expect(newest).toMatchObject({
      conversation_id: pair.conversationId, sender_id: pair.a.id, type: "text", media: [], voice: null,
      reply_to: null, reactions: [], link_preview: null, read_at: null, unsent: false,
    });
    expect(Number.isNaN(Date.parse(newest!.created_at))).toBe(false);
  });

  test("garbage cursors are a 400, not a crash", async () => {
    expect((await page("before=abc")).status).toBe(400);
    expect((await page("limit=-1")).status).toBe(400);
  });
});

describe("sending", () => {
  let pair: Pair;
  beforeAll(async () => { pair = await makeMatch("send"); });

  test("idempotent on client_id: the retry returns the same message and stores one row", async () => {
    const first = await send(pair.a.token, pair.conversationId, { client_id: "c-retry-1", content: "une fois" });
    const second = await send(pair.a.token, pair.conversationId, { client_id: "c-retry-1", content: "une fois" });
    expect([first.status, second.status]).toEqual([200, 200]);
    expect(second.body.message!.id).toBe(first.body.message!.id);
    expect(first.body.message!.client_id).toBe("c-retry-1");
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${pair.conversationId} AND client_id = 'c-retry-1'`;
    expect(n).toBe("1");
  });

  test("two simultaneous sends with the same client_id still make one message", async () => {
    const results = await Promise.all(Array.from({ length: 6 }, () => send(pair.a.token, pair.conversationId, { client_id: "c-race", content: "course" })));
    expect(new Set(results.map((r) => r.body.message!.id)).size).toBe(1);
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE client_id = 'c-race' AND conversation_id = ${pair.conversationId}`;
    expect(n).toBe("1");
  });

  test("a reply carries a summary of the original; one from another conversation is refused", async () => {
    const original = await sendText(pair.b.token, pair.conversationId, "On se voit jeudi ?");
    const reply = await sendText(pair.a.token, pair.conversationId, "Oui !", { reply_to_id: original.id });
    expect(reply.reply_to).toEqual({ id: original.id, sender_id: pair.b.id, type: "text", preview: "On se voit jeudi ?" });

    const other = await makeMatch("sendother");
    const foreign = await sendText(other.a.token, other.conversationId, "ailleurs");
    const refused = await send(pair.a.token, pair.conversationId, { content: "x", reply_to_id: foreign.id });
    expect(refused.status).toBe(400);
  });

  test("photos and a voice note travel as attachments, each usable once", async () => {
    const one = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(300, 200, 1) });
    const two = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(100, 100, 1) });
    const sent = await send(pair.a.token, pair.conversationId, { client_id: "c-photos", type: "photo", content: "vue", media_ids: [two.id, one.id] });
    expect(sent.status).toBe(200);
    expect(sent.body.message).toMatchObject({ type: "photo", content: "vue" });
    expect(sent.body.message!.media.map((m) => m.id)).toEqual([two.id, one.id]); // order of media_ids
    expect(sent.body.message!.media[0]).toMatchObject({ kind: "photo", width: 100, height: 100 });

    const again = await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [one.id] });
    expect(again.status).toBe(400); // already attached

    const voice = await uploadOk(pair.a.token, pair.conversationId, { kind: "voice", file: VOICE_FIXTURE, durationMs: 8300, waveform: WAVEFORM });
    const note = await send(pair.a.token, pair.conversationId, { type: "voice", media_ids: [voice.id] });
    expect(note.body.message!.voice).toMatchObject({ id: voice.id, duration_ms: 8300 });
    expect(note.body.message!.voice!.waveform).toHaveLength(48);
    expect(note.body.message!.media).toEqual([]);
    expect(note.body.message!.content).toBe("");
  });

  test("media of the other member, of another conversation, or unknown is refused and stays unattached", async () => {
    const theirs = await uploadOk(pair.b.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
    expect((await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [theirs.id] })).status).toBe(400);

    const other = await makeMatch("sendforeign");
    const elsewhere = await uploadOk(other.a.token, other.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
    expect((await send(other.a.token, pair.conversationId, { type: "photo", media_ids: [elsewhere.id] })).status).toBe(404); // not even a member
    expect((await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [elsewhere.id] })).status).toBe(400);
    expect((await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [987654321] })).status).toBe(400);

    const rows = await db<{ message_id: number | null }[]>`SELECT message_id FROM message_media WHERE id IN (${theirs.id}, ${elsewhere.id})`;
    expect(rows.map((r) => r.message_id)).toEqual([null, null]);
  });

  test("a failed send does not half-attach: media stays free for a correct retry", async () => {
    const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
    const bad = await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [photo.id, 987654321] });
    expect(bad.status).toBe(400);
    const [row] = await db<{ message_id: number | null }[]>`SELECT message_id FROM message_media WHERE id = ${photo.id}`;
    expect(row?.message_id).toBeNull();
    expect((await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [photo.id] })).status).toBe(200);
  });

  test("more than ten photos, empty text, unknown type, bad client_id", async () => {
    expect((await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: Array.from({ length: 11 }, (_, i) => i + 1) })).status).toBe(400);
    expect((await send(pair.a.token, pair.conversationId, { content: "   " })).status).toBe(400);
    expect((await send(pair.a.token, pair.conversationId, { content: "x", type: "video" })).status).toBe(400);
    expect((await send(pair.a.token, pair.conversationId, { content: "x", client_id: "has space" })).status).toBe(400);
    expect((await send(pair.a.token, pair.conversationId, { content: "x".repeat(4001) })).status).toBe(400);
  });

  test("blocked in either direction: no message", async () => {
    const blocked = await makeMatch("blocked");
    await db`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${blocked.b.id}, ${blocked.a.id})`;
    expect((await send(blocked.a.token, blocked.conversationId, { content: "hello" })).status).toBe(403);
    expect((await send(blocked.b.token, blocked.conversationId, { content: "hello" })).status).toBe(403);
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${blocked.conversationId}`;
    expect(n).toBe("0");
  });
});

describe("reactions", () => {
  let pair: Pair;
  let message: ApiMessage;
  beforeAll(async () => {
    pair = await makeMatch("react");
    message = await sendText(pair.a.token, pair.conversationId, "réagis");
  });

  const react = async (token: string, emoji: string) => {
    const res = await post(token, `/api/messages/${message.id}/reactions`, { emoji });
    return { status: res.status, body: (await res.json()) as { success: boolean; reactions: Array<{ emoji: string; user_ids: number[] }> } };
  };

  test("toggle on, the same twice removes it", async () => {
    expect((await react(pair.b.token, "❤️")).body.reactions).toEqual([{ emoji: "❤️", user_ids: [pair.b.id] }]);
    expect((await react(pair.b.token, "❤️")).body.reactions).toEqual([]);
  });

  test("one reaction per member: another emoji replaces; both members can react", async () => {
    await react(pair.b.token, "😂");
    const both = (await react(pair.a.token, "😂")).body.reactions;
    expect(both).toEqual([{ emoji: "😂", user_ids: [pair.a.id, pair.b.id].sort((x, y) => x - y) }]);
    const swapped = (await react(pair.b.token, "👍")).body.reactions;
    expect(swapped).toEqual([{ emoji: "😂", user_ids: [pair.a.id] }, { emoji: "👍", user_ids: [pair.b.id] }]);
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_reactions WHERE message_id = ${message.id} AND user_id = ${pair.b.id}`;
    expect(n).toBe("1");
  });

  test("history shows the reactions", async () => {
    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.a.token) })).json()) as { messages: ApiMessage[] };
    expect(listed.messages[0]!.reactions.map((r) => r.emoji).sort()).toEqual(["👍", "😂"].sort());
  });

  test("only the six allowed emoji", async () => {
    for (const emoji of ["🔥", "❤", "x"]) expect((await react(pair.b.token, emoji)).status).toBe(400);
    expect((await post(pair.b.token, `/api/messages/${message.id}/reactions`, {})).status).toBe(400);
  });
});

describe("unsend", () => {
  test("the author, within 15 minutes: emptied, media files deleted, reactions gone", async () => {
    const pair = await makeMatch("unsend");
    const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(80, 80, 1) });
    const { body } = await send(pair.a.token, pair.conversationId, { type: "photo", content: "légende secrète", media_ids: [photo.id] });
    const message = body.message!;
    await post(pair.b.token, `/api/messages/${message.id}/reactions`, { emoji: "❤️" });
    const [{ storage_key }] = await db<{ storage_key: string }[]>`SELECT storage_key FROM message_media WHERE id = ${photo.id}`;
    const path = `${process.env.UPLOADS_DIR ?? "uploads"}/${storage_key}`;
    expect(await Bun.file(path).exists()).toBe(true);

    const res = await post(pair.a.token, `/api/messages/${message.id}/unsend`);
    expect(res.status).toBe(200);
    const view = ((await res.json()) as { message: ApiMessage }).message;
    expect(view).toMatchObject({ unsent: true, content: "", media: [], voice: null, link_preview: null, reactions: [] });

    expect(await Bun.file(path).exists()).toBe(false);
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_media WHERE message_id = ${message.id}`;
    expect(n).toBe("0");
    const [stored] = await db<{ content: string }[]>`SELECT content FROM messages WHERE id = ${message.id}`;
    expect(stored?.content).toBe("");

    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.b.token) })).json()) as { messages: ApiMessage[] };
    expect(listed.messages[0]).toMatchObject({ id: message.id, unsent: true, content: "" });
  });

  test("the recipient cannot unsend (403), nobody can react to an unsent message", async () => {
    const pair = await makeMatch("unsend2");
    const message = await sendText(pair.a.token, pair.conversationId, "x");
    expect((await post(pair.b.token, `/api/messages/${message.id}/unsend`)).status).toBe(403);
    await post(pair.a.token, `/api/messages/${message.id}/unsend`);
    expect((await post(pair.b.token, `/api/messages/${message.id}/reactions`, { emoji: "❤️" })).status).toBe(404);
  });

  test("a second unsend is harmless", async () => {
    const pair = await makeMatch("unsend3");
    const message = await sendText(pair.a.token, pair.conversationId, "x");
    expect((await post(pair.a.token, `/api/messages/${message.id}/unsend`)).status).toBe(200);
    expect((await post(pair.a.token, `/api/messages/${message.id}/unsend`)).status).toBe(200);
  });

  test("after 15 minutes it is refused (409), just before it is allowed", async () => {
    const pair = await makeMatch("unsend4");
    const late = await sendText(pair.a.token, pair.conversationId, "trop tard");
    const fine = await sendText(pair.a.token, pair.conversationId, "juste à temps");
    // Backdate through the database: the clock of the server is real.
    await db`UPDATE messages SET created_at = NOW() - INTERVAL '15 minutes 30 seconds' WHERE id = ${late.id}`;
    await db`UPDATE messages SET created_at = NOW() - INTERVAL '14 minutes 30 seconds' WHERE id = ${fine.id}`;

    const refused = await post(pair.a.token, `/api/messages/${late.id}/unsend`);
    expect(refused.status).toBe(409);
    expect(((await refused.json()) as { error: string }).error).toBe("too_late");
    const [kept] = await db<{ unsent_at: Date | null; content: string }[]>`SELECT unsent_at, content FROM messages WHERE id = ${late.id}`;
    expect(kept?.unsent_at).toBeNull();
    expect(kept?.content).toBe("trop tard");

    expect((await post(pair.a.token, `/api/messages/${fine.id}/unsend`)).status).toBe(200);
  });

  test("the conversation list shows 'Message retiré' / 'Photo' / 'Message vocal' as the last message", async () => {
    const pair = await makeMatch("lastmsg");
    const last = async () => {
      const listed = (await (await fetch(`${BASE_URL}/api/conversations`, { headers: auth(pair.b.token) })).json()) as { conversations: Array<{ id: number; lastMessage: string }> };
      return listed.conversations.find((c) => c.id === pair.conversationId)?.lastMessage;
    };
    await sendText(pair.a.token, pair.conversationId, "bonjour");
    expect(await last()).toBe("bonjour");
    const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
    const sent = await send(pair.a.token, pair.conversationId, { type: "photo", content: "légende", media_ids: [photo.id] });
    expect(await last()).toBe("Photo");
    const voice = await uploadOk(pair.a.token, pair.conversationId, { kind: "voice", file: VOICE_FIXTURE, durationMs: 1000, waveform: WAVEFORM });
    await send(pair.a.token, pair.conversationId, { type: "voice", media_ids: [voice.id] });
    expect(await last()).toBe("Message vocal");
    const lastVoice = await db<{ id: number }[]>`SELECT id FROM messages WHERE conversation_id = ${pair.conversationId} ORDER BY id DESC LIMIT 1`;
    await post(pair.a.token, `/api/messages/${lastVoice[0]!.id}/unsend`);
    expect(await last()).toBe("Message retiré");
    expect(sent.body.message!.type).toBe("photo");
  });
});

describe("read receipts", () => {
  test("up_to_id marks what the caller received, up to that message, and sets read_at", async () => {
    const pair = await makeMatch("read");
    const m1 = await sendText(pair.a.token, pair.conversationId, "1");
    const m2 = await sendText(pair.a.token, pair.conversationId, "2");
    const m3 = await sendText(pair.a.token, pair.conversationId, "3");
    const own = await sendText(pair.b.token, pair.conversationId, "réponse");

    const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: json(pair.b.token), body: JSON.stringify({ up_to_id: m2.id }) });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; up_to_id: number; read_at: string };
    expect(body.up_to_id).toBe(m2.id);
    expect(Number.isNaN(Date.parse(body.read_at))).toBe(false);

    const rows = await db<{ id: number; read_at: Date | null; is_read: boolean }[]>`SELECT id, read_at, is_read FROM messages WHERE conversation_id = ${pair.conversationId} ORDER BY id`;
    expect(rows.map((r) => [r.id, r.read_at !== null, r.is_read])).toEqual([
      [m1.id, true, true], [m2.id, true, true], [m3.id, false, false], [own.id, false, false],
    ]);

    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.a.token) })).json()) as { messages: ApiMessage[] };
    expect(listed.messages.find((m) => m.id === m1.id)!.read_at).not.toBeNull();
    expect(listed.messages.find((m) => m.id === m3.id)!.read_at).toBeNull();
  });

  test("an old app calling PUT /read with no body marks everything", async () => {
    const pair = await makeMatch("read2");
    await sendText(pair.a.token, pair.conversationId, "1");
    await sendText(pair.a.token, pair.conversationId, "2");
    const res = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: auth(pair.b.token) });
    expect(res.status).toBe(200);
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${pair.conversationId} AND read_at IS NULL`;
    expect(n).toBe("0");
  });

  test("a bad up_to_id is a 400; the author's own messages are never marked by themselves", async () => {
    const pair = await makeMatch("read3");
    await sendText(pair.a.token, pair.conversationId, "mine");
    const bad = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: json(pair.a.token), body: JSON.stringify({ up_to_id: "abc" }) });
    expect(bad.status).toBe(400);
    await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/read`, { method: "PUT", headers: json(pair.a.token), body: "{}" });
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ${pair.conversationId} AND read_at IS NOT NULL`;
    expect(n).toBe("0");
  });
});

describe("report", () => {
  test("writes a row in `reports` that points at the message and at its author", async () => {
    const pair = await makeMatch("report");
    const message = await sendText(pair.a.token, pair.conversationId, "propos déplacé");
    const res = await post(pair.b.token, `/api/messages/${message.id}/report`, { reason: "harassment", details: "il insiste" });
    expect(res.status).toBe(200);
    const rows = await db<{ reporter_id: number; reported_user_id: number; reason: string; details: string | null; message_id: number; status: string }[]>`
      SELECT reporter_id, reported_user_id, reason, details, message_id, status FROM reports WHERE message_id = ${message.id}`;
    expect(rows).toEqual([{ reporter_id: pair.b.id, reported_user_id: pair.a.id, reason: "harassment", details: "il insiste", message_id: message.id, status: "pending" }]);

    // the same reporter twice is one report
    expect((await post(pair.b.token, `/api/messages/${message.id}/report`, { reason: "harassment" })).status).toBe(200);
    const [{ n }] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM reports WHERE message_id = ${message.id}`;
    expect(n).toBe("1");
  });

  test("your own message cannot be reported; a missing reason is a 400", async () => {
    const pair = await makeMatch("report2");
    const message = await sendText(pair.a.token, pair.conversationId, "x");
    expect((await post(pair.a.token, `/api/messages/${message.id}/report`, { reason: "spam" })).status).toBe(400);
    expect((await post(pair.b.token, `/api/messages/${message.id}/report`, {})).status).toBe(400);
  });

  test("a reported message that is then unsent keeps its text for moderation, but not for the app", async () => {
    const pair = await makeMatch("report4");
    const message = await sendText(pair.a.token, pair.conversationId, "preuve");
    await post(pair.b.token, `/api/messages/${message.id}/report`, { reason: "harassment" });
    const res = await post(pair.a.token, `/api/messages/${message.id}/unsend`);
    expect(((await res.json()) as { message: ApiMessage }).message.content).toBe("");
    const [stored] = await db<{ content: string; unsent_at: Date | null }[]>`SELECT content, unsent_at FROM messages WHERE id = ${message.id}`;
    expect(stored?.content).toBe("preuve");
    expect(stored?.unsent_at).not.toBeNull();
  });
});
