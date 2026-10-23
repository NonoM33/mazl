import type { Sql } from "postgres";
import { sql, isBlockedBetween } from "../../../db";
import type { InsertOutcome, MessageRepository, NewMessage } from "../application/ports";
import type { ConversationMembers, MediaRecord, MessageRecord, ReactionRecord } from "../domain/types";
import { mediaColumns, mediaOf, messageColumns, messageOf, type MediaRow, type MessageRow } from "./row-mappers";

// postgres.js loses the call signature on transaction handles in its typings.
const asSql = (transaction: unknown): Sql => transaction as Sql;

const INT4 = 23;

class Rollback extends Error {
  constructor(readonly outcome: InsertOutcome) {
    super("rollback");
  }
}

interface ConversationRow {
  id: number;
  user1_id: number;
  user2_id: number;
}

const membersOf = (row: ConversationRow): ConversationMembers => ({ id: row.id, user1Id: row.user1_id, user2Id: row.user2_id });

async function insertInTransaction(tx: Sql, input: NewMessage): Promise<InsertOutcome> {
  if (input.replyToId !== null) {
    const parent = await tx`SELECT 1 FROM messages WHERE id = ${input.replyToId} AND conversation_id = ${input.conversationId}`;
    if (parent.length === 0) return { kind: "reply_unusable" };
  }
  const inserted = await tx<MessageRow[]>`
    INSERT INTO messages (conversation_id, sender_id, client_id, type, content, reply_to_id)
    VALUES (${input.conversationId}, ${input.senderId}, ${input.clientId}, ${input.type}, ${input.content}, ${input.replyToId})
    ON CONFLICT (conversation_id, sender_id, client_id) DO NOTHING
    RETURNING id
  `;
  const created = inserted[0];
  if (created === undefined) {
    const existing = await tx<MessageRow[]>`
      SELECT ${messageColumns(tx)} FROM messages m
      WHERE m.conversation_id = ${input.conversationId} AND m.sender_id = ${input.senderId} AND m.client_id = ${input.clientId}
    `;
    const row = existing[0];
    return row === undefined ? { kind: "media_unusable" } : { kind: "existing", message: messageOf(row) };
  }

  if (input.mediaIds.length > 0) {
    const ids = tx.array([...input.mediaIds], INT4);
    const attached = await tx`
      UPDATE message_media SET message_id = ${created.id}, position = array_position(${ids}, id)
      WHERE id = ANY(${ids}) AND conversation_id = ${input.conversationId} AND uploader_id = ${input.senderId}
        AND message_id IS NULL AND role = 'attachment' AND kind = ${input.type === "voice" ? "voice" : "photo"}
      RETURNING id
    `;
    if (attached.length !== input.mediaIds.length) throw new Rollback({ kind: "media_unusable" });
  }
  await tx`UPDATE conversations SET last_message_at = NOW() WHERE id = ${input.conversationId}`;
  const row = (await tx<MessageRow[]>`SELECT ${messageColumns(tx)} FROM messages m WHERE m.id = ${created.id}`)[0];
  if (row === undefined) throw new Rollback({ kind: "media_unusable" });
  return { kind: "created", message: messageOf(row) };
}

