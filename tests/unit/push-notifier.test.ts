import { describe, expect, test } from "bun:test";
import { createPushNotifier } from "../../src/features/push/application/push-notifier";
import type { PushAudience, PushDirectory, PushMessage, PushResult, PushTransport } from "../../src/features/push/application/ports";

// The match and message pushes, from the contract of the app (V1-CONTRAT
// section 1). A fake transport records what would reach gorush: nothing here
// touches the network or a database.

class FakeTransport implements PushTransport {
  sent: PushMessage[] = [];
  enabled = true;
  next: () => Promise<PushResult> = () => Promise.resolve({ ok: true });
  isEnabled(): boolean {
    return this.enabled;
  }
  send(message: PushMessage): Promise<PushResult> {
    this.sent.push(message);
    return this.next();
  }
}

// Answers by (recipient, actor): unknown pairs are deliverable with the name of the actor.
class FakeDirectory implements PushDirectory {
  asked: Array<[number, number]> = [];
  constructor(
    private readonly names: Readonly<Record<number, string | null>>,
    private readonly refused: ReadonlySet<string> = new Set(),
  ) {}
  audience(recipientId: number, actorId: number): Promise<PushAudience> {
    this.asked.push([recipientId, actorId]);
    return Promise.resolve({ deliverable: !this.refused.has(`${recipientId}:${actorId}`), actorName: this.names[actorId] ?? null });
  }
  // A member alone is refused as "<id>:<id>".
  reachable(recipientIds: readonly number[]): Promise<number[]> {
    return Promise.resolve(recipientIds.filter((id) => !this.refused.has(`${id}:${id}`)));
  }
}

const EMOJI = /\p{Extended_Pictographic}/u;
const TUTOIEMENT = /\b(tu|toi|ton|ta|tes|t'|te)\b/i;

function setup(options: { names?: Record<number, string | null>; refused?: string[]; connected?: number[]; now?: () => number } = {}) {
  const transport = new FakeTransport();
  const directory = new FakeDirectory(options.names ?? { 1: "Sarah Cohen", 2: "Daniel Lévy" }, new Set(options.refused ?? []));
  const connected = new Set(options.connected ?? []);
  const errors: string[] = [];
  const notifier = createPushNotifier({ transport, directory, connections: { isConnected: (userId) => connected.has(userId) }, log: { error: (line) => errors.push(line) }, ...(options.now === undefined ? {} : { now: options.now }) });
  return { transport, directory, notifier, errors };
}

describe("a match forms", () => {
  test("both members are told, each with the OTHER member's id and the conversation", async () => {
    const { transport, notifier } = setup();
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    expect(transport.sent.map((push) => [push.recipientId, push.data])).toEqual([
      [1, { type: "new_match", match_user_id: 2, conversation_id: 40 }],
      [2, { type: "new_match", match_user_id: 1, conversation_id: 40 }],
    ]);
    expect(transport.sent.every((push) => push.collapseId === undefined)).toBe(true);
  });

  test("without a conversation yet, the field is absent (not null)", async () => {
    const { transport, notifier } = setup();
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: null });
    expect(transport.sent[0]?.data).toEqual({ type: "new_match", match_user_id: 2 });
    expect(Object.keys(transport.sent[0]?.data ?? {})).not.toContain("conversation_id");
  });

  test("the text names only the first name of the other member, in vouvoiement, with no emoji", async () => {
    const { transport, notifier } = setup();
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    const toSarah = transport.sent[0];
    expect(toSarah?.message).toContain("Daniel");
    expect(`${toSarah?.title} ${toSarah?.message}`).not.toContain("Lévy");
    for (const push of transport.sent) {
      expect(`${push.title} ${push.message}`).not.toMatch(EMOJI);
      expect(`${push.title} ${push.message}`).not.toMatch(TUTOIEMENT);
      expect(push.message).toMatch(/\bvous\b/i);
    }
  });

  test("a member without a display name still gets a generic text", async () => {
    const { transport, notifier } = setup({ names: { 1: null, 2: null } });
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    expect(transport.sent).toHaveLength(2);
    expect(transport.sent[0]?.message).not.toContain("null");
    expect(transport.sent[0]?.message).not.toContain("undefined");
  });

  test("a blocked, banned or inactive member (either side) triggers no notification for that pair", async () => {
    const { transport, notifier } = setup({ refused: ["1:2", "2:1"] });
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    expect(transport.sent).toEqual([]);
  });

  test("only the refused direction is skipped", async () => {
    const { transport, notifier } = setup({ refused: ["2:1"] });
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    expect(transport.sent.map((push) => push.recipientId)).toEqual([1]);
  });
});

