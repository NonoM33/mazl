import { randomUUID } from "node:crypto";
import { PhotoRejectedError } from "../../media/domain/errors";
import { ChatError, invalid, notFound } from "../domain/errors";
import { validateVoiceBytes } from "../domain/voice-format";
import { parseWaveform } from "../domain/waveform";
import type { MediaKind, UploadedMediaView } from "../domain/types";
import { signChatMediaUrl } from "./media-signer";
import type { ChatImageProcessor, FileStorage, MediaRepository, MessageRepository } from "./ports";

export const MAX_PHOTO_BYTES = 10 * 1024 * 1024;
export const MAX_VOICE_BYTES = 3 * 1024 * 1024;
export const MAX_VOICE_MS = 120_000;
export const MAX_PENDING_PER_USER = 40;
export const ORPHAN_AGE_MS = 24 * 60 * 60 * 1000;
const PURGE_BATCH = 200;
export const STRAY_MIN_AGE_MS = 60 * 60 * 1000;
const LOOKUP_BATCH = 500;
const CHAT_PREFIX = "chat";

export interface ServedMedia {
  readonly bytes: Uint8Array;
  readonly contentType: "image/jpeg" | "audio/mp4";
}

export interface VoiceUpload {
  readonly bytes: Uint8Array;
  readonly durationMs: number;
  // JSON text of the 48-point waveform, as sent in the multipart field.
  readonly waveform: string;
}

export interface ChatMediaService {
  uploadPhoto(userId: number, conversationId: number, bytes: Uint8Array): Promise<UploadedMediaView>;
  uploadVoice(userId: number, conversationId: number, upload: VoiceUpload): Promise<UploadedMediaView>;
  serve(mediaId: number): Promise<ServedMedia | null>;
  // Deletes attachments nobody used for 24 h (files first, then rows).
  purgeOrphans(): Promise<number>;
  // GDPR erasure: lists every chat file of the user's conversations BEFORE
  // `deletion` runs (the cascade would hide them), and removes them from disk
  // only AFTER it succeeded. If `deletion` throws, no file is touched.
  eraseUserMedia<T>(userId: number, deletion: () => Promise<T>): Promise<T>;
  // Safety net: removes files under chat/ that no row owns and that are older
  // than an hour, so an upload in flight is never touched.
  sweepStrayFiles(): Promise<number>;
}

export interface ChatMediaDeps {
  readonly messages: Pick<MessageRepository, "findConversationOf" | "isBlocked">;
  readonly media: MediaRepository;
  readonly storage: FileStorage;
  readonly images: ChatImageProcessor;
  readonly now: () => Date;
}

