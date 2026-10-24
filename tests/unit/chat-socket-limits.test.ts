import { beforeEach, describe, expect, test } from "bun:test";
import type { ChatService } from "../../src/features/chat/application/chat-service";
import { createChatLimits, type ChatLimits } from "../../src/features/chat/application/chat-limits";
import { createChatSocketHandlers, type ChatSocketHandlers } from "../../src/features/chat/presentation/socket-handlers";

// Security: a connected account must not be able to flood the server through the
// WebSocket (chat:send writes to the database, typing and read fan out events).

const ALICE = 1;
const BOB = 2;
const CONV = 10;

class RecordingChat {
  readonly sends: Array<{ userId: number; content: string | undefined }> = [];
  readonly typings: number[] = [];
  readonly reads: number[] = [];
  async send(userId: number, _conversationId: number, input: { content?: string | undefined }) {
    this.sends.push({ userId, content: input.content });
    return { created: true, message: {} };
  }
  async relayTyping(userId: number) { this.typings.push(userId); }
  async markRead(userId: number) { this.reads.push(userId); return null; }
}

let clock: number;
let chat: RecordingChat;
let limits: ChatLimits;
let handlers: ChatSocketHandlers;

beforeEach(() => {
  clock = 1_000_000;
  chat = new RecordingChat();
  limits = createChatLimits(() => clock);
  handlers = createChatSocketHandlers(chat as unknown as ChatService, limits);
});

const sendFrame = (content: string, id = 0) => ({ conversationId: CONV, content, clientId: `c-${id}` });

describe("chat:send content size", () => {
  test("a frame carrying 5001 characters is dropped before it reaches the service", async () => {
    await handlers.send(ALICE, sendFrame("x".repeat(5001)));
    expect(chat.sends).toEqual([]);
  });

  test("a frame carrying a megabyte of text is dropped", async () => {
    await handlers.send(ALICE, sendFrame("x".repeat(1_000_000)));
    expect(chat.sends).toEqual([]);
  });

  test("5000 characters, the REST bound, still go through", async () => {
    await handlers.send(ALICE, sendFrame("x".repeat(5000)));
    expect(chat.sends).toHaveLength(1);
  });
});

describe("chat:send rate", () => {
  test("a user firing 500 frames in one minute gets exactly 90 of them processed", async () => {
    for (let i = 0; i < 500; i++) await handlers.send(ALICE, sendFrame("hello", i));
    expect(chat.sends).toHaveLength(90);
  });

  test("the window slides: the quota is back a minute later", async () => {
    for (let i = 0; i < 90; i++) await handlers.send(ALICE, sendFrame("hello", i));
    await handlers.send(ALICE, sendFrame("refused"));
    expect(chat.sends).toHaveLength(90);
    clock += 60_001;
    await handlers.send(ALICE, sendFrame("allowed again"));
    expect(chat.sends).toHaveLength(91);
  });

  test("one user's flood does not use another user's quota", async () => {
    for (let i = 0; i < 200; i++) await handlers.send(ALICE, sendFrame("spam", i));
    await handlers.send(BOB, sendFrame("hi"));
    expect(chat.sends.filter((s) => s.userId === BOB)).toHaveLength(1);
  });

  test("REST and WebSocket sends draw from the same quota", async () => {
    for (let i = 0; i < 60; i++) expect(limits.send.attempt(ALICE).allowed).toBe(true);
    for (let i = 0; i < 100; i++) await handlers.send(ALICE, sendFrame("via ws", i));
    expect(chat.sends).toHaveLength(30);
    expect(limits.send.attempt(ALICE).allowed).toBe(false);
  });

  test("invalid frames count too: garbage cannot be used to burn CPU for free", async () => {
    for (let i = 0; i < 90; i++) await handlers.send(ALICE, { nonsense: i });
    await handlers.send(ALICE, sendFrame("valid but too late"));
    expect(chat.sends).toEqual([]);
  });
});

describe("chat:typing and chat:read rate", () => {
  test("500 typing frames in a minute: 60 are relayed", async () => {
    for (let i = 0; i < 500; i++) await handlers.typing(ALICE, { conversationId: CONV, isTyping: true });
    expect(chat.typings).toHaveLength(60);
  });

  test("500 read frames in a minute: 60 are processed", async () => {
    for (let i = 0; i < 500; i++) await handlers.read(ALICE, { conversationId: CONV, upToId: i + 1 });
    expect(chat.reads).toHaveLength(60);
  });

  test("typing, read and send have their own budgets", async () => {
    for (let i = 0; i < 100; i++) await handlers.typing(ALICE, { conversationId: CONV });
    await handlers.read(ALICE, { conversationId: CONV });
    await handlers.send(ALICE, sendFrame("still allowed"));
    expect([chat.typings.length, chat.reads.length, chat.sends.length]).toEqual([60, 1, 1]);
  });

  test("the quota comes back after a minute", async () => {
    for (let i = 0; i < 100; i++) await handlers.typing(ALICE, { conversationId: CONV });
    clock += 60_001;
    await handlers.typing(ALICE, { conversationId: CONV });
    expect(chat.typings).toHaveLength(61);
  });
});
