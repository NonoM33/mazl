import type { Sql } from "postgres";
import { coupleSubscriptionOf, NO_PREMIUM, type CouplePremium, type MemberSubscription } from "../domain/premium";

// The subscriptions of the two members of a couple. Timestamps of the
// subscriptions table are UTC without zone: read back as UTC instants.
interface Row {
  user_id: number;
  plan_type: string | null;
  status: string;
  expires_at: Date | null;
}

export class PgCouplePremium {
  constructor(private readonly sql: Sql) {}

  async of(viewerId: number, coupleId: number, now: Date = new Date()): Promise<CouplePremium> {
    const rows = await this.sql<Row[]>`
      SELECT s.user_id, s.plan_type, s.status, (s.expires_at AT TIME ZONE 'UTC') AS expires_at
      FROM couples c
      JOIN subscriptions s ON s.user_id IN (c.user1_id, c.user2_id)
      WHERE c.id = ${coupleId} AND c.status = 'active'
        AND ${viewerId} IN (c.user1_id, c.user2_id)
    `;
    if (rows.length === 0) return NO_PREMIUM;
    const subscriptions: MemberSubscription[] = rows.map((row) => ({
      userId: row.user_id,
      planType: row.plan_type,
      status: row.status,
      expiresAt: row.expires_at === null ? null : new Date(row.expires_at),
    }));
    return coupleSubscriptionOf(viewerId, subscriptions, now);
  }
}
