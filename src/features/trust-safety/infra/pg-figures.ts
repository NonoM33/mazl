import type { Sql } from "postgres";
import type { DashboardFigures, FiguresRepository } from "../application/ports";
import { SANCTION_KINDS, type SanctionKind } from "../domain/types";
import type { VerificationQueueItemDto } from "../presentation/dto";
import { num, numOrNull, text } from "./mappers";
import { loadTransparency } from "./pg-transparency";
import { countVerificationQueue, loadVerificationQueue } from "./pg-verification";

function round1(value: number | null): number | null {
  return value === null ? null : Math.round(value * 10) / 10;
}

export class PgFiguresRepository implements FiguresRepository {
  constructor(private readonly sql: Sql) {}

  transparency(from: Date, toExclusive: Date) {
    return loadTransparency(this.sql, from, toExclusive);
  }

  verificationQueue(limit: number): Promise<readonly VerificationQueueItemDto[]> {
    return loadVerificationQueue(this.sql, limit);
  }

  async dashboard(now: Date): Promise<DashboardFigures> {
    const [reports, daily, sanctions, appeals, members, other, pendingVerification] = await Promise.all([
      this.reportFigures(now),
      this.dailySeries(now),
      this.sql`SELECT kind, COUNT(*)::int AS total FROM member_sanctions WHERE created_at >= ${now}::timestamptz - interval '30 days' GROUP BY kind`,
      this.sql`
        SELECT COUNT(*) FILTER (WHERE status = 'pending')::int AS pending,
               COUNT(*) FILTER (WHERE decided_at >= ${now}::timestamptz - interval '30 days')::int AS decided,
               COUNT(*) FILTER (WHERE decided_at >= ${now}::timestamptz - interval '30 days' AND status = 'overturned')::int AS overturned
        FROM sanction_appeals`,
      this.sql`
        SELECT (SELECT COUNT(*)::int FROM users WHERE provider NOT IN ('seed', 'review')) AS total,
               (SELECT COUNT(*)::int FROM users WHERE provider NOT IN ('seed', 'review') AND created_at >= ${now}::timestamptz - interval '7 days') AS new7d,
               (SELECT COUNT(*)::int FROM users WHERE provider NOT IN ('seed', 'review') AND last_login_at >= ${now}::timestamptz - interval '7 days') AS active7d,
               (SELECT COUNT(*)::int FROM matches m WHERE m.created_at >= ${now}::timestamptz - interval '7 days'
                  AND NOT EXISTS (SELECT 1 FROM users s WHERE s.id IN (m.user1_id, m.user2_id) AND s.provider = 'seed')) AS matches7d,
               (SELECT COUNT(*)::int FROM profiles p JOIN users u ON u.id = p.user_id WHERE p.is_verified = true AND u.provider NOT IN ('seed', 'review')) AS verified`,
      this.sql`SELECT COUNT(*)::int AS open FROM authority_requests WHERE status IN ('received', 'in_progress')`,
      countVerificationQueue(this.sql),
    ]);
    const byKind = Object.fromEntries(SANCTION_KINDS.map((kind) => [kind, 0])) as Record<SanctionKind, number>;
    for (const row of sanctions) {
      const kind = SANCTION_KINDS.find((candidate) => candidate === row.kind);
      if (kind) byKind[kind] = num(row.total);
    }
    const decided = num(appeals[0]?.decided);
    const member = members[0];
    return {
      generatedAt: now.toISOString(),
      reports: { ...reports, daily },
      sanctions30d: byKind,
      appeals: {
        pending: num(appeals[0]?.pending),
        decided30d: decided,
        overturnRate30d: decided === 0 ? null : Math.round((num(appeals[0]?.overturned) / decided) * 1000) / 1000,
      },
      verification: { pending: pendingVerification, verifiedMembers: num(member?.verified) },
      members: { total: num(member?.total), new7d: num(member?.new7d), active7d: num(member?.active7d), matches7d: num(member?.matches7d) },
      authorities: { open: num(other[0]?.open) },
    };
  }

  private async reportFigures(now: Date) {
    const rows = await this.sql`
      SELECT
        (SELECT COUNT(*)::int FROM reports WHERE created_at >= ${now}::timestamptz - interval '7 days') AS received7d,
        (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch FROM (handled_at - created_at)) / 3600)
           FROM reports WHERE handled_at >= ${now}::timestamptz - interval '30 days') AS median
    `;
    return { receivedLast7d: num(rows[0]?.received7d), medianHandlingHours30d: round1(numOrNull(rows[0]?.median)) };
  }

  private async dailySeries(now: Date) {
    const rows = await this.sql`
      SELECT to_char(d.day, 'YYYY-MM-DD') AS day,
        (SELECT COUNT(*)::int FROM reports r WHERE r.created_at::date = d.day) AS received,
        (SELECT COUNT(*)::int FROM reports r WHERE r.handled_at::date = d.day) AS handled
      FROM generate_series((${now}::timestamptz AT TIME ZONE 'UTC')::date - 29, (${now}::timestamptz AT TIME ZONE 'UTC')::date, interval '1 day') AS d(day)
      ORDER BY d.day ASC
    `;
    return rows.map((row) => ({ day: text(row.day) ?? "", received: num(row.received), handled: num(row.handled) }));
  }
}