export function createChatMediaService(deps: ChatMediaDeps): ChatMediaService {
  const { messages, media, storage, images, now } = deps;

  async function authorise(userId: number, conversationId: number): Promise<void> {
    const conversation = await messages.findConversationOf(conversationId, userId);
    if (conversation === null) throw notFound();
    const other = conversation.user1Id === userId ? conversation.user2Id : conversation.user1Id;
    if (await messages.isBlocked(userId, other)) throw new ChatError("blocked");
    if ((await media.countPending(userId)) >= MAX_PENDING_PER_USER) throw new ChatError("too_many_pending");
  }

  // The file is written first; if the row cannot be, the file goes again.
  async function store(userId: number, conversationId: number, kind: MediaKind, extension: string, bytes: Uint8Array,
    facts: { width: number | null; height: number | null; durationMs: number | null; waveform: readonly number[] | null }) {
    const storageKey = `chat/${conversationId}/${randomUUID()}.${extension}`;
    await storage.save(storageKey, bytes);
    try {
      return await media.insert({ conversationId, uploaderId: userId, kind, storageKey, ...facts });
    } catch (error: unknown) {
      await storage.remove(storageKey);
      throw error;
    }
  }

  async function uploadPhoto(userId: number, conversationId: number, bytes: Uint8Array): Promise<UploadedMediaView> {
    await authorise(userId, conversationId);
    if (bytes.byteLength === 0) throw invalid("file: empty");
    if (bytes.byteLength > MAX_PHOTO_BYTES) throw new ChatError("too_large", "photo");
    let processed;
    try {
      processed = await images.toChatJpeg(bytes);
    } catch (error: unknown) {
      if (error instanceof PhotoRejectedError) throw invalid(`file: ${error.reason}`);
      throw error;
    }
    const row = await store(userId, conversationId, "photo", "jpg", processed.bytes, {
      width: processed.width, height: processed.height, durationMs: null, waveform: null,
    });
    return { id: row.id, kind: "photo", url: signChatMediaUrl(row.id), width: row.width, height: row.height };
  }

  async function uploadVoice(userId: number, conversationId: number, upload: VoiceUpload): Promise<UploadedMediaView> {
    await authorise(userId, conversationId);
    if (upload.bytes.byteLength === 0) throw invalid("file: empty");
    if (upload.bytes.byteLength > MAX_VOICE_BYTES) throw new ChatError("too_large", "voice");
    if (!Number.isInteger(upload.durationMs) || upload.durationMs < 1 || upload.durationMs > MAX_VOICE_MS) {
      throw invalid("duration_ms: 1 to 120000");
    }
    const waveform = parseWaveform(upload.waveform);
    if (waveform === null) throw invalid("waveform: 48 integers between 0 and 100");
    const verdict = validateVoiceBytes(upload.bytes);
    if (!verdict.ok) throw invalid(`file: ${verdict.reason}`);
    const row = await store(userId, conversationId, "voice", "m4a", upload.bytes, {
      width: null, height: null, durationMs: upload.durationMs, waveform,
    });
    return { id: row.id, kind: "voice", url: signChatMediaUrl(row.id), duration_ms: row.durationMs, waveform: row.waveform };
  }

  async function serve(mediaId: number): Promise<ServedMedia | null> {
    const row = await media.find(mediaId);
    if (row === null) return null;
    const bytes = await storage.read(row.storageKey);
    if (bytes === null) return null;
    return { bytes, contentType: row.kind === "voice" ? "audio/mp4" : "image/jpeg" };
  }

  async function purgeOrphans(): Promise<number> {
    const cutoff = new Date(now().getTime() - ORPHAN_AGE_MS);
    let purged = 0;
    for (;;) {
      const batch = await media.listOrphans(cutoff, PURGE_BATCH);
      if (batch.length === 0) return purged;
      const removed: number[] = [];
      for (const row of batch) {
        try {
          await storage.remove(row.storageKey);
          removed.push(row.id);
        } catch (error: unknown) {
          console.error("Chat orphan removal failed:", error instanceof Error ? error.name : "unknown");
        }
      }
      if (removed.length === 0) return purged;
      await media.delete(removed);
      purged += removed.length;
    }
  }

  async function removeQuietly(key: string): Promise<boolean> {
    try {
      await storage.remove(key);
      return true;
    } catch (error: unknown) {
      console.error("Chat file removal failed:", error instanceof Error ? error.name : "unknown");
      return false;
    }
  }

  async function eraseUserMedia<T>(userId: number, deletion: () => Promise<T>): Promise<T> {
    const keys = await media.storageKeysOfUser(userId);
    const result = await deletion();
    for (const key of keys) await removeQuietly(key);
    return result;
  }

  async function sweepStrayFiles(): Promise<number> {
    const cutoff = now().getTime() - STRAY_MIN_AGE_MS;
    const candidates = (await storage.list(CHAT_PREFIX)).filter((file) => file.modifiedAt.getTime() < cutoff);
    let removed = 0;
    for (let from = 0; from < candidates.length; from += LOOKUP_BATCH) {
      const batch = candidates.slice(from, from + LOOKUP_BATCH).map((file) => file.key);
      const owned = await media.referencedKeys(batch);
      for (const key of batch) {
        if (!owned.has(key) && (await removeQuietly(key))) removed += 1;
      }
    }
    return removed;
  }

  return { uploadPhoto, uploadVoice, serve, purgeOrphans, eraseUserMedia, sweepStrayFiles };
}
