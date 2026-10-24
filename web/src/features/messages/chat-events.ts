import type { MessageView } from "../../shared/api/types";

// Narrowing of the realtime payloads (docs/chat/CONTRAT.md §3). Unknown shapes
// are dropped, never thrown on, and never logged: they carry message text.

const isRecord = (value: unknown): value is Record<string, unknown> => typeof value === "object" && value !== null;

export function messageOf(payload: unknown): MessageView | null {
  if (!isRecord(payload) || !isRecord(payload.message)) return null;
  const { message } = payload;
  const valid = typeof message.id === "number" && typeof message.conversation_id === "number" && typeof message.sender_id === "number" && typeof message.created_at === "string";
  return valid ? (message as unknown as MessageView) : null;
}

export interface ReadEvent { readonly conversationId: number; readonly userId: number; readonly upToId: number; readonly readAt: string }

export function readEventOf(payload: unknown): ReadEvent | null {
  if (!isRecord(payload)) return null;
  const { conversation_id: conversationId, user_id: userId, up_to_id: upToId, read_at: readAt } = payload;
  if (typeof conversationId !== "number" || typeof userId !== "number" || typeof upToId !== "number" || typeof readAt !== "string") return null;
  return { conversationId, userId, upToId, readAt };
}

export interface TypingEvent { readonly conversationId: number; readonly userId: number; readonly isTyping: boolean }

export function typingEventOf(payload: unknown): TypingEvent | null {
  if (!isRecord(payload)) return null;
  const { conversation_id: conversationId, user_id: userId, is_typing: isTyping } = payload;
  if (typeof conversationId !== "number" || typeof userId !== "number") return null;
  return { conversationId, userId, isTyping: isTyping !== false };
}
