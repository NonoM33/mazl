import type { Sql } from "postgres";
import type { PlusStatus } from "../application/ports";

// mazl+ is a subscriptions row that is active and not yet expired, or the
// MAZL Couple subscription of the partner of an active couple (one pays, both
// have the rights: docs/couple/ESPACE-COUPLE.md section 1). The expiry column
// is a TIMESTAMP holding UTC (see PgSubscriptionRepository), so it is compared
// with the current time expressed in UTC.
export class PgPlusStatus implements PlusStatus {
  constructor(private readonly sql: Sql) {}

  async isPlus(userId: number): Promise<boolean> {
    const rows = await this.sql`
      SELECT 1 AS active FROM subscriptions
      WHERE user_id = ${userId} AND status = 'active' AND expires_at > (NOW() AT TIME ZONE 'UTC')
      UNION ALL
      SELECT 1 FROM couples c
      JOIN subscriptions s ON s.user_id = CASE WHEN c.user1_id = ${userId} THEN c.user2_id ELSE c.user1_id END
      WHERE c.status = 'active' AND ${userId} IN (c.user1_id, c.user2_id)
        AND s.plan_type = 'couple_monthly' AND s.status = 'active' AND s.expires_at > (NOW() AT TIME ZONE 'UTC')
      LIMIT 1
    `;
    return rows.length > 0;
  }
}
