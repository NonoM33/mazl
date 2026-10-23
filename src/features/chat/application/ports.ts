import type { MessageType } from "../domain/message-rules";
import type {
  ConversationMembers,
  MediaKind,
  MediaRecord,
  MediaRole,
  MessageRecord,
  ReactionRecord,
  StoredLinkPreview,
} from "../domain/types";

// Ports of the chat feature. Services depend on these interfaces only; the
// Postgres, disk, sharp and WebSocket adapters live in ../infra.

export interface NewMessage {
  readonly conversationId: number;
  readonly senderId: number;
  readonly clientId: string | null;
  readonly type: MessageType;
  readonly content: string;
  readonly replyToId: number | null;
  // Attachments in display order; empty for a text message.
  readonly mediaIds: readonly number[];
}

export type InsertOutcome =
  | { readonly kind: "created"; readonly message: MessageRecord }
  // Same (conversation, sender, client_id) already stored: nothing was written.
  | { readonly kind: "existing"; readonly message: MessageRecord }
  | { readonly kind: "media_unusable" }
  | { readonly kind: "reply_unusable" };

export type ReadOutcome = { readonly upToId: number; readonly readAt: Date } | null;

export interface MessageRepository {
  // The conversation, only when `userId` is one of its two members.
  findConversationOf(conversationId: number, userId: number): Promise<ConversationMembers | null>;
  isBlocked(userA: number, userB: number): Promise<boolean>;
  // Newest first, ids strictly below `before` when given.
  list(conversationId: number, before: number | null, limit: number): Promise<MessageRecord[]>;
  findByIds(ids: readonly number[]): Promise<MessageRecord[]>;
  // The message, only when `userId` is a member of its conversation.
  findForMember(messageId: number, userId: number): Promise<{ message: MessageRecord; conversation: ConversationMembers } | null>;
  insert(message: NewMessage): Promise<InsertOutcome>;
  media(messageIds: readonly number[]): Promise<MediaRecord[]>;
  reactions(messageIds: readonly number[]): Promise<ReactionRecord[]>;
  // Same emoji again removes it; another emoji replaces the previous one.
  toggleReaction(messageId: number, userId: number, emoji: string): Promise<void>;
  // Marks the message unsent, empties its text (unless a report points at it),
  // deletes its reactions and media rows. Returns the deleted media rows, or
  // null when the message was already unsent.
  unsend(messageId: number, at: Date): Promise<MediaRecord[] | null>;
  // Marks as read what `readerId` received up to `upToId` (all when null).
  markRead(conversationId: number, readerId: number, upToId: number | null, at: Date): Promise<ReadOutcome>;
  // False when this reporter already reported this message.
  report(input: { reporterId: number; reportedUserId: number; messageId: number; reason: string; details: string | null }): Promise<boolean>;
  // Stores the preview and attaches its image; null when the message is gone or unsent.
  attachPreview(input: { messageId: number; preview: Omit<StoredLinkPreview, "imageMediaId">; image: NewMedia | null }): Promise<MessageRecord | null>;
}

export interface NewMedia {
  readonly conversationId: number;
  readonly uploaderId: number;
  readonly kind: MediaKind;
  readonly storageKey: string;
  readonly width: number | null;
  readonly height: number | null;
  readonly durationMs: number | null;
  readonly waveform: readonly number[] | null;
  readonly role?: MediaRole;
}

export interface MediaRepository {
  insert(media: NewMedia): Promise<MediaRecord>;
  find(id: number): Promise<MediaRecord | null>;
  countPending(uploaderId: number): Promise<number>;
  // Attachments nobody used, uploaded before `olderThan`.
  listOrphans(olderThan: Date, limit: number): Promise<MediaRecord[]>;
  delete(ids: readonly number[]): Promise<void>;
}

export type CachedPreview =
  | { readonly found: false }
  | { readonly found: true; readonly data: PreviewCacheData | null };

// null data = the page was fetched and gave nothing usable (cached too).
export interface PreviewCacheData {
  readonly title: string | null;
  readonly description: string | null;
  readonly siteName: string | null;
  readonly imageKey: string | null;
  readonly imageWidth: number | null;
  readonly imageHeight: number | null;
}

export interface PreviewCache {
  get(url: string, notOlderThan: Date): Promise<CachedPreview>;
  // Returns the image key of the entry it replaced, so the caller can delete that file.
  put(url: string, data: PreviewCacheData | null, at: Date): Promise<string | null>;
  // Drops entries fetched before `olderThan`; returns the image keys they owned.
  deleteExpired(olderThan: Date): Promise<string[]>;
}

export interface FileStorage {
  save(key: string, bytes: Uint8Array): Promise<void>;
  read(key: string): Promise<Uint8Array | null>;
  remove(key: string): Promise<void>;
}

export interface ProcessedImage {
  readonly bytes: Uint8Array;
  readonly width: number;
  readonly height: number;
}

export interface ChatImageProcessor {
  // Metadata-free JPEG, long side <= 2048 px. Throws PhotoRejectedError.
  toChatJpeg(bytes: Uint8Array): Promise<ProcessedImage>;
  // Metadata-free JPEG, long side <= 1024 px, for link preview thumbnails.
  toPreviewJpeg(bytes: Uint8Array): Promise<ProcessedImage>;
}

export interface RealtimeEvents {
  emit(userIds: readonly number[], event: { type: string; payload: unknown }): void;
}
