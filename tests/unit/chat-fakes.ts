import type {
  FileStorage, InsertOutcome, MessageNotifier, MessageRepository, NewMedia, NewMessage, RealtimeEvents, ReadOutcome,
} from "../../src/features/chat/application/ports";
import type {
  ConversationMembers, MediaRecord, MessageRecord, ReactionRecord, StoredLinkPreview,
} from "../../src/features/chat/domain/types";

// In-memory doubles of the chat ports. They implement the documented behaviour
// of each port (not of the Postgres adapter), so the services can be tested
// without a database.

export const T0 = new Date("2026-10-23T10:00:00.000Z");

export class FakeMessageRepository implements MessageRepository {
  readonly conversations = new Map<number, ConversationMembers>();
  readonly messages: MessageRecord[] = [];
  readonly mediaRows: MediaRecord[] = [];
  readonly reactionRows: ReactionRecord[] = [];
  readonly reports: Array<{ reporterId: number; reportedUserId: number; messageId: number; reason: string; details: string | null }> = [];
  readonly blocked = new Set<string>();
  private nextId = 1;
  private nextMediaId = 1;
  createdAt: Date = T0;

  addConversation(id: number, user1Id: number, user2Id: number): void {
    this.conversations.set(id, { id, user1Id, user2Id });
  }

  addMedia(partial: Partial<MediaRecord> & Pick<MediaRecord, "conversationId" | "uploaderId" | "kind">): MediaRecord {
    const row: MediaRecord = {
      id: this.nextMediaId++, storageKey: `chat/${partial.conversationId}/${this.nextMediaId}.bin`, width: 10, height: 10,
      durationMs: null, waveform: null, messageId: null, role: "attachment", createdAt: T0, ...partial,
    };
    this.mediaRows.push(row);
    return row;
  }

