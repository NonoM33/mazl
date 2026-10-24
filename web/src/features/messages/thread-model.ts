import type { MessageView } from "../../shared/api/types";
import { dayLabel } from "../../shared/lib/format";

// Pure model of a conversation thread: merging what the server says with what
// is being sent, grouping bubbles, reactions and the unsend window
// (docs/chat/CONTRAT.md, docs/design/CHAT.md).

export type SendState = "sent" | "sending" | "failed";
export interface ThreadMessage { readonly view: MessageView; readonly state: SendState }

export const GROUP_GAP_MS = 3 * 60_000;
export const UNSEND_WINDOW_MS = 15 * 60_000;
export const ALLOWED_REACTIONS = ["❤️", "😂", "😮", "😢", "🙏", "👍"] as const;
export const MAX_MESSAGE_LENGTH = 4000;

const at = (view: MessageView): number => new Date(view.created_at).getTime();
const isLocal = (item: ThreadMessage): boolean => item.state !== "sent";

function order(a: ThreadMessage, b: ThreadMessage): number {
  if (isLocal(a) !== isLocal(b)) return isLocal(a) ? 1 : -1;
  // Local ids count down (-1, -2…): the earliest send has the highest one.
  return at(a.view) - at(b.view) || (isLocal(a) ? b.view.id - a.view.id : a.view.id - b.view.id);
}

let localSequence = 0;

export function optimisticMessage(input: { clientId: string; conversationId: number; senderId: number; content: string; replyTo: MessageView["reply_to"]; now?: Date }): ThreadMessage {
  const created = (input.now ?? new Date()).toISOString();
  const view: MessageView = {
    id: -(localSequence += 1), conversation_id: input.conversationId, sender_id: input.senderId, client_id: input.clientId,
    type: "text", content: input.content, media: [], voice: null, reply_to: input.replyTo, reactions: [], link_preview: null,
    created_at: created, read_at: null, unsent: false,
  };
  return { view, state: "sending" };
}

// A server message replaces the local one with the same client_id (or the same
// id), so a message coming back by REST and by the socket appears once.
export function mergeIncoming(items: readonly ThreadMessage[], incoming: MessageView): ThreadMessage[] {
  const next: ThreadMessage = { view: incoming, state: "sent" };
  const index = items.findIndex((item) => item.view.id === incoming.id || (incoming.client_id !== null && item.view.client_id === incoming.client_id));
  const merged = index === -1 ? [...items, next] : items.map((item, position) => (position === index ? next : item));
  return merged.sort(order);
}

export function mergePage(items: readonly ThreadMessage[], page: readonly MessageView[]): ThreadMessage[] {
  return page.reduce<ThreadMessage[]>((acc, view) => mergeIncoming(acc, view), [...items]);
}

export function replaceItem(items: readonly ThreadMessage[], clientId: string, change: Partial<ThreadMessage>): ThreadMessage[] {
  return items.map((item) => (item.view.client_id === clientId ? { ...item, ...change } : item));
}

export function removeItem(items: readonly ThreadMessage[], clientId: string): ThreadMessage[] {
  return items.filter((item) => item.view.client_id !== clientId);
}

export function patchView(items: readonly ThreadMessage[], id: number, patch: Partial<MessageView>): ThreadMessage[] {
  return items.map((item) => (item.view.id === id ? { ...item, view: { ...item.view, ...patch } } : item));
}

// The other member read up to `upToId`: my messages up to there become « Vu ».
export function applyRead(items: readonly ThreadMessage[], input: { upToId: number; readAt: string; readerId: number }): ThreadMessage[] {
  return items.map((item) => {
    const { view } = item;
    if (view.sender_id === input.readerId || view.id > input.upToId || view.read_at !== null || item.state !== "sent") return item;
    return { ...item, view: { ...view, read_at: input.readAt } };
  });
}

