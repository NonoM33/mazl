import { DISPLAYED_REACTIONS, replyPreview } from "../domain/message-rules";
import type {
  LinkPreviewView,
  MediaRecord,
  MessageRecord,
  MessageView,
  PhotoView,
  ReactionRecord,
  ReactionView,
  ReplyView,
  VoiceView,
} from "../domain/types";
import type { MessageRepository } from "./ports";

// Turns stored rows into the shape of CONTRAT.md §1: media URLs signed, replies
// summarised, reactions grouped, an unsent message emptied.

export interface MessagePresenter {
  present(records: readonly MessageRecord[]): Promise<MessageView[]>;
}

export interface PresenterDeps {
  readonly repository: Pick<MessageRepository, "media" | "reactions" | "findByIds">;
  readonly signUrl: (mediaId: number) => string;
}

function groupBy<T>(items: readonly T[], keyOf: (item: T) => number): Map<number, T[]> {
  const groups = new Map<number, T[]>();
  for (const item of items) {
    const key = keyOf(item);
    const list = groups.get(key);
    if (list) list.push(item);
    else groups.set(key, [item]);
  }
  return groups;
}

function groupReactions(reactions: readonly ReactionRecord[]): ReactionView[] {
  return DISPLAYED_REACTIONS.flatMap((emoji) => {
    const userIds = reactions
      .filter((reaction) => reaction.emoji === emoji)
      .map((reaction) => reaction.userId)
      .sort((a, b) => a - b);
    return userIds.length > 0 ? [{ emoji, user_ids: userIds }] : [];
  });
}

export function createMessagePresenter(deps: PresenterDeps): MessagePresenter {
  const { repository, signUrl } = deps;

  function photoOf(media: MediaRecord): PhotoView {
    return { id: media.id, kind: "photo", url: signUrl(media.id), width: media.width, height: media.height };
  }

  function voiceOf(media: MediaRecord): VoiceView {
    return { id: media.id, url: signUrl(media.id), duration_ms: media.durationMs, waveform: media.waveform };
  }

  function linkPreviewOf(record: MessageRecord, attached: readonly MediaRecord[]): LinkPreviewView | null {
    const preview = record.linkPreview;
    if (preview === null) return null;
    const image = attached.find((media) => media.id === preview.imageMediaId && media.role === "preview");
    return {
      url: preview.url,
      title: preview.title,
      description: preview.description,
      image_url: image ? signUrl(image.id) : null,
      site_name: preview.siteName,
    };
  }

  function replyOf(record: MessageRecord, parents: ReadonlyMap<number, MessageRecord>): ReplyView | null {
    if (record.replyToId === null) return null;
    const parent = parents.get(record.replyToId);
    if (parent === undefined) return null;
    return {
      id: parent.id,
      sender_id: parent.senderId,
      type: parent.type,
      preview: replyPreview({ type: parent.type, content: parent.content, unsent: parent.unsentAt !== null }),
    };
  }

  async function present(records: readonly MessageRecord[]): Promise<MessageView[]> {
    if (records.length === 0) return [];
    const ids = records.map((record) => record.id);
    const parentIds = [...new Set(records.flatMap((record) => (record.replyToId === null ? [] : [record.replyToId])))];
    const [mediaRows, reactionRows, parentRows] = await Promise.all([
      repository.media(ids),
      repository.reactions(ids),
      parentIds.length > 0 ? repository.findByIds(parentIds) : Promise.resolve<MessageRecord[]>([]),
    ]);
    const mediaByMessage = groupBy(mediaRows, (media) => media.messageId ?? 0);
    const reactionsByMessage = groupBy(reactionRows, (reaction) => reaction.messageId);
    const parents = new Map(parentRows.map((parent) => [parent.id, parent]));

    return records.map((record): MessageView => {
      const unsent = record.unsentAt !== null;
      const attached = unsent ? [] : (mediaByMessage.get(record.id) ?? []);
      const attachments = attached.filter((media) => media.role === "attachment");
      const voice = attachments.find((media) => media.kind === "voice");
      return {
        id: record.id,
        conversation_id: record.conversationId,
        sender_id: record.senderId,
        client_id: record.clientId,
        type: record.type,
        content: unsent ? "" : record.content,
        media: attachments.filter((media) => media.kind === "photo").map(photoOf),
        voice: voice ? voiceOf(voice) : null,
        reply_to: replyOf(record, parents),
        reactions: unsent ? [] : groupReactions(reactionsByMessage.get(record.id) ?? []),
        link_preview: unsent ? null : linkPreviewOf(record, attached),
        created_at: record.createdAt.toISOString(),
        read_at: record.readAt?.toISOString() ?? null,
        unsent,
        is_read: record.readAt !== null,
      };
    });
  }

  return { present };
}