export const postgresMessageRepository: MessageRepository = {
  async findConversationOf(conversationId, userId) {
    const rows = await sql<ConversationRow[]>`
      SELECT id, user1_id, user2_id FROM conversations
      WHERE id = ${conversationId} AND (user1_id = ${userId} OR user2_id = ${userId})
    `;
    return rows[0] === undefined ? null : membersOf(rows[0]);
  },

  isBlocked: (userA, userB) => isBlockedBetween(userA, userB),

  async list(conversationId, before, limit) {
    const rows = await sql<MessageRow[]>`
      SELECT ${messageColumns(sql)} FROM messages m
      WHERE m.conversation_id = ${conversationId} ${before === null ? sql`` : sql`AND m.id < ${before}`}
      ORDER BY m.id DESC LIMIT ${limit}
    `;
    return rows.map(messageOf);
  },

  async findByIds(ids) {
    if (ids.length === 0) return [];
    const rows = await sql<MessageRow[]>`SELECT ${messageColumns(sql)} FROM messages m WHERE m.id = ANY(${sql.array([...ids], INT4)})`;
    return rows.map(messageOf);
  },

  async findForMember(messageId, userId) {
    const rows = await sql<Array<MessageRow & { user1_id: number; user2_id: number }>>`
      SELECT ${messageColumns(sql)}, c.user1_id, c.user2_id
      FROM messages m JOIN conversations c ON c.id = m.conversation_id
      WHERE m.id = ${messageId} AND (c.user1_id = ${userId} OR c.user2_id = ${userId})
    `;
    const row = rows[0];
    if (row === undefined) return null;
    return {
      message: messageOf(row),
      conversation: { id: row.conversation_id, user1Id: row.user1_id, user2Id: row.user2_id },
    };
  },

  async insert(input) {
    try {
      return await sql.begin((tx) => insertInTransaction(asSql(tx), input));
    } catch (error: unknown) {
      if (error instanceof Rollback) return error.outcome;
      throw error;
    }
  },

  async media(messageIds) {
    if (messageIds.length === 0) return [];
    const rows = await sql<MediaRow[]>`
      SELECT ${mediaColumns(sql)} FROM message_media
      WHERE message_id = ANY(${sql.array([...messageIds], INT4)}) ORDER BY position, id
    `;
    return rows.map(mediaOf);
  },

  async reactions(messageIds) {
    if (messageIds.length === 0) return [];
    const rows = await sql<Array<{ message_id: number; user_id: number; emoji: string }>>`
      SELECT message_id, user_id, emoji FROM message_reactions WHERE message_id = ANY(${sql.array([...messageIds], INT4)})
    `;
    return rows.map((row): ReactionRecord => ({ messageId: row.message_id, userId: row.user_id, emoji: row.emoji }));
  },

  async toggleReaction(messageId, userId, emoji) {
    await sql.begin(async (transaction) => {
      const tx = asSql(transaction);
      const removed = await tx`
        DELETE FROM message_reactions WHERE message_id = ${messageId} AND user_id = ${userId} AND emoji = ${emoji} RETURNING 1
      `;
      if (removed.length > 0) return;
      await tx`
        INSERT INTO message_reactions (message_id, user_id, emoji) VALUES (${messageId}, ${userId}, ${emoji})
        ON CONFLICT (message_id, user_id) DO UPDATE SET emoji = EXCLUDED.emoji, created_at = NOW()
      `;
    });
  },

  async unsend(messageId, at): Promise<MediaRecord[] | null> {
    return sql.begin(async (transaction) => {
      const tx = asSql(transaction);
      // RETENTION CHOICE: a message that a report points at keeps its text, so that
      // unsending cannot destroy the evidence. The only reader is the admin
      // moderation list (db.ts getReports, `reported_message_content`); the
      // presenter hides the text of every unsent message from members. It is
      // deleted with the conversation (account deletion).
      const marked = await tx`
        UPDATE messages SET unsent_at = ${at}, link_preview = NULL,
          content = CASE WHEN EXISTS (SELECT 1 FROM reports r WHERE r.message_id = messages.id) THEN content ELSE '' END
        WHERE id = ${messageId} AND unsent_at IS NULL
        RETURNING id
      `;
      if (marked.length === 0) return null;
      await tx`DELETE FROM message_reactions WHERE message_id = ${messageId}`;
      const removed = await tx<MediaRow[]>`DELETE FROM message_media WHERE message_id = ${messageId} RETURNING ${mediaColumns(tx)}`;
      return removed.map(mediaOf);
    });
  },

  async markRead(conversationId, readerId, upToId, at) {
    const rows = await sql<Array<{ id: number }>>`
      UPDATE messages SET read_at = ${at}, is_read = true
      WHERE conversation_id = ${conversationId} AND sender_id <> ${readerId} AND read_at IS NULL
        ${upToId === null ? sql`` : sql`AND id <= ${upToId}`}
      RETURNING id
    `;
    if (rows.length === 0) return null;
    return { upToId: Math.max(...rows.map((row) => row.id)), readAt: at };
  },

  async report(input) {
    const rows = await sql`
      INSERT INTO reports (reporter_id, reported_user_id, reason, details, message_id)
      VALUES (${input.reporterId}, ${input.reportedUserId}, ${input.reason}, ${input.details}, ${input.messageId})
      ON CONFLICT (reporter_id, message_id) WHERE message_id IS NOT NULL DO NOTHING
      RETURNING id
    `;
    return rows.length > 0;
  },

  async attachPreview({ messageId, preview, image }) {
    return sql.begin(async (transaction) => {
      const tx = asSql(transaction);
      const live = await tx`SELECT id FROM messages WHERE id = ${messageId} AND unsent_at IS NULL FOR UPDATE`;
      if (live.length === 0) return null;
      let imageMediaId: number | null = null;
      if (image !== null) {
        const stored = await tx<Array<{ id: number }>>`
          INSERT INTO message_media (conversation_id, uploader_id, kind, storage_key, width, height, message_id, role, position)
          VALUES (${image.conversationId}, ${image.uploaderId}, ${image.kind}, ${image.storageKey}, ${image.width}, ${image.height},
                  ${messageId}, 'preview', 0)
          RETURNING id
        `;
        imageMediaId = stored[0]?.id ?? null;
      }
      const document = { ...preview, imageMediaId };
      const rows = await tx<MessageRow[]>`
        UPDATE messages m SET link_preview = ${tx.json(document)} WHERE m.id = ${messageId}
        RETURNING ${messageColumns(tx)}
      `;
      return rows[0] === undefined ? null : (messageOf(rows[0]) satisfies MessageRecord);
    });
  },
};
