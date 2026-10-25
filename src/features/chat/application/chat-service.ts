import { ChatError, invalid, notFound } from "../domain/errors";
import { canToggleReaction, canUnsend, isAllowedReaction, isRetiredReaction, type MessageType } from "../domain/message-rules";
import { firstHttpUrl } from "../domain/url-extract";
import type { ConversationMembers, MessageRecord, MessageView, ReactionView } from "../domain/types";
import { messageEvent, readEvent, typingEvent, updatedEvent } from "./chat-events";
import type { FileStorage, MessageNotifier, MessageRepository, NewMessage, RealtimeEvents } from "./ports";
import type { MessagePresenter } from "./message-presenter";

export const DEFAULT_PAGE_SIZE = 30;
export const MAX_PAGE_SIZE = 50;
export const MAX_TEXT_LENGTH = 4000;
export const MAX_CAPTION_LENGTH = 1000;
export const MAX_PHOTOS = 10;

export interface SendInput {
  readonly clientId?: string | undefined;
  readonly type?: MessageType | undefined;
  readonly content?: string | undefined;
  readonly mediaIds?: readonly number[] | undefined;
  readonly replyToId?: number | null | undefined;
}

export interface PreviewScheduler {
  schedule(message: MessageRecord): void;
}

export interface ChatServiceDeps {
  readonly repository: MessageRepository;
  readonly presenter: MessagePresenter;
  readonly events: RealtimeEvents;
  readonly storage: FileStorage;
  readonly previews: PreviewScheduler;
  readonly notifier: MessageNotifier;
  readonly now: () => Date;
}

export interface MessagePage {
  readonly messages: MessageView[];
  readonly hasMore: boolean;
}

export interface SentMessage {
  readonly message: MessageView;
  readonly created: boolean;
}

export interface ChatService {
  listMessages(userId: number, conversationId: number, page: { before: number | null; limit: number | null }): Promise<MessagePage>;
  send(userId: number, conversationId: number, input: SendInput): Promise<SentMessage>;
  toggleReaction(userId: number, messageId: number, emoji: string): Promise<ReactionView[]>;
  unsend(userId: number, messageId: number): Promise<MessageView>;
  markRead(userId: number, conversationId: number, upToId: number | null): Promise<{ upToId: number; readAt: Date } | null>;
  report(userId: number, messageId: number, reason: string, details: string | null): Promise<void>;
  relayTyping(userId: number, conversationId: number, isTyping: boolean): Promise<void>;
}

function otherMember(conversation: ConversationMembers, userId: number): number {
  return conversation.user1Id === userId ? conversation.user2Id : conversation.user1Id;
}

// What the message is, checked against its type before anything is stored.
function toNewMessage(userId: number, conversationId: number, input: SendInput): NewMessage {
  const type = input.type ?? "text";
  const mediaIds = input.mediaIds ?? [];
  const text = (input.content ?? "").trim();
  if (new Set(mediaIds).size !== mediaIds.length) throw invalid("media_ids: duplicate");
  const base = { conversationId, senderId: userId, clientId: input.clientId ?? null, replyToId: input.replyToId ?? null };

  if (type === "text") {
    if (mediaIds.length > 0) throw invalid("media_ids: not allowed on a text message");
    if (text.length === 0) throw invalid("content: required");
    if (text.length > MAX_TEXT_LENGTH) throw invalid("content: too long");
    return { ...base, type, content: text, mediaIds };
  }
  if (type === "photo") {
    if (mediaIds.length < 1 || mediaIds.length > MAX_PHOTOS) throw invalid(`media_ids: 1 to ${MAX_PHOTOS} photos`);
    if (text.length > MAX_CAPTION_LENGTH) throw invalid("content: caption too long");
    return { ...base, type, content: text, mediaIds };
  }
  if (mediaIds.length !== 1) throw invalid("media_ids: exactly one voice note");
  return { ...base, type, content: "", mediaIds };
}

