import type { MessageType } from "./message-rules";

// Records as stored (rows), and views as sent to the app (CONTRAT.md §1).

export type MediaKind = "photo" | "voice";
// "attachment" belongs to the message's content; "preview" is the downloaded
// og:image of a link preview and is never listed among the attachments.
export type MediaRole = "attachment" | "preview";

export interface ConversationMembers {
  readonly id: number;
  readonly user1Id: number;
  readonly user2Id: number;
}

export interface StoredLinkPreview {
  readonly url: string;
  readonly title: string | null;
  readonly description: string | null;
  readonly siteName: string | null;
  readonly imageMediaId: number | null;
}

export interface MessageRecord {
  readonly id: number;
  readonly conversationId: number;
  readonly senderId: number;
  readonly clientId: string | null;
  readonly type: MessageType;
  readonly content: string;
  readonly replyToId: number | null;
  readonly linkPreview: StoredLinkPreview | null;
  readonly unsentAt: Date | null;
  readonly readAt: Date | null;
  readonly createdAt: Date;
}

export interface MediaRecord {
  readonly id: number;
  readonly conversationId: number;
  readonly uploaderId: number;
  readonly kind: MediaKind;
  readonly storageKey: string;
  readonly width: number | null;
  readonly height: number | null;
  readonly durationMs: number | null;
  readonly waveform: readonly number[] | null;
  readonly messageId: number | null;
  readonly role: MediaRole;
  readonly createdAt: Date;
}

export interface ReactionRecord {
  readonly messageId: number;
  readonly userId: number;
  readonly emoji: string;
}

export interface PhotoView {
  readonly id: number;
  readonly kind: "photo";
  readonly url: string;
  readonly width: number | null;
  readonly height: number | null;
}

export interface VoiceView {
  readonly id: number;
  readonly url: string;
  readonly duration_ms: number | null;
  readonly waveform: readonly number[] | null;
}

export interface ReactionView {
  readonly emoji: string;
  readonly user_ids: readonly number[];
}

export interface LinkPreviewView {
  readonly url: string;
  readonly title: string | null;
  readonly description: string | null;
  readonly image_url: string | null;
  readonly site_name: string | null;
}

export interface ReplyView {
  readonly id: number;
  readonly sender_id: number;
  readonly type: MessageType;
  readonly preview: string;
}

export interface MessageView {
  readonly id: number;
  readonly conversation_id: number;
  readonly sender_id: number;
  readonly client_id: string | null;
  readonly type: MessageType;
  readonly content: string;
  readonly media: readonly PhotoView[];
  readonly voice: VoiceView | null;
  readonly reply_to: ReplyView | null;
  readonly reactions: readonly ReactionView[];
  readonly link_preview: LinkPreviewView | null;
  readonly created_at: string;
  readonly read_at: string | null;
  readonly unsent: boolean;
  // Kept for app versions that predate read_at.
  readonly is_read: boolean;
}

// Result of POST /media, CONTRAT.md §2.
export type UploadedMediaView =
  | PhotoView
  | (VoiceView & { readonly kind: "voice" });
