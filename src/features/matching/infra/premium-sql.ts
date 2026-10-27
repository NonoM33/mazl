import type { PendingQuery, Row, Sql } from "postgres";

type Fragment = PendingQuery<Row[]>;

// mazl+ as the subscriptions table says it (same rule as PgPlusStatus), for a
// column of the surrounding query.
export const hasActivePlus = (sql: Sql, userColumn: Fragment): Fragment =>
  sql`EXISTS (
    SELECT 1 FROM subscriptions su
    WHERE su.user_id = ${userColumn} AND su.status = 'active' AND su.expires_at > (NOW() AT TIME ZONE 'UTC')
  )`;

// A member in discreet mode (mazl+, docs/premium/MONETISATION.md section 3) who
// has not liked [viewerId]: they are not shown to that viewer.
export const hiddenByDiscreetMode = (sql: Sql, memberColumn: Fragment, viewerId: number): Fragment =>
  sql`(
    EXISTS (SELECT 1 FROM member_premium_settings ms WHERE ms.user_id = ${memberColumn} AND ms.incognito)
    AND ${hasActivePlus(sql, memberColumn)}
    AND NOT EXISTS (
      SELECT 1 FROM swipes liked
      WHERE liked.user_id = ${memberColumn} AND liked.target_user_id = ${viewerId} AND liked.action IN ('like', 'super_like')
    )
  )`;
