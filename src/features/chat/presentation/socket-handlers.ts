import type { ChatService } from "../application/chat-service";
import { ChatError } from "../domain/errors";
import { socketReadSchema, socketSendSchema, socketTypingSchema } from "./schemas";

// The WebSocket `chat:*` messages of the app, each one a thin call into the
// service. Nothing here throws: a bad frame, a stranger or a blocked pair is
// ignored exactly as before the redesign.

export interface ChatSocketHandlers {
  send(userId: number, payload: unknown): Promise<void>;
  typing(userId: number, payload: unknown): Promise<void>;
  read(userId: number, payload: unknown): Promise<void>;
}

async function ignoringChatErrors(work: () => Promise<unknown>): Promise<void> {
  try {
    await work();
  } catch (error: unknown) {
    if (!(error instanceof ChatError)) console.error("WebSocket chat error:", error instanceof Error ? error.name : "unknown");
  }
}

export function createChatSocketHandlers(chat: ChatService): ChatSocketHandlers {
  return {
    send: (userId, payload) =>
      ignoringChatErrors(async () => {
        const parsed = socketSendSchema.safeParse(payload);
        if (!parsed.success) return;
        await chat.send(userId, parsed.data.conversationId, {
          clientId: parsed.data.clientId,
          content: parsed.data.content,
          replyToId: parsed.data.replyToId,
        });
      }),
    typing: (userId, payload) =>
      ignoringChatErrors(async () => {
        const parsed = socketTypingSchema.safeParse(payload);
        if (parsed.success) await chat.relayTyping(userId, parsed.data.conversationId, parsed.data.isTyping ?? true);
      }),
    read: (userId, payload) =>
      ignoringChatErrors(async () => {
        const parsed = socketReadSchema.safeParse(payload);
        if (parsed.success) await chat.markRead(userId, parsed.data.conversationId, parsed.data.upToId ?? null);
      }),
  };
}
