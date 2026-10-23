import type { MessageView } from "../domain/types";

// WebSocket events of CONTRAT.md §3. Fields the app already read before the
// redesign (camelCase ids) are kept next to the new ones so that installed
// versions keep working.

export interface ChatEvent {
  readonly type: string;
  readonly payload: unknown;
}

export function messageEvent(message: MessageView): ChatEvent {
  return {
    type: "chat:message",
    payload: {
      message,
      conversationId: message.conversation_id,
      messageId: message.id,
      senderId: message.sender_id,
      content: message.content,
      createdAt: message.created_at,
    },
  };
}

export function updatedEvent(message: MessageView): ChatEvent {
  return { type: "chat:updated", payload: { message } };
}

export function readEvent(input: { conversationId: number; userId: number; upToId: number; readAt: Date }): ChatEvent {
  return {
    type: "chat:read",
    payload: {
      conversation_id: input.conversationId,
      user_id: input.userId,
      up_to_id: input.upToId,
      read_at: input.readAt.toISOString(),
      conversationId: input.conversationId,
      userId: input.userId,
    },
  };
}

export function typingEvent(input: { conversationId: number; userId: number; isTyping: boolean }): ChatEvent {
  return {
    type: "chat:typing",
    payload: {
      conversation_id: input.conversationId,
      user_id: input.userId,
      is_typing: input.isTyping,
      conversationId: input.conversationId,
      userId: input.userId,
      isTyping: input.isTyping,
    },
  };
}
