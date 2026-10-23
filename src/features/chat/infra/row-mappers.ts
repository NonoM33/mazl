import type { Sql } from "postgres";
import { z } from "zod";
import type { MessageType } from "../domain/message-rules";
import type { MediaKind, MediaRecord, MediaRole, MessageRecord, StoredLinkPreview } from "../domain/types";

// Row shapes as Postgres returns them, and their conversion to domain records.

export interface MessageRow {
  id: number;
  conversation_id: number;
  sender_id: number;
  client_id: string | null;
  type: MessageType;
  content: string;
  reply_to_id: number | null;
  link_preview: unknown;
  unsent_at: Date | null;
  read_at: Date | null;
  created_at: Date;
}

export interface MediaRow {
  id: number;
  conversation_id: number;
  uploader_id: number;
  kind: MediaKind;
  storage_key: string;
  width: number | null;
  height: number | null;
  duration_ms: number | null;
  waveform: unknown;
  message_id: number | null;
  role: MediaRole;
  created_at: Date;
}

// `messages.created_at` is a TIMESTAMP (no zone) written by NOW() in the session
// zone; reading it back as a zoned instant keeps the 15-minute unsend window
// right whatever zone the server process runs in.
export const messageColumns = (q: Sql) => q`
  m.id, m.conversation_id, m.sender_id, m.client_id, m.type, m.content, m.reply_to_id, m.link_preview,
  m.unsent_at, m.read_at, (m.created_at AT TIME ZONE current_setting('TimeZone')) AS created_at
`;

export const mediaColumns = (q: Sql) => q`
  id, conversation_id, uploader_id, kind, storage_key, width, height, duration_ms, waveform, message_id, role, created_at
`;

const storedPreviewSchema = z.object({
  url: z.string(),
  title: z.string().nullable(),
  description: z.string().nullable(),
  siteName: z.string().nullable(),
  imageMediaId: z.number().int().nullable(),
});

const waveformSchema = z.array(z.number());

function previewOf(raw: unknown): StoredLinkPreview | null {
  const parsed = storedPreviewSchema.safeParse(raw);
  return parsed.success ? parsed.data : null;
}

export function messageOf(row: MessageRow): MessageRecord {
  return {
    id: row.id,
    conversationId: row.conversation_id,
    senderId: row.sender_id,
    clientId: row.client_id,
    type: row.type,
    content: row.content,
    replyToId: row.reply_to_id,
    linkPreview: previewOf(row.link_preview),
    unsentAt: row.unsent_at,
    readAt: row.read_at,
    createdAt: row.created_at,
  };
}

export function mediaOf(row: MediaRow): MediaRecord {
  const waveform = waveformSchema.safeParse(row.waveform);
  return {
    id: row.id,
    conversationId: row.conversation_id,
    uploaderId: row.uploader_id,
    kind: row.kind,
    storageKey: row.storage_key,
    width: row.width,
    height: row.height,
    durationMs: row.duration_ms,
    waveform: waveform.success ? waveform.data : null,
    messageId: row.message_id,
    role: row.role,
    createdAt: row.created_at,
  };
}
