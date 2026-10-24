// Business rules of a message that do not depend on storage or transport.

export type MessageType = "text" | "photo" | "voice";

export const ALLOWED_REACTIONS = ["❤️", "😂", "😮", "😢", "🙏", "👍"] as const;
export type Reaction = (typeof ALLOWED_REACTIONS)[number];

// Retired on 2026-10-24 (replaced by 🙏): a reaction already placed stays displayed
// and can be removed, but can no longer be added.
export const RETIRED_REACTIONS = ["😡"] as const;
export const DISPLAYED_REACTIONS = [...ALLOWED_REACTIONS, ...RETIRED_REACTIONS] as const;

export function isAllowedReaction(emoji: string): emoji is Reaction {
  return (ALLOWED_REACTIONS as readonly string[]).includes(emoji);
}

export function isRetiredReaction(emoji: string): boolean {
  return (RETIRED_REACTIONS as readonly string[]).includes(emoji);
}

// `current` is the emoji the member already has on the message, if any. A retired
// emoji can only be toggled off, which is the case where it equals `current`.
export function canToggleReaction(emoji: string, current: string | null): boolean {
  if (isAllowedReaction(emoji)) return true;
  return current === emoji && isRetiredReaction(emoji);
}

export const UNSEND_WINDOW_MS = 15 * 60 * 1000;

export type UnsendDecision = "allowed" | "not_author" | "too_late";

export function canUnsend(input: {
  readonly senderId: number;
  readonly userId: number;
  readonly createdAt: Date;
  readonly now: Date;
}): UnsendDecision {
  if (input.senderId !== input.userId) return "not_author";
  return input.now.getTime() - input.createdAt.getTime() > UNSEND_WINDOW_MS ? "too_late" : "allowed";
}

const PREVIEW_LENGTH = 80;

export function replyPreview(message: { type: MessageType; content: string; unsent: boolean }): string {
  if (message.unsent) return "Message retiré";
  if (message.type === "photo") return "Photo";
  if (message.type === "voice") return "Message vocal";
  const letters = Array.from(message.content);
  return letters.length <= PREVIEW_LENGTH ? message.content : `${letters.slice(0, PREVIEW_LENGTH - 1).join("")}…`;
}
