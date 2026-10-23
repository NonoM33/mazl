import { beforeEach, describe, expect, test } from "bun:test";
import { createChatService, type ChatService } from "../../src/features/chat/application/chat-service";
import { createMessagePresenter } from "../../src/features/chat/application/message-presenter";
import { ChatError } from "../../src/features/chat/domain/errors";
import type { MessageRecord } from "../../src/features/chat/domain/types";
import { FakeMessageRepository, FakeStorage, RecordingEvents, T0 } from "./chat-fakes";

// Expectations are CONTRAT.md §0-§3, written from the contract.

const ALICE = 1;
const BOB = 2;
const EVE = 3;
const CONV = 10;

let repo: FakeMessageRepository;
let storage: FakeStorage;
let events: RecordingEvents;
let scheduled: MessageRecord[];
let clock: Date;
let service: ChatService;

beforeEach(() => {
  repo = new FakeMessageRepository();
  repo.addConversation(CONV, ALICE, BOB);
  storage = new FakeStorage();
  events = new RecordingEvents();
  scheduled = [];
  clock = new Date(T0.getTime() + 60_000);
  const presenter = createMessagePresenter({ repository: repo, signUrl: (id) => `https://signed.example/m/${id}` });
  service = createChatService({
    repository: repo, presenter, events, storage, now: () => clock,
    previews: { schedule: (m) => { scheduled.push(m); } },
  });
});

async function kind(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
    return "no error";
  } catch (error: unknown) {
    return error instanceof ChatError ? error.kind : `other: ${String(error)}`;
  }
}

