import { beforeEach, describe, expect, test } from "bun:test";
import { createChatService, type ChatService } from "../../src/features/chat/application/chat-service";
import { createMessagePresenter } from "../../src/features/chat/application/message-presenter";
import { receiptKey, type ReadReceiptVisibility } from "../../src/features/chat/application/ports";
import { FakeMessageRepository, FakeStorage, RecordingEvents, RecordingNotifier, T0 } from "./chat-fakes";

// docs/premium/MONETISATION.md section 4: the author of a message sees that it
// was read only when they are mazl+ AND the reader keeps their receipts on.
// The read time is stored in any case; only what the server hands out changes.

const ALICE = 1;
const BOB = 2;
const CONV = 10;

let repo: FakeMessageRepository;
let events: RecordingEvents;
let plus: Set<number>;
let receiptsOff: Set<number>;
let service: ChatService;

// The rule of the Postgres adapter, over the in-memory conversation.
const visibility: ReadReceiptVisibility = {
  async authorsWhoMaySee(pairs) {
    const allowed = new Set<string>();
    for (const pair of pairs) {
      const conversation = repo.conversations.get(pair.conversationId);
      if (conversation === undefined) continue;
      const reader = conversation.user1Id === pair.authorId ? conversation.user2Id : conversation.user1Id;
      if (plus.has(pair.authorId) && !receiptsOff.has(reader)) allowed.add(receiptKey(pair.conversationId, pair.authorId));
    }
    return allowed;
  },
};

beforeEach(() => {
  repo = new FakeMessageRepository();
  repo.addConversation(CONV, ALICE, BOB);
  events = new RecordingEvents();
  plus = new Set();
  receiptsOff = new Set();
  const clock = new Date(T0.getTime() + 60_000);
  service = createChatService({
    repository: repo,
    presenter: createMessagePresenter({ repository: repo, signUrl: (id) => `https://signed.example/m/${id}`, receipts: visibility }),
    events, storage: new FakeStorage(), now: () => clock, previews: { schedule: () => undefined }, notifier: new RecordingNotifier(), receipts: visibility,
  });
});

async function aliceWritesBobReads() {
  const sent = await service.send(ALICE, CONV, { clientId: "c-1", content: "Shabbat shalom" });
  await service.markRead(BOB, CONV, null);
  return sent.message.id;
}

async function aliceSees() {
  const { messages } = await service.listMessages(ALICE, CONV, { before: null, limit: null });
  return messages[0];
}

describe("what the author is given", () => {
  test("a free author never sees « read », even when it was read", async () => {
    await aliceWritesBobReads();
    const view = await aliceSees();
    expect([view?.read_at, view?.is_read]).toEqual([null, false]);
    // The truth is kept for the day the author subscribes.
    expect(repo.messages[0]?.readAt).not.toBeNull();
  });

  test("a mazl+ author sees the time, when the reader keeps receipts on", async () => {
    plus.add(ALICE);
    await aliceWritesBobReads();
    const view = await aliceSees();
    expect(view?.read_at).toBe(new Date(T0.getTime() + 60_000).toISOString());
    expect(view?.is_read).toBe(true);
  });

  test("a mazl+ author sees nothing when the reader turned receipts off", async () => {
    plus.add(ALICE);
    receiptsOff.add(BOB);
    await aliceWritesBobReads();
    const view = await aliceSees();
    expect([view?.read_at, view?.is_read]).toEqual([null, false]);
  });

  test("a reader's own switch protects them even from their own mazl+: it is about THEIR reading", async () => {
    plus.add(ALICE);
    plus.add(BOB);
    receiptsOff.add(ALICE);
    // Bob writes, Alice reads with her receipts off: Bob (mazl+) sees nothing.
    const sent = await service.send(BOB, CONV, { clientId: "c-2", content: "Bonjour" });
    await service.markRead(ALICE, CONV, null);
    const { messages } = await service.listMessages(BOB, CONV, { before: null, limit: null });
    expect(messages.find((m) => m.id === sent.message.id)?.read_at).toBeNull();
  });

  test("an unsend or a reaction does not give it away either", async () => {
    const id = await aliceWritesBobReads();
    const reactions = await service.toggleReaction(BOB, id, "❤️");
    expect(reactions.length).toBe(1);
    const updates = events.ofType("chat:updated");
    expect(JSON.stringify(updates)).not.toContain('"read_at":"2');
    const unsent = await service.unsend(ALICE, id);
    expect([unsent.read_at, unsent.is_read]).toEqual([null, false]);
  });
});

describe("the chat:read event", () => {
  test("the reader's devices are told so that their marks clear; a free author is not", async () => {
    await aliceWritesBobReads();
    const [read] = events.ofType("chat:read");
    expect(read?.to).toEqual([BOB]);
  });

  test("a mazl+ author is told, when the reader keeps receipts on", async () => {
    plus.add(ALICE);
    await aliceWritesBobReads();
    expect(events.ofType("chat:read")[0]?.to.sort()).toEqual([ALICE, BOB]);
  });

  test("a mazl+ author is not told when the reader turned receipts off", async () => {
    plus.add(ALICE);
    receiptsOff.add(BOB);
    await aliceWritesBobReads();
    expect(events.ofType("chat:read")[0]?.to).toEqual([BOB]);
  });

  test("the messages carried by the event for the author never include a hidden read time", async () => {
    await aliceWritesBobReads();
    expect(JSON.stringify(events.sent.filter((e) => e.to.includes(ALICE)))).not.toContain("read_at\":\"2");
  });
});
