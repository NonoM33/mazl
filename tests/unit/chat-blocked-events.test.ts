import { beforeEach, describe, expect, test } from "bun:test";
import { createChatService, type ChatService } from "../../src/features/chat/application/chat-service";
import { createLinkPreviewService } from "../../src/features/chat/application/link-preview-service";
import { createMessagePresenter } from "../../src/features/chat/application/message-presenter";
import type { MessageRecord } from "../../src/features/chat/domain/types";
import { FakeFetcher, FakeImages, FakeMessageRepository, FakePreviewCache, FakeStorage, RecordingEvents, T0, htmlPage, RecordingNotifier } from "./chat-fakes";

// Security: a block cuts every signal between the two people. Typing and read
// receipts say "I am here, I saw your message": they must not cross a block,
// whoever blocked whom.

const ALICE = 1;
const BOB = 2;
const CONV = 10;

let repo: FakeMessageRepository;
let events: RecordingEvents;
let service: ChatService;
let clock: Date;

beforeEach(() => {
  repo = new FakeMessageRepository();
  repo.addConversation(CONV, ALICE, BOB);
  events = new RecordingEvents();
  clock = new Date(T0.getTime() + 60_000);
  const presenter = createMessagePresenter({ repository: repo, signUrl: (id) => `https://signed.example/m/${id}` });
  service = createChatService({
    repository: repo, presenter, events, storage: new FakeStorage(), now: () => clock, previews: { schedule: () => undefined }, notifier: new RecordingNotifier(),
  });
});

describe("typing", () => {
  test("is relayed between people who are not blocked (control)", async () => {
    await service.relayTyping(ALICE, CONV, true);
    expect(events.ofType("chat:typing")).toHaveLength(1);
  });

  test("the blocker's typing never reaches the person they blocked", async () => {
    repo.blocked.add(`${ALICE}:${BOB}`);
    await service.relayTyping(ALICE, CONV, true);
    expect(events.sent).toEqual([]);
  });

  test("the blocked person's typing never reaches the blocker", async () => {
    repo.blocked.add(`${ALICE}:${BOB}`);
    await service.relayTyping(BOB, CONV, true);
    expect(events.sent).toEqual([]);
  });
});

describe("read receipts", () => {
  async function aliceWritesThenBobBlocksAlice(): Promise<void> {
    await service.send(ALICE, CONV, { content: "avant" });
    events.sent.length = 0;
    repo.blocked.add(`${BOB}:${ALICE}`);
  }

  test("reading a message of someone you blocked emits no chat:read to anyone", async () => {
    await aliceWritesThenBobBlocksAlice();
    await service.markRead(BOB, CONV, null);
    expect(events.ofType("chat:read")).toEqual([]);
    expect(events.sent).toEqual([]);
  });

  test("and does not stamp read_at, which the blocked sender could still fetch", async () => {
    await aliceWritesThenBobBlocksAlice();
    expect(await service.markRead(BOB, CONV, null)).toBeNull();
    expect(repo.messages.map((m) => m.readAt)).toEqual([null]);
  });

  test("it is the same when the BLOCKED person reads what the blocker wrote earlier", async () => {
    await service.send(BOB, CONV, { content: "avant" });
    events.sent.length = 0;
    repo.blocked.add(`${BOB}:${ALICE}`);
    await service.markRead(ALICE, CONV, null);
    expect(events.sent).toEqual([]);
    expect(repo.messages.map((m) => m.readAt)).toEqual([null]);
  });
});

describe("message updates", () => {
  test("unsending after a block updates the author's own devices only", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "oups" });
    events.sent.length = 0;
    repo.blocked.add(`${BOB}:${ALICE}`);
    await service.unsend(ALICE, message.id);
    expect(repo.messages[0]?.unsentAt).not.toBeNull();
    expect(events.ofType("chat:updated").map((e) => e.to)).toEqual([[ALICE]]);
  });

  test("unsending between people who are not blocked still tells both (control)", async () => {
    const { message } = await service.send(ALICE, CONV, { content: "oups" });
    events.sent.length = 0;
    await service.unsend(ALICE, message.id);
    expect(events.ofType("chat:updated")[0]?.to.sort()).toEqual([ALICE, BOB]);
  });

  test("a link preview that arrives after a block goes to the sender only", async () => {
    const page = "https://news.example/a";
    const outcome = await repo.insert({ conversationId: CONV, senderId: ALICE, clientId: null, type: "text", content: page, replyToId: null, mediaIds: [] });
    const message: MessageRecord = (() => { if (outcome.kind !== "created") throw new Error("setup"); return outcome.message; })();
    repo.blocked.add(`${BOB}:${ALICE}`);
    const previews = createLinkPreviewService({
      fetcher: new FakeFetcher({ [page]: htmlPage('<meta property="og:title" content="T">') }),
      images: new FakeImages(), storage: new FakeStorage(), cache: new FakePreviewCache(), repository: repo, events, now: () => clock,
      presenter: createMessagePresenter({ repository: repo, signUrl: (id) => `https://signed.example/m/${id}` }),
      runInBackground: () => undefined,
    });
    await previews.run(message);
    expect(events.ofType("chat:updated").map((e) => e.to)).toEqual([[ALICE]]);
  });
});