describe("a message arrives", () => {
  test("the recipient with no open socket gets one push for the conversation, grouped by collapse id", async () => {
    const { transport, notifier } = setup();
    await notifier.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 });
    expect(transport.sent).toHaveLength(1);
    expect(transport.sent[0]).toMatchObject({ recipientId: 2, data: { type: "new_message", conversation_id: 40 }, collapseId: "conv-40" });
    expect(transport.sent[0]?.data).toEqual({ type: "new_message", conversation_id: 40 });
  });

  test("the text names the sender by first name only; vouvoiement, no emoji", async () => {
    const { transport, notifier } = setup();
    await notifier.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 });
    const push = transport.sent[0];
    expect(push?.message).toContain("Sarah");
    expect(`${push?.title} ${push?.message}`).not.toContain("Cohen");
    expect(`${push?.title} ${push?.message}`).not.toMatch(EMOJI);
    expect(`${push?.title} ${push?.message}`).not.toMatch(TUTOIEMENT);
  });

  test("a recipient with an open socket is not pushed, and the database is not even asked", async () => {
    const { transport, directory, notifier } = setup({ connected: [2] });
    await notifier.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 });
    expect(transport.sent).toEqual([]);
    expect(directory.asked).toEqual([]);
  });

  test("a blocked, banned or inactive pair triggers nothing", async () => {
    const { transport, notifier } = setup({ refused: ["2:1"] });
    await notifier.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 });
    expect(transport.sent).toEqual([]);
  });
});

describe("without gorush, or when it fails", () => {
  test("a transport that is not configured is neither called nor is the database asked", async () => {
    const { transport, directory, notifier } = setup();
    transport.enabled = false;
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    await notifier.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 });
    expect(transport.sent).toEqual([]);
    expect(directory.asked).toEqual([]);
  });

  test("a refused push is logged without a name and does not stop the other member's push", async () => {
    const { transport, notifier, errors } = setup();
    transport.next = () => Promise.resolve({ ok: false, reason: "invalid_player_ids" });
    await notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 });
    expect(transport.sent).toHaveLength(2);
    expect(errors).toHaveLength(2);
    expect(errors.join(" ")).not.toContain("Daniel");
  });

  test("a transport that throws never rejects", async () => {
    const { transport, notifier, errors } = setup();
    transport.next = () => Promise.reject(new Error("socket hang up"));
    await expect(notifier.matchFormed({ userAId: 1, userBId: 2, conversationId: 40 })).resolves.toBeUndefined();
    await expect(notifier.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 })).resolves.toBeUndefined();
    expect(errors.length).toBeGreaterThan(0);
  });

  test("a database that throws never rejects either", async () => {
    const { transport, notifier, errors } = setup();
    const failing: PushDirectory = {
      audience: () => Promise.reject(new Error("connection terminated")),
      reachable: () => Promise.reject(new Error("connection terminated")),
    };
    const broken = createPushNotifier({ transport, directory: failing, connections: { isConnected: () => false }, log: { error: (line) => errors.push(line) } });
    await expect(broken.messageReceived({ conversationId: 40, senderId: 1, recipientId: 2 })).resolves.toBeUndefined();
    await expect(broken.boostEnded(2)).resolves.toBeUndefined();
    expect(transport.sent).toEqual([]);
    expect(errors).toHaveLength(2);
  });
});

const HOUR = 3_600_000;

function expectHouseStyle(push: PushMessage | undefined): void {
  expect(push).toBeDefined();
  for (const text of [push?.title ?? "", push?.message ?? ""]) {
    expect(text).not.toMatch(EMOJI);
    expect(text).not.toMatch(TUTOIEMENT);
  }
}

