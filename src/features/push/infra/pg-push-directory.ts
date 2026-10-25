import type { Sql } from "postgres";
import type { PushAudience, PushDirectory } from "../application/ports";

// Whether a push between two members may be sent, and the name to put in it.
// One round trip. Refused when either account is deactivated or deleted (a ban
// also deactivates), carries an active restriction, suspension or ban, or when
// either member blocked the other.
export class PgPushDirectory implements PushDirectory {
  constructor(private readonly sql: Sql) {}

  async audience(recipientId: number, actorId: number): Promise<PushAudience> {
    const [row] = await this.sql<{ recipient_active: boolean | null; actor_active: boolean | null; display_name: string | null; blocked: boolean; sanctioned: boolean }[]>`
      SELECT r.is_active AS recipient_active, a.is_active AS actor_active, p.display_name,
        EXISTS (
          SELECT 1 FROM blocked_users b
          WHERE (b.blocker_id = r.id AND b.blocked_id = a.id) OR (b.blocker_id = a.id AND b.blocked_id = r.id)
        ) AS blocked,
        EXISTS (
          SELECT 1 FROM member_sanctions s
          WHERE s.user_id IN (r.id, a.id) AND s.revoked_at IS NULL AND s.starts_at <= now()
            AND (s.ends_at IS NULL OR s.ends_at > now())
            AND s.kind IN ('restriction', 'suspension', 'ban')
        ) AS sanctioned
      FROM users r
      JOIN users a ON a.id = ${actorId}
      LEFT JOIN profiles p ON p.user_id = a.id
      WHERE r.id = ${recipientId}`;
    if (row === undefined) return { deliverable: false, actorName: null };
    const active = row.recipient_active !== false && row.actor_active !== false;
    return { deliverable: active && !row.blocked && !row.sanctioned, actorName: row.display_name };
  }
}