describe("sending", () => {
  test("a text message reaches both members as chat:message with the §1 shape", async () => {
    const { message, created } = await service.send(ALICE, CONV, { clientId: "c-1", content: "  Salut !  " });
    expect(created).toBe(true);
    expect(message).toMatchObject({
      conversation_id: CONV, sender_id: ALICE, client_id: "c-1", type: "text", content: "Salut !",
      media: [], voice: null, reply_to: null, reactions: [], link_preview: null, read_at: null, unsent: false,
    });
    const sent = events.ofType("chat:message");
    expect(sent).toHaveLength(1);
    expect(sent[0]!.to.sort()).toEqual([ALICE, BOB]);
    expect((sent[0]!.payload as { message: { id: number } }).message.id).toBe(message.id);
  });

  test("idempotent on client_id: the second send returns the same message and emits nothing", async () => {
    const first = await service.send(ALICE, CONV, { clientId: "c-1", content: "Salut" });
    events.sent.length = 0;
    const second = await service.send(ALICE, CONV, { clientId: "c-1", content: "Salut" });
    expect(second.created).toBe(false);
    expect(second.message.id).toBe(first.message.id);
    expect(repo.messages).toHaveLength(1);
    expect(events.sent).toHaveLength(0);
    expect(scheduled).toHaveLength(0);
  });

  test("the same client_id from the other member is another message", async () => {
    const a = await service.send(ALICE, CONV, { clientId: "same", content: "a" });
    const b = await service.send(BOB, CONV, { clientId: "same", content: "b" });
    expect(b.message.id).not.toBe(a.message.id);
  });

  test("without a client_id (old app versions) two sends are two messages", async () => {
    await service.send(ALICE, CONV, { content: "x" });
    await service.send(ALICE, CONV, { content: "x" });
    expect(repo.messages).toHaveLength(2);
  });

  test("photos: up to 10, owned by the sender, in this conversation, unattached", async () => {
    const photos = Array.from({ length: 10 }, () => repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "photo" }));
    const { message } = await service.send(ALICE, CONV, { clientId: "p", type: "photo", content: "vue", mediaIds: photos.map((p) => p.id) });
    expect(message.media.map((m) => m.id)).toEqual(photos.map((p) => p.id));
    expect(message.media[0]).toMatchObject({ kind: "photo", url: expect.stringContaining("https://signed.example/m/") });
    expect(message.content).toBe("vue");

    const eleven = Array.from({ length: 11 }, () => repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "photo" }));
    expect(await kind(service.send(ALICE, CONV, { type: "photo", mediaIds: eleven.map((p) => p.id) }))).toBe("invalid");
  });

  test("a media row already used by a message cannot be attached again", async () => {
    const photo = repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "photo" });
    await service.send(ALICE, CONV, { type: "photo", mediaIds: [photo.id] });
    expect(await kind(service.send(ALICE, CONV, { type: "photo", mediaIds: [photo.id] }))).toBe("invalid");
  });

  test("a media row uploaded by the other member, or to another conversation, is refused", async () => {
    const theirs = repo.addMedia({ conversationId: CONV, uploaderId: BOB, kind: "photo" });
    expect(await kind(service.send(ALICE, CONV, { type: "photo", mediaIds: [theirs.id] }))).toBe("invalid");
    repo.addConversation(11, ALICE, EVE);
    const elsewhere = repo.addMedia({ conversationId: 11, uploaderId: ALICE, kind: "photo" });
    expect(await kind(service.send(ALICE, CONV, { type: "photo", mediaIds: [elsewhere.id] }))).toBe("invalid");
    expect(await kind(service.send(ALICE, CONV, { type: "photo", mediaIds: [9999] }))).toBe("invalid");
  });

  test("a voice message carries exactly one voice media", async () => {
    const voice = repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "voice", durationMs: 8300, waveform: [1, 2, 3] });
    const { message } = await service.send(ALICE, CONV, { type: "voice", content: "ignored", mediaIds: [voice.id] });
    expect(message.type).toBe("voice");
    expect(message.content).toBe("");
    expect(message.voice).toEqual({ id: voice.id, url: `https://signed.example/m/${voice.id}`, duration_ms: 8300, waveform: [1, 2, 3] });
    expect(message.media).toEqual([]);
    expect(await kind(service.send(ALICE, CONV, { type: "voice", mediaIds: [] }))).toBe("invalid");
  });

  const invalidShapes: Array<[string, Parameters<ChatService["send"]>[2]]> = [
    ["empty text", { content: "   " }],
    ["no content at all", {}],
    ["text over 4000 characters", { content: "x".repeat(4001) }],
    ["text with media", { content: "hi", mediaIds: [1] }],
    ["duplicate media ids", { type: "photo", mediaIds: [1, 1] }],
    ["photo without media", { type: "photo", mediaIds: [] }],
    ["voice with two media", { type: "voice", mediaIds: [1, 2] }],
  ];
  for (const [label, input] of invalidShapes) {
    test(`refuses ${label}`, async () => expect(await kind(service.send(ALICE, CONV, input))).toBe("invalid"));
  }

  test("reply_to must be a message of the same conversation", async () => {
    const root = await service.send(BOB, CONV, { content: "On se voit jeudi ?" });
    const { message } = await service.send(ALICE, CONV, { content: "Oui", replyToId: root.message.id });
    expect(message.reply_to).toEqual({ id: root.message.id, sender_id: BOB, type: "text", preview: "On se voit jeudi ?" });

    repo.addConversation(11, ALICE, EVE);
    const foreign = await service.send(ALICE, 11, { content: "autre" });
    expect(await kind(service.send(ALICE, CONV, { content: "x", replyToId: foreign.message.id }))).toBe("invalid");
    expect(await kind(service.send(ALICE, CONV, { content: "x", replyToId: 9999 }))).toBe("invalid");
  });

  test("a blocked pair cannot send", async () => {
    repo.blocked.add(`${BOB}:${ALICE}`);
    expect(await kind(service.send(ALICE, CONV, { content: "hello" }))).toBe("blocked");
    expect(repo.messages).toHaveLength(0);
  });

  test("a link preview job is scheduled for a NEW text message that has a link, only", async () => {
    await service.send(ALICE, CONV, { content: "Regarde https://example.com/a" });
    await service.send(ALICE, CONV, { content: "pas de lien" });
    const photo = repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "photo" });
    await service.send(ALICE, CONV, { type: "photo", content: "https://example.com/caption", mediaIds: [photo.id] });
    expect(scheduled.map((m) => m.content)).toEqual(["Regarde https://example.com/a"]);
  });
});

describe("only the two members", () => {
  test("every operation answers not_found to an outsider", async () => {
    const mine = await service.send(ALICE, CONV, { content: "secret" });
    const id = mine.message.id;
    const probes: Array<[string, Promise<unknown>]> = [
      ["list", service.listMessages(EVE, CONV, { before: null, limit: null })],
      ["send", service.send(EVE, CONV, { content: "intrusion" })],
      ["react", service.toggleReaction(EVE, id, "❤️")],
      ["unsend", service.unsend(EVE, id)],
      ["read", service.markRead(EVE, CONV, null)],
      ["report", service.report(EVE, id, "spam", null)],
    ];
    for (const [label, call] of probes) expect([label, await kind(call)]).toEqual([label, "not_found"]);
    expect(repo.messages).toHaveLength(1);
  });

  test("an unknown conversation or message looks the same", async () => {
    expect(await kind(service.listMessages(ALICE, 999, { before: null, limit: null }))).toBe("not_found");
    expect(await kind(service.toggleReaction(ALICE, 999, "❤️"))).toBe("not_found");
  });

  test("typing from an outsider relays nothing", async () => {
    await service.relayTyping(EVE, CONV, true);
    expect(events.sent).toHaveLength(0);
    await service.relayTyping(ALICE, CONV, true);
    expect(events.ofType("chat:typing")[0]).toMatchObject({ to: [BOB] });
  });
});