export function createChatService(deps: ChatServiceDeps): ChatService {
  const { repository, presenter, events, storage, previews, notifier, now } = deps;

  async function memberOf(conversationId: number, userId: number): Promise<ConversationMembers> {
    const conversation = await repository.findConversationOf(conversationId, userId);
    if (conversation === null) throw notFound();
    return conversation;
  }

  async function messageOf(messageId: number, userId: number) {
    const found = await repository.findForMember(messageId, userId);
    if (found === null) throw notFound();
    return found;
  }

  async function viewOf(record: MessageRecord): Promise<MessageView> {
    const [view] = await presenter.present([record]);
    if (view === undefined) throw notFound();
    return view;
  }

  async function reload(messageId: number): Promise<MessageRecord> {
    const [record] = await repository.findByIds([messageId]);
    if (record === undefined) throw notFound();
    return record;
  }

  async function listMessages(userId: number, conversationId: number, page: { before: number | null; limit: number | null }): Promise<MessagePage> {
    await memberOf(conversationId, userId);
    const limit = Math.min(Math.max(page.limit ?? DEFAULT_PAGE_SIZE, 1), MAX_PAGE_SIZE);
    const rows = await repository.list(conversationId, page.before, limit + 1);
    return { messages: await presenter.present(rows.slice(0, limit)), hasMore: rows.length > limit };
  }

  // The message is stored and delivered: whatever goes wrong with the push is
  // logged without any personal data and never reaches the sender.
  function notifyRecipient(event: { conversationId: number; senderId: number; recipientId: number }): void {
    try {
      notifier.messageCreated(event);
    } catch (error: unknown) {
      console.error("Message notification failed:", error instanceof Error ? error.name : "unknown");
    }
  }

  async function send(userId: number, conversationId: number, input: SendInput): Promise<SentMessage> {
    const conversation = await memberOf(conversationId, userId);
    const other = otherMember(conversation, userId);
    if (await repository.isBlocked(userId, other)) throw new ChatError("blocked");

    const outcome = await repository.insert(toNewMessage(userId, conversationId, input));
    if (outcome.kind === "media_unusable") throw invalid("media_ids: unknown, foreign or already used");
    if (outcome.kind === "reply_unusable") throw invalid("reply_to_id: not in this conversation");

    const message = await viewOf(outcome.message);
    if (outcome.kind === "existing") return { message, created: false };

    events.emit([userId, other], messageEvent(message));
    notifyRecipient({ conversationId, senderId: userId, recipientId: other });
    if (outcome.message.type === "text" && firstHttpUrl(outcome.message.content) !== null) {
      previews.schedule(outcome.message);
    }
    return { message, created: true };
  }

  async function toggleReaction(userId: number, messageId: number, emoji: string): Promise<ReactionView[]> {
    if (!isAllowedReaction(emoji) && !isRetiredReaction(emoji)) throw invalid("emoji: not allowed");
    const { message, conversation } = await messageOf(messageId, userId);
    if (message.unsentAt !== null) throw notFound();
    const mine = (await repository.reactions([messageId])).find((reaction) => reaction.userId === userId);
    if (!canToggleReaction(emoji, mine?.emoji ?? null)) throw invalid("emoji: not allowed");
    const other = otherMember(conversation, userId);
    if (await repository.isBlocked(userId, other)) throw new ChatError("blocked");

    await repository.toggleReaction(messageId, userId, emoji);
    const view = await viewOf(await reload(messageId));
    events.emit([userId, other], updatedEvent(view));
    return [...view.reactions];
  }

  async function removeFiles(keys: readonly string[]): Promise<void> {
    for (const key of keys) {
      try {
        await storage.remove(key);
      } catch (error: unknown) {
        console.error("Chat media removal failed:", error instanceof Error ? error.name : "unknown");
      }
    }
  }

  async function unsend(userId: number, messageId: number): Promise<MessageView> {
    const { message, conversation } = await messageOf(messageId, userId);
    const decision = canUnsend({ senderId: message.senderId, userId, createdAt: message.createdAt, now: now() });
    if (decision === "not_author") throw new ChatError("not_author");
    if (message.unsentAt !== null) return viewOf(message);
    if (decision === "too_late") throw new ChatError("too_late");

    const deleted = await repository.unsend(messageId, now());
    if (deleted !== null) await removeFiles(deleted.map((media) => media.storageKey));
    const view = await viewOf(await reload(messageId));
    // After a block, the retraction only reaches the author's own devices.
    const other = otherMember(conversation, userId);
    events.emit((await repository.isBlocked(userId, other)) ? [userId] : [userId, other], updatedEvent(view));
    return view;
  }

  // A read receipt is a signal ("I saw it"): across a block it is neither
  // stored (the sender could fetch `read_at`) nor pushed. Conversations with a
  // blocked person are hidden from the list, so no unread badge is left behind.
  async function markRead(userId: number, conversationId: number, upToId: number | null) {
    const conversation = await memberOf(conversationId, userId);
    if (await repository.isBlocked(userId, otherMember(conversation, userId))) return null;
    const outcome = await repository.markRead(conversationId, userId, upToId, now());
    if (outcome !== null) {
      events.emit([userId, otherMember(conversation, userId)], readEvent({ conversationId, userId, ...outcome }));
    }
    return outcome;
  }

  async function report(userId: number, messageId: number, reason: string, details: string | null): Promise<void> {
    const { message } = await messageOf(messageId, userId);
    if (message.senderId === userId) throw invalid("message: cannot report your own message");
    await repository.report({ reporterId: userId, reportedUserId: message.senderId, messageId, reason, details });
  }

  async function relayTyping(userId: number, conversationId: number, isTyping: boolean): Promise<void> {
    const conversation = await repository.findConversationOf(conversationId, userId);
    if (conversation === null) return;
    if (await repository.isBlocked(userId, otherMember(conversation, userId))) return;
    events.emit([otherMember(conversation, userId)], typingEvent({ conversationId, userId, isTyping }));
  }

  return { listMessages, send, toggleReaction, unsend, markRead, report, relayTyping };
}