// The last message of mine that was read: « Vu à HH:MM » goes under it only.
export function lastSeenMessageId(items: readonly ThreadMessage[], myId: number): number | null {
  for (let index = items.length - 1; index >= 0; index -= 1) {
    const view = items[index]?.view;
    if (view?.sender_id === myId && view.read_at !== null && !view.unsent) return view.id;
  }
  return null;
}

export function newestReceivedId(items: readonly ThreadMessage[], myId: number): number | null {
  for (let index = items.length - 1; index >= 0; index -= 1) {
    const item = items[index];
    if (item?.state === "sent" && item.view.sender_id !== myId) return item.view.id;
  }
  return null;
}

export type Reactions = MessageView["reactions"];

// One reaction per member: the same emoji again removes it, another emoji
// replaces the previous one.
export function toggleReaction(reactions: Reactions, emoji: string, userId: number): Reactions {
  const mine = reactions.find((reaction) => reaction.user_ids.includes(userId))?.emoji;
  const without = reactions
    .map((reaction) => ({ emoji: reaction.emoji, user_ids: reaction.user_ids.filter((id) => id !== userId) }))
    .filter((reaction) => reaction.user_ids.length > 0);
  if (mine === emoji) return without;
  const existing = without.find((reaction) => reaction.emoji === emoji);
  if (existing) return without.map((reaction) => (reaction === existing ? { emoji, user_ids: [...reaction.user_ids, userId] } : reaction));
  return [...without, { emoji, user_ids: [userId] }];
}

export function canUnsend(view: MessageView, myId: number, now: Date = new Date()): boolean {
  return view.sender_id === myId && !view.unsent && view.id > 0 && now.getTime() - at(view) < UNSEND_WINDOW_MS;
}

export type BubblePosition = "single" | "first" | "middle" | "last";
export type ThreadRow =
  | { readonly kind: "day"; readonly key: string; readonly label: string }
  | { readonly kind: "message"; readonly key: string; readonly item: ThreadMessage; readonly position: BubblePosition; readonly lastOfGroup: boolean; readonly firstOfGroup: boolean; readonly newGroup: boolean };

const sameDay = (a: Date, b: Date): boolean => a.toDateString() === b.toDateString();

function continuesGroup(previous: MessageView | undefined, view: MessageView): boolean {
  if (previous?.sender_id !== view.sender_id) return false;
  return at(view) - at(previous) < GROUP_GAP_MS && sameDay(new Date(previous.created_at), new Date(view.created_at));
}

// Bubbles of one sender less than 3 minutes apart, on the same day, form a group.
export function buildRows(items: readonly ThreadMessage[], now: Date = new Date()): ThreadRow[] {
  const rows: ThreadRow[] = [];
  items.forEach((item, index) => {
    const previous = items[index - 1]?.view;
    const next = items[index + 1]?.view;
    if (!previous || !sameDay(new Date(previous.created_at), new Date(item.view.created_at))) {
      rows.push({ kind: "day", key: `day-${item.view.created_at}-${item.view.id}`, label: dayLabel(item.view.created_at, now) });
    }
    const joinsPrevious = continuesGroup(previous, item.view);
    const joinsNext = next !== undefined && continuesGroup(item.view, next);
    const position: BubblePosition = joinsPrevious ? (joinsNext ? "middle" : "last") : joinsNext ? "first" : "single";
    rows.push({ kind: "message", key: item.view.client_id ?? String(item.view.id), item, position, firstOfGroup: !joinsPrevious, lastOfGroup: !joinsNext, newGroup: !joinsPrevious && index > 0 });
  });
  return rows;
}

// Messages that get the anti-scam card: RECEIVED text only. The "early" rank
// is only known when the whole history is loaded (as in the app).
export function scamCandidates(items: readonly ThreadMessage[], myId: number, hasMore: boolean, earlyCount: number): Map<number, number> {
  const ranks = new Map<number, number>();
  items.forEach((item, index) => {
    const { view } = item;
    if (view.sender_id === myId || view.unsent || view.type !== "text" || view.content.length === 0 || item.state !== "sent") return;
    ranks.set(view.id, hasMore ? earlyCount : index);
  });
  return ranks;
}