describe("pagination", () => {
  beforeEach(async () => {
    for (let i = 1; i <= 7; i++) await service.send(ALICE, CONV, { content: `m${i}` });
  });
  const contents = (page: { messages: Array<{ content: string }> }) => page.messages.map((m) => m.content);

  test("newest first, has_more while older ones remain, cursor by id", async () => {
    const first = await service.listMessages(BOB, CONV, { before: null, limit: 3 });
    expect(contents(first)).toEqual(["m7", "m6", "m5"]);
    expect(first.hasMore).toBe(true);
    const oldest = first.messages.at(-1)!.id;
    const second = await service.listMessages(BOB, CONV, { before: oldest, limit: 3 });
    expect(contents(second)).toEqual(["m4", "m3", "m2"]);
    expect(second.hasMore).toBe(true);
    const third = await service.listMessages(BOB, CONV, { before: second.messages.at(-1)!.id, limit: 3 });
    expect(contents(third)).toEqual(["m1"]);
    expect(third.hasMore).toBe(false);
  });

  test("exactly the last page has no more", async () => {
    const all = await service.listMessages(BOB, CONV, { before: null, limit: 7 });
    expect(all.messages).toHaveLength(7);
    expect(all.hasMore).toBe(false);
  });

  test("limit defaults to 30 and is clamped to 1..50", async () => {
    for (let i = 8; i <= 60; i++) await service.send(ALICE, CONV, { content: `m${i}` });
    expect((await service.listMessages(BOB, CONV, { before: null, limit: null })).messages).toHaveLength(30);
    expect((await service.listMessages(BOB, CONV, { before: null, limit: 500 })).messages).toHaveLength(50);
    expect((await service.listMessages(BOB, CONV, { before: null, limit: 0 })).messages).toHaveLength(1);
    expect((await service.listMessages(BOB, CONV, { before: null, limit: -5 })).messages).toHaveLength(1);
  });
});

describe("reactions", () => {
  test("toggle: add, same emoji removes, another emoji replaces; update event to both", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    events.sent.length = 0;
    expect(await service.toggleReaction(BOB, message.id, "❤️")).toEqual([{ emoji: "❤️", user_ids: [BOB] }]);
    expect(events.ofType("chat:updated")).toHaveLength(1);
    expect(events.ofType("chat:updated")[0]!.to.sort()).toEqual([ALICE, BOB]);
    expect(await service.toggleReaction(ALICE, message.id, "❤️")).toEqual([{ emoji: "❤️", user_ids: [ALICE, BOB] }]);
    expect(await service.toggleReaction(BOB, message.id, "😂")).toEqual([
      { emoji: "❤️", user_ids: [ALICE] }, { emoji: "😂", user_ids: [BOB] },
    ]);
    expect(await service.toggleReaction(BOB, message.id, "😂")).toEqual([{ emoji: "❤️", user_ids: [ALICE] }]);
  });

  test("only the six allowed emoji", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    for (const emoji of ["🔥", "", "❤", "<script>", "❤️❤️"]) {
      expect(await kind(service.toggleReaction(BOB, message.id, emoji))).toBe("invalid");
    }
    expect(repo.reactionRows).toHaveLength(0);
  });

  test("an unsent message cannot be reacted to", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    await service.unsend(ALICE, message.id);
    expect(await kind(service.toggleReaction(BOB, message.id, "❤️"))).toBe("not_found");
  });
});

