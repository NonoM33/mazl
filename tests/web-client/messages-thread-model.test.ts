import { describe, expect, test } from "bun:test";
import type { MessageView } from "../../web/src/shared/api/types";
import {
  applyRead, buildRows, canUnsend, lastSeenMessageId, mergeIncoming, mergePage, optimisticMessage, scamCandidates, toggleReaction,
  UNSEND_WINDOW_MS, type ThreadMessage,
} from "../../web/src/features/messages/thread-model";

const ME = 1;
const OTHER = 2;
const base = new Date("2026-10-20T10:00:00Z").getTime();

function view(id: number, sender: number, minutes: number, extra: Partial<MessageView> = {}): MessageView {
  return {
    id, conversation_id: 9, sender_id: sender, client_id: null, type: "text", content: `m${id}`, media: [], voice: null, reply_to: null,
    reactions: [], link_preview: null, created_at: new Date(base + minutes * 60_000).toISOString(), read_at: null, unsent: false, ...extra,
  };
}
const sent = (v: MessageView): ThreadMessage => ({ view: v, state: "sent" });

describe("grouping", () => {
  test("same sender within 3 minutes is one group, a longer gap or another sender starts a new one", () => {
    const rows = buildRows([sent(view(1, OTHER, 0)), sent(view(2, OTHER, 2)), sent(view(3, OTHER, 4)), sent(view(4, ME, 4.5)), sent(view(5, OTHER, 5))], new Date(base));
    const messages = rows.filter((row) => row.kind === "message");
    expect(messages.map((row) => (row.kind === "message" ? row.position : ""))).toEqual(["first", "middle", "last", "single", "single"]);
  });

  test("exactly 3 minutes apart is a new group", () => {
    const rows = buildRows([sent(view(1, OTHER, 0)), sent(view(2, OTHER, 3))], new Date(base));
    expect(rows.filter((row) => row.kind === "message").map((row) => (row.kind === "message" ? row.position : ""))).toEqual(["single", "single"]);
  });

  test("a day separator comes first and between days, and cuts a group at midnight", () => {
    const late = view(1, OTHER, 0, { created_at: new Date(2026, 9, 20, 23, 59).toISOString() });
    const early = view(2, OTHER, 0, { created_at: new Date(2026, 9, 21, 0, 1).toISOString() });
    const rows = buildRows([sent(late), sent(early)], new Date(2026, 9, 21, 12));
    expect(rows.map((row) => row.kind)).toEqual(["day", "message", "day", "message"]);
    expect(rows[2]?.kind === "day" && rows[2].label).toBe("Aujourd'hui");
  });
});

describe("optimistic / server / realtime merge", () => {
  test("the server message replaces the local one with the same client_id", () => {
    const local = optimisticMessage({ clientId: "c-1", conversationId: 9, senderId: ME, content: "Salut", replyTo: null });
    const merged = mergeIncoming([local], view(10, ME, 1, { client_id: "c-1", content: "Salut" }));
    expect(merged).toHaveLength(1);
    expect(merged[0]?.state).toBe("sent");
    expect(merged[0]?.view.id).toBe(10);
  });

  test("the same message arriving by REST then by the socket appears once", () => {
    const v = view(10, ME, 1, { client_id: "c-1" });
    const once = mergeIncoming([], v);
    expect(mergeIncoming(once, v)).toHaveLength(1);
  });

  test("an update (reactions, link preview) replaces by id", () => {
    const updated = mergeIncoming([sent(view(10, OTHER, 1))], view(10, OTHER, 1, { reactions: [{ emoji: "❤️", user_ids: [ME] }] }));
    expect(updated).toHaveLength(1);
    expect(updated[0]?.view.reactions).toHaveLength(1);
  });

  test("local messages stay after server ones and two local ids never collide", () => {
    const a = optimisticMessage({ clientId: "a", conversationId: 9, senderId: ME, content: "a", replyTo: null });
    const b = optimisticMessage({ clientId: "b", conversationId: 9, senderId: ME, content: "b", replyTo: null });
    expect(a.view.id).not.toBe(b.view.id);
    const merged = mergeIncoming([a, b], view(5, OTHER, 9999));
    expect(merged.map((item) => item.view.id)).toEqual([5, a.view.id, b.view.id]);
  });

  test("an older page is merged without duplicates, in order", () => {
    const merged = mergePage([sent(view(3, OTHER, 3)), sent(view(4, OTHER, 4))], [view(4, OTHER, 4), view(2, OTHER, 2), view(1, OTHER, 1)]);
    expect(merged.map((item) => item.view.id)).toEqual([1, 2, 3, 4]);
  });
});

describe("read receipts", () => {
  test("« Vu » goes under the last of my messages that was read", () => {
    const items = applyRead([sent(view(1, ME, 0)), sent(view(2, ME, 1)), sent(view(3, OTHER, 2)), sent(view(4, ME, 3))], { upToId: 2, readAt: "2026-10-20T10:05:00Z", readerId: OTHER });
    expect(lastSeenMessageId(items, ME)).toBe(2);
    expect(items.find((item) => item.view.id === 4)?.view.read_at).toBeNull();
  });
});

describe("reactions", () => {
  test("react, react again removes, another emoji replaces mine", () => {
    const first = toggleReaction([], "❤️", ME);
    expect(first).toEqual([{ emoji: "❤️", user_ids: [ME] }]);
    expect(toggleReaction(first, "❤️", ME)).toEqual([]);
    expect(toggleReaction(first, "👍", ME)).toEqual([{ emoji: "👍", user_ids: [ME] }]);
  });

  test("the other member's reaction is kept", () => {
    const start = [{ emoji: "❤️", user_ids: [OTHER] }];
    expect(toggleReaction(start, "❤️", ME)).toEqual([{ emoji: "❤️", user_ids: [OTHER, ME] }]);
    expect(toggleReaction(toggleReaction(start, "❤️", ME), "❤️", ME)).toEqual(start);
  });
});

describe("unsend window", () => {
  const mine = view(7, ME, 0);
  const at = (ms: number) => new Date(base + ms);
  test("allowed under 15 minutes, refused from 15 minutes", () => {
    expect(canUnsend(mine, ME, at(UNSEND_WINDOW_MS - 1))).toBe(true);
    expect(canUnsend(mine, ME, at(UNSEND_WINDOW_MS))).toBe(false);
  });
  test("never for the other member's message, nor an already unsent one", () => {
    expect(canUnsend(view(8, OTHER, 0), ME, at(1000))).toBe(false);
    expect(canUnsend(view(9, ME, 0, { unsent: true }), ME, at(1000))).toBe(false);
  });
});

describe("scam candidates", () => {
  test("only received text messages are judged", () => {
    const ranks = scamCandidates([sent(view(1, OTHER, 0)), sent(view(2, ME, 1)), sent(view(3, OTHER, 2, { unsent: true, content: "" })), sent(view(4, OTHER, 3, { type: "photo" }))], ME, false, 20);
    expect([...ranks.keys()]).toEqual([1]);
  });
  test("with older pages unloaded, the rank is unknown and counts as late", () => {
    expect(scamCandidates([sent(view(1, OTHER, 0))], ME, true, 20).get(1)).toBe(20);
  });
});