describe("a like is received", () => {
  test("the member liked is told, without the name of who liked them, and the app opens the likes", async () => {
    const { transport, directory, notifier } = setup();
    await notifier.likeReceived({ likerId: 1, recipientId: 2, superLike: false });
    expect(directory.asked).toEqual([[2, 1]]);
    expect(transport.sent).toHaveLength(1);
    expect(transport.sent[0]?.recipientId).toBe(2);
    expect(transport.sent[0]?.data).toEqual({ type: "new_like" });
    expect(transport.sent[0]?.collapseId).toBe("likes");
    expect(`${transport.sent[0]?.title} ${transport.sent[0]?.message}`).not.toContain("Sarah");
    expectHouseStyle(transport.sent[0]);
  });

  test("simple likes are told at most once every six hours to the same member", async () => {
    let now = 0;
    const { transport, notifier } = setup({ now: () => now });
    await notifier.likeReceived({ likerId: 1, recipientId: 2, superLike: false });
    now = 5 * HOUR;
    await notifier.likeReceived({ likerId: 3, recipientId: 2, superLike: false });
    expect(transport.sent).toHaveLength(1);
    now = 6 * HOUR + 1;
    await notifier.likeReceived({ likerId: 4, recipientId: 2, superLike: false });
    expect(transport.sent).toHaveLength(2);
  });

  test("a super like is always told, once per sender, also within the six hours", async () => {
    const { transport, notifier } = setup({ now: () => 0 });
    await notifier.likeReceived({ likerId: 1, recipientId: 2, superLike: false });
    await notifier.likeReceived({ likerId: 3, recipientId: 2, superLike: true });
    await notifier.likeReceived({ likerId: 3, recipientId: 2, superLike: true });
    expect(transport.sent.map((push) => push.data)).toEqual([{ type: "new_like" }, { type: "super_like" }]);
    expect(transport.sent[1]?.collapseId).toBeUndefined();
    expect(`${transport.sent[1]?.title} ${transport.sent[1]?.message}`).not.toContain("Sarah");
    expectHouseStyle(transport.sent[1]);
  });

  test("a blocked pair, or a push without key, sends nothing", async () => {
    const blocked = setup({ refused: ["2:1"] });
    await blocked.notifier.likeReceived({ likerId: 1, recipientId: 2, superLike: true });
    expect(blocked.transport.sent).toEqual([]);
    const off = setup();
    off.transport.enabled = false;
    await off.notifier.likeReceived({ likerId: 1, recipientId: 2, superLike: true });
    expect(off.transport.sent).toEqual([]);
    expect(off.directory.asked).toEqual([]);
  });
});

describe("a Boost ends", () => {
  test("the member is told, and the app opens the Boost", async () => {
    const { transport, notifier } = setup();
    await notifier.boostEnded(7);
    expect(transport.sent).toHaveLength(1);
    expect(transport.sent[0]?.recipientId).toBe(7);
    expect(transport.sent[0]?.data).toEqual({ type: "boost_ended" });
    expectHouseStyle(transport.sent[0]);
  });

  test("a member who can no longer be reached is not told", async () => {
    const { transport, notifier } = setup({ refused: ["7:7"] });
    await notifier.boostEnded(7);
    expect(transport.sent).toEqual([]);
  });
});

describe("an event becomes available", () => {
  test("every reachable member of the list is told once, with the event to open", async () => {
    const { transport, notifier } = setup({ refused: ["5:5"] });
    const outcome = await notifier.eventAvailable({ eventId: 12, title: "Shabbat à Paris", recipientIds: [3, 4, 5, 3] });
    expect(transport.sent.map((push) => push.recipientId).sort()).toEqual([3, 4]);
    expect(transport.sent[0]?.data).toEqual({ type: "event_available", event_id: 12 });
    expect(transport.sent[0]?.collapseId).toBe("event-12");
    expect(transport.sent[0]?.message).toContain("Shabbat à Paris");
    expectHouseStyle(transport.sent[0]);
    expect(outcome).toEqual({ requested: 3, sent: 2, skipped: 1, failed: 0 });
  });

  test("a refusal of the provider is counted as failed, and the rest is still sent", async () => {
    const { transport, notifier, errors } = setup();
    let calls = 0;
    transport.next = () => Promise.resolve(++calls === 1 ? { ok: false, reason: "All included players are not subscribed" } : { ok: true });
    const outcome = await notifier.eventAvailable({ eventId: 1, title: "Soirée", recipientIds: [3, 4] });
    expect(outcome).toEqual({ requested: 2, sent: 1, skipped: 0, failed: 1 });
    expect(errors).toHaveLength(1);
  });

  test("a long title is cut, and without key nothing is sent nor looked up", async () => {
    const { transport, notifier } = setup();
    await notifier.eventAvailable({ eventId: 1, title: "x".repeat(300), recipientIds: [3] });
    expect(transport.sent[0]?.message.length).toBeLessThan(160);
    transport.enabled = false;
    transport.sent = [];
    const outcome = await notifier.eventAvailable({ eventId: 1, title: "Soirée", recipientIds: [3] });
    expect(outcome).toEqual({ requested: 1, sent: 0, skipped: 1, failed: 0 });
    expect(transport.sent).toEqual([]);
  });
});

describe("a test push from the administrators", () => {
  test("goes to the member as it is, and says why when it does not leave", async () => {
    const { transport, notifier } = setup();
    expect(await notifier.testPush(44)).toEqual({ ok: true });
    expect(transport.sent[0]?.recipientId).toBe(44);
    expect(transport.sent[0]?.data).toEqual({ type: "admin_test" });
    expectHouseStyle(transport.sent[0]);
    transport.next = () => Promise.resolve({ ok: false, reason: "All included players are not subscribed" });
    expect(await notifier.testPush(44)).toEqual({ ok: false, reason: "All included players are not subscribed" });
    transport.enabled = false;
    expect(await notifier.testPush(44)).toEqual({ ok: false, reason: "not_configured" });
  });
});