  async findConversationOf(conversationId: number, userId: number) {
    const c = this.conversations.get(conversationId);
    return c && (c.user1Id === userId || c.user2Id === userId) ? c : null;
  }
  async isBlocked(a: number, b: number) {
    return this.blocked.has(`${a}:${b}`) || this.blocked.has(`${b}:${a}`);
  }
  async list(conversationId: number, before: number | null, limit: number) {
    return this.messages
      .filter((m) => m.conversationId === conversationId && (before === null || m.id < before))
      .sort((a, b) => b.id - a.id)
      .slice(0, limit);
  }
  async findByIds(ids: readonly number[]) {
    return this.messages.filter((m) => ids.includes(m.id));
  }
  async findForMember(messageId: number, userId: number) {
    const message = this.messages.find((m) => m.id === messageId);
    const conversation = message && (await this.findConversationOf(message.conversationId, userId));
    return message && conversation ? { message, conversation } : null;
  }
  async insert(input: NewMessage): Promise<InsertOutcome> {
    if (input.clientId !== null) {
      const existing = this.messages.find(
        (m) => m.conversationId === input.conversationId && m.senderId === input.senderId && m.clientId === input.clientId,
      );
      if (existing) return { kind: "existing", message: existing };
    }
    if (input.replyToId !== null) {
      const parent = this.messages.find((m) => m.id === input.replyToId);
      if (!parent || parent.conversationId !== input.conversationId) return { kind: "reply_unusable" };
    }
    const usable = input.mediaIds.every((id) => {
      const row = this.mediaRows.find((m) => m.id === id);
      return row && row.conversationId === input.conversationId && row.uploaderId === input.senderId && row.messageId === null && row.role === "attachment";
    });
    if (!usable) return { kind: "media_unusable" };
    const message: MessageRecord = {
      id: this.nextId++, conversationId: input.conversationId, senderId: input.senderId, clientId: input.clientId,
      type: input.type, content: input.content, replyToId: input.replyToId, linkPreview: null, unsentAt: null, readAt: null,
      createdAt: this.createdAt,
    };
    this.messages.push(message);
    for (const id of input.mediaIds) {
      const index = this.mediaRows.findIndex((m) => m.id === id);
      this.mediaRows[index] = { ...this.mediaRows[index]!, messageId: message.id };
    }
    return { kind: "created", message };
  }
  async media(ids: readonly number[]) {
    return this.mediaRows.filter((m) => m.messageId !== null && ids.includes(m.messageId));
  }
  async reactions(ids: readonly number[]) {
    return this.reactionRows.filter((r) => ids.includes(r.messageId));
  }
  async toggleReaction(messageId: number, userId: number, emoji: string) {
    const index = this.reactionRows.findIndex((r) => r.messageId === messageId && r.userId === userId);
    const current = this.reactionRows[index];
    if (current && current.emoji === emoji) this.reactionRows.splice(index, 1);
    else if (current) this.reactionRows[index] = { messageId, userId, emoji };
    else this.reactionRows.push({ messageId, userId, emoji });
  }
  async unsend(messageId: number, at: Date) {
    const index = this.messages.findIndex((m) => m.id === messageId);
    const message = this.messages[index];
    if (!message || message.unsentAt) return null;
    const reported = this.reports.some((r) => r.messageId === messageId);
    this.messages[index] = { ...message, unsentAt: at, content: reported ? message.content : "", linkPreview: null };
    const removed = this.mediaRows.filter((m) => m.messageId === messageId);
    for (const row of removed) this.mediaRows.splice(this.mediaRows.indexOf(row), 1);
    for (let i = this.reactionRows.length - 1; i >= 0; i--) if (this.reactionRows[i]!.messageId === messageId) this.reactionRows.splice(i, 1);
    return removed;
  }
  async markRead(conversationId: number, readerId: number, upToId: number | null, at: Date): Promise<ReadOutcome> {
    const targets = this.messages.filter(
      (m) => m.conversationId === conversationId && m.senderId !== readerId && m.readAt === null && (upToId === null || m.id <= upToId),
    );
    if (targets.length === 0) return null;
    for (const t of targets) this.messages[this.messages.indexOf(t)] = { ...t, readAt: at };
    return { upToId: Math.max(...targets.map((t) => t.id)), readAt: at };
  }
  async report(input: { reporterId: number; reportedUserId: number; messageId: number; reason: string; details: string | null }) {
    if (this.reports.some((r) => r.reporterId === input.reporterId && r.messageId === input.messageId)) return false;
    this.reports.push(input);
    return true;
  }
  async attachPreview(input: { messageId: number; preview: Omit<StoredLinkPreview, "imageMediaId">; image: NewMedia | null }) {
    const index = this.messages.findIndex((m) => m.id === input.messageId);
    const message = this.messages[index];
    if (!message || message.unsentAt) return null;
    let imageMediaId: number | null = null;
    if (input.image) {
      const row = this.addMedia({ ...input.image, messageId: message.id, role: "preview" });
      imageMediaId = row.id;
    }
    this.messages[index] = { ...message, linkPreview: { ...input.preview, imageMediaId } };
    return this.messages[index]!;
  }
}

export class FakeStorage implements FileStorage {
  readonly files = new Map<string, Uint8Array>();
  readonly modified = new Map<string, Date>();
  failRemoveFor = new Set<string>();
  savedAt: Date = T0;
  async save(key: string, bytes: Uint8Array) {
    this.files.set(key, bytes);
    this.modified.set(key, this.savedAt);
  }
  async list(prefix: string) {
    return [...this.files.keys()]
      .filter((key) => key.startsWith(`${prefix}/`))
      .map((key) => ({ key, modifiedAt: this.modified.get(key) ?? T0 }));
  }
  async read(key: string) { return this.files.get(key) ?? null; }
  async remove(key: string) {
    if (this.failRemoveFor.has(key)) throw new Error("disk error");
    this.files.delete(key);
  }
}

export class RecordingNotifier implements MessageNotifier {
  readonly created: Array<{ conversationId: number; senderId: number; recipientId: number }> = [];
  failWith: Error | null = null;
  messageCreated(event: { conversationId: number; senderId: number; recipientId: number }): void {
    if (this.failWith !== null) throw this.failWith;
    this.created.push({ ...event });
  }
}

export class RecordingEvents implements RealtimeEvents {
  readonly sent: Array<{ to: number[]; type: string; payload: unknown }> = [];
  emit(userIds: readonly number[], event: { type: string; payload: unknown }) {
    this.sent.push({ to: [...userIds], type: event.type, payload: event.payload });
  }
  ofType(type: string) { return this.sent.filter((e) => e.type === type); }
}

import type { FetchOptions, FetchOutcome, GuardedFetcher } from "../../src/features/chat/application/guarded-fetch";
import type { CachedPreview, ChatImageProcessor, PreviewCache, PreviewCacheData, ProcessedImage } from "../../src/features/chat/application/ports";
import { PhotoRejectedError } from "../../src/features/media/domain/errors";

