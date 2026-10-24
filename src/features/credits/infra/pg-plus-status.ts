import type { Sql } from "postgres";
import type { PlusStatus } from "../application/ports";

// mazl+ is a subscriptions row that is active and not yet expired. The expiry
// column is a TIMESTAMP holding UTC (see PgSubscriptionRepository), so it is
// compared with the current time expressed in UTC.
export class PgPlusStatus implements PlusStatus {
  constructor(private readonly sql: Sql) {}

  async isPlus(userId: number): Promise<boolean> {
    const rows = await this.sql`
      SELECT 1 AS active FROM subscriptions
      WHERE user_id = ${userId} AND status = 'active' AND expires_at > (NOW() AT TIME ZONE 'UTC')
      LIMIT 1
    `;
    return rows.length > 0;
  }
}
