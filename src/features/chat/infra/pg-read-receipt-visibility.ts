import type { Sql } from "postgres";
import { receiptKey, type ReadReceiptVisibility } from "../application/ports";

// An author sees that a message was read when they are a mazl+ member (the
// subscriptions table, as PgPlusStatus reads it) and the other member of the
// conversation has not turned off « Envoyer les confirmations de lecture »
// (on by default).
export class PgReadReceiptVisibility implements ReadReceiptVisibility {
  constructor(private readonly sql: Sql) {}

  async authorsWhoMaySee(pairs: readonly { readonly conversationId: number; readonly authorId: number }[]): Promise<ReadonlySet<string>> {
    if (pairs.length === 0) return new Set();
    const conversations = pairs.map((pair) => pair.conversationId);
    const authors = pairs.map((pair) => pair.authorId);
    const rows = await this.sql<{ conversation_id: number; author_id: number }[]>`
      SELECT asked.conversation_id, asked.author_id
      FROM unnest(${this.sql.array(conversations, 23)}::int[], ${this.sql.array(authors, 23)}::int[]) AS asked(conversation_id, author_id)
      JOIN conversations c ON c.id = asked.conversation_id
      LEFT JOIN member_premium_settings reader
        ON reader.user_id = CASE WHEN c.user1_id = asked.author_id THEN c.user2_id ELSE c.user1_id END
      WHERE COALESCE(reader.send_read_receipts, true)
        AND EXISTS (
          SELECT 1 FROM subscriptions su
          WHERE su.user_id = asked.author_id AND su.status = 'active' AND su.expires_at > (NOW() AT TIME ZONE 'UTC')
        )
    `;
    return new Set(rows.map((row) => receiptKey(row.conversation_id, row.author_id)));
  }
}
