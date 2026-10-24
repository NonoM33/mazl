import type { Sql } from "postgres";
import type { ConversationReader, ReportRow } from "../application/ports";
import type { ConversationDto } from "../presentation/dto";
import { loadMemberRefs } from "./member-refs";
import { isoRequired, num, numOrNull, text } from "./mappers";

const MESSAGE_LIMIT = 500;

export class PgConversationReader implements ConversationReader {
  constructor(private readonly sql: Sql) {}

  async forReport(report: ReportRow): Promise<ConversationDto> {
    const conversationId = await this.findConversationId(report);
    const refs = await loadMemberRefs(this.sql, [report.reported.id, ...(report.reporterId === null ? [] : [report.reporterId])]);
    const participants = [...refs.values()];
    if (conversationId === null) return { conversationId: null, participants, messages: [] };
    const rows = await this.sql`
      SELECT id, sender_id, type, content, unsent_at, created_at FROM (
        SELECT id, sender_id, type, content, unsent_at, created_at FROM messages
        WHERE conversation_id = ${conversationId} ORDER BY id DESC LIMIT ${MESSAGE_LIMIT}
      ) latest ORDER BY id ASC
    `;
    return {
      conversationId,
      participants,
      messages: rows.map((row) => {
        const type = row.type === "photo" || row.type === "voice" ? row.type : "text";
        return {
          id: num(row.id),
          senderId: num(row.sender_id),
          type,
          // Photos and voice notes are never shown here: only their existence.
          content: type === "text" ? text(row.content) : null,
          sentAt: isoRequired(row.created_at),
          unsent: row.unsent_at !== null,
          reported: num(row.id) === report.messageId,
        };
      }),
    };
  }

  private async findConversationId(report: ReportRow): Promise<number | null> {
    if (report.messageId !== null) {
      const rows = await this.sql`SELECT conversation_id FROM messages WHERE id = ${report.messageId}`;
      const found = numOrNull(rows[0]?.conversation_id);
      if (found !== null) return found;
    }
    if (report.reporterId === null) return null;
    const rows = await this.sql`
      SELECT id FROM conversations
      WHERE (user1_id = ${report.reporterId} AND user2_id = ${report.reported.id})
         OR (user1_id = ${report.reported.id} AND user2_id = ${report.reporterId})
      ORDER BY COALESCE(last_message_at, created_at) DESC LIMIT 1
    `;
    return numOrNull(rows[0]?.id);
  }
}