describe("unsend", () => {
  test("the author, within 15 minutes: emptied view, files deleted, update event", async () => {
    const photo = repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "photo", storageKey: "chat/10/a.jpg" });
    storage.files.set("chat/10/a.jpg", new Uint8Array([1]));
    const { message } = await service.send(ALICE, CONV, { type: "photo", content: "légende", mediaIds: [photo.id] });
    await service.toggleReaction(BOB, message.id, "❤️");
    events.sent.length = 0;
    clock = new Date(T0.getTime() + 14 * 60_000);

    const view = await service.unsend(ALICE, message.id);
    expect(view).toMatchObject({ unsent: true, content: "", media: [], voice: null, link_preview: null, reactions: [] });
    expect(storage.files.has("chat/10/a.jpg")).toBe(false);
    expect(repo.mediaRows).toHaveLength(0);
    expect(events.ofType("chat:updated")).toHaveLength(1);
    expect(events.ofType("chat:updated")[0]!.to.sort()).toEqual([ALICE, BOB]);
    expect(repo.messages[0]!.content).toBe("");
  });

  test("the other member is refused (not_author)", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    expect(await kind(service.unsend(BOB, message.id))).toBe("not_author");
    expect(repo.messages[0]!.unsentAt).toBeNull();
  });

  test("after 15 minutes it is too late, at exactly 15 minutes it is still allowed", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    clock = new Date(T0.getTime() + 15 * 60_000);
    expect((await service.unsend(ALICE, message.id)).unsent).toBe(true);

    const late = await service.send(ALICE, CONV, { content: "y" });
    clock = new Date(T0.getTime() + 15 * 60_000 + 1);
    expect(await kind(service.unsend(ALICE, late.message.id))).toBe("too_late");
    expect(repo.messages[1]!.unsentAt).toBeNull();
  });

  test("a second unsend is a no-op that returns the same unsent view", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    await service.unsend(ALICE, message.id);
    events.sent.length = 0;
    expect((await service.unsend(ALICE, message.id)).unsent).toBe(true);
    expect(events.sent).toHaveLength(0);
  });

  test("a reply to an unsent message shows 'Message retiré' as its preview", async () => {
    const root = await service.send(BOB, CONV, { content: "texte secret" });
    const reply = await service.send(ALICE, CONV, { content: "ok", replyToId: root.message.id });
    await service.unsend(BOB, root.message.id);
    const page = await service.listMessages(ALICE, CONV, { before: null, limit: 10 });
    expect(page.messages.find((m) => m.id === reply.message.id)!.reply_to!.preview).toBe("Message retiré");
  });

  test("a failing disk removal does not fail the unsend", async () => {
    const photo = repo.addMedia({ conversationId: CONV, uploaderId: ALICE, kind: "photo", storageKey: "chat/10/stuck.jpg" });
    storage.failRemoveFor.add("chat/10/stuck.jpg");
    const { message } = await service.send(ALICE, CONV, { type: "photo", mediaIds: [photo.id] });
    expect((await service.unsend(ALICE, message.id)).unsent).toBe(true);
  });

  test("evidence is kept when the message had been reported", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "insulte" });
    await service.report(BOB, message.id, "harassment", null);
    await service.unsend(ALICE, message.id);
    expect(repo.messages[0]!.content).toBe("insulte");
    const [view] = (await service.listMessages(BOB, CONV, { before: null, limit: 5 })).messages;
    expect(view!.content).toBe(""); // never shown to the app
  });
});

describe("read receipts", () => {
  test("marks what the reader received up to up_to_id and tells both members", async () => {
    const m1 = await service.send(ALICE, CONV, { content: "1" });
    const m2 = await service.send(ALICE, CONV, { content: "2" });
    await service.send(ALICE, CONV, { content: "3" });
    events.sent.length = 0;
    const outcome = await service.markRead(BOB, CONV, m2.message.id);
    expect(outcome?.upToId).toBe(m2.message.id);
    expect(repo.messages.map((m) => m.readAt !== null)).toEqual([true, true, false]);
    const event = events.ofType("chat:read")[0]!;
    expect(event.to.sort()).toEqual([ALICE, BOB]);
    expect(event.payload).toMatchObject({ conversation_id: CONV, user_id: BOB, up_to_id: m2.message.id, read_at: clock.toISOString() });
    expect(m1.message.read_at).toBeNull();
  });

  test("own messages are not marked by their author, and a repeat emits nothing", async () => {
    await service.send(ALICE, CONV, { content: "mine" });
    events.sent.length = 0;
    expect(await service.markRead(ALICE, CONV, null)).toBeNull();
    expect(events.sent).toHaveLength(0);
    await service.markRead(BOB, CONV, null);
    events.sent.length = 0;
    expect(await service.markRead(BOB, CONV, null)).toBeNull();
    expect(events.sent).toHaveLength(0);
  });
});

describe("reports", () => {
  test("a member reports the other's message; own messages cannot be reported", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "x" });
    await service.report(BOB, message.id, "harassment", "details");
    expect(repo.reports).toEqual([{ reporterId: BOB, reportedUserId: ALICE, messageId: message.id, reason: "harassment", details: "details" }]);
    expect(await kind(service.report(ALICE, message.id, "spam", null))).toBe("invalid");
  });
});