export class FakeFetcher implements GuardedFetcher {
  readonly calls: Array<{ url: string; kind: string }> = [];
  constructor(private readonly responses: Record<string, FetchOutcome | (() => Promise<FetchOutcome>)>) {}
  async fetch(url: string, options: FetchOptions): Promise<FetchOutcome> {
    this.calls.push({ url, kind: options.kind });
    const response = this.responses[url];
    if (response === undefined) return { ok: false, reason: "dns_failed" };
    return typeof response === "function" ? response() : response;
  }
}

export const htmlPage = (html: string): FetchOutcome => ({
  ok: true, body: new TextEncoder().encode(html), contentType: "text/html", truncated: false,
});
export const imageBytes = (marker = 1): FetchOutcome => ({
  ok: true, body: Uint8Array.from([0x89, 0x50, marker]), contentType: "image/png", truncated: false,
});

export class FakeImages implements ChatImageProcessor {
  failPreview = false;
  readonly previewCalls: Uint8Array[] = [];
  async toChatJpeg(bytes: Uint8Array): Promise<ProcessedImage> {
    if (bytes.byteLength < 3) throw new PhotoRejectedError("undecodable");
    return { bytes: Uint8Array.from([0xff, 0xd8, 0xff, 0x01]), width: 640, height: 480 };
  }
  async toPreviewJpeg(bytes: Uint8Array): Promise<ProcessedImage> {
    this.previewCalls.push(bytes);
    if (this.failPreview) throw new PhotoRejectedError("undecodable");
    return { bytes: Uint8Array.from([0xff, 0xd8, 0xff, 0x02]), width: 320, height: 200 };
  }
}

export class FakePreviewCache implements PreviewCache {
  readonly entries = new Map<string, { data: PreviewCacheData | null; at: Date }>();
  async get(url: string, notOlderThan: Date): Promise<CachedPreview> {
    const entry = this.entries.get(url);
    return entry && entry.at >= notOlderThan ? { found: true, data: entry.data } : { found: false };
  }
  async put(url: string, data: PreviewCacheData | null, at: Date) {
    const previous = this.entries.get(url)?.data?.imageKey ?? null;
    this.entries.set(url, { data, at });
    return previous;
  }
  async deleteExpired(olderThan: Date) {
    const keys: string[] = [];
    for (const [url, entry] of [...this.entries]) {
      if (entry.at < olderThan) {
        this.entries.delete(url);
        if (entry.data?.imageKey) keys.push(entry.data.imageKey);
      }
    }
    return keys;
  }
}

import type { MediaRepository } from "../../src/features/chat/application/ports";

export class FakeMediaRepository implements MediaRepository {
  readonly rows: MediaRecord[] = [];
  // conversation id -> its two members, for storageKeysOfUser
  readonly members = new Map<number, number[]>();
  // image keys owned by the preview cache
  readonly cacheKeys = new Set<string>();
  readonly referenceLookups: number[] = [];
  async storageKeysOfUser(userId: number) {
    return this.rows.filter((r) => this.members.get(r.conversationId)?.includes(userId)).map((r) => r.storageKey);
  }
  async referencedKeys(keys: readonly string[]) {
    this.referenceLookups.push(keys.length);
    const owned = new Set([...this.rows.map((r) => r.storageKey), ...this.cacheKeys]);
    return new Set(keys.filter((key) => owned.has(key)));
  }
  private nextId = 1;
  async insert(media: NewMedia) {
    const row: MediaRecord = { id: this.nextId++, messageId: null, role: "attachment", createdAt: T0, ...media };
    this.rows.push(row);
    return row;
  }
  async find(id: number) { return this.rows.find((r) => r.id === id) ?? null; }
  async countPending(uploaderId: number) {
    return this.rows.filter((r) => r.uploaderId === uploaderId && r.messageId === null && r.role === "attachment").length;
  }
  async listOrphans(olderThan: Date, limit: number) {
    return this.rows.filter((r) => r.messageId === null && r.role === "attachment" && r.createdAt < olderThan).slice(0, limit);
  }
  async delete(ids: readonly number[]) {
    for (const id of ids) {
      const index = this.rows.findIndex((r) => r.id === id);
      if (index >= 0) this.rows.splice(index, 1);
    }
  }
}
