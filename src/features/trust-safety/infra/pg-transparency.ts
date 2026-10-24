import type { Sql } from "postgres";
import { normalizeReason } from "../domain/priority";
import {
  AUTHORITY_KINDS,
  DECISION_GROUNDS,
  REPORT_REASONS,
  SANCTION_KINDS,
  type AuthorityKind,
  type DecisionGround,
  type ReportReason,
  type SanctionKind,
} from "../domain/types";
import type { TransparencyDto } from "../presentation/dto";
import { num, numOrNull, type Row } from "./mappers";

function zeroed<K extends string>(keys: readonly K[]): Record<K, number> {
  return Object.fromEntries(keys.map((key) => [key, 0])) as Record<K, number>;
}

function round1(value: number | null): number | null {
  return value === null ? null : Math.round(value * 10) / 10;
}

function tally<K extends string>(rows: readonly Row[], keys: readonly K[], pick: (raw: unknown) => K | null): Record<K, number> {
  const counts = zeroed(keys);
  for (const row of rows) {
    const key = pick(row.key);
    if (key !== null) counts[key] += num(row.total);
  }
  return counts;
}

function oneOf<K extends string>(keys: readonly K[]): (raw: unknown) => K | null {
  return (raw) => keys.find((key) => key === raw) ?? null;
}

// DSA art. 15 figures for [from, toExclusive). Dates are UTC calendar days.
export async function loadTransparency(sql: Sql, from: Date, toExclusive: Date): Promise<Omit<TransparencyDto, "from" | "to">> {
  const [notices, kinds, grounds, authorities, figures] = await Promise.all([
    sql`SELECT lower(reason) AS key, COUNT(*)::int AS total FROM reports WHERE created_at >= ${from} AND created_at < ${toExclusive} GROUP BY 1`,
    sql`SELECT kind AS key, COUNT(*)::int AS total FROM member_sanctions WHERE created_at >= ${from} AND created_at < ${toExclusive} GROUP BY 1`,
    sql`SELECT ground AS key, COUNT(*)::int AS total FROM member_sanctions WHERE created_at >= ${from} AND created_at < ${toExclusive} GROUP BY 1`,
    sql`SELECT kind AS key, COUNT(*)::int AS total FROM authority_requests WHERE received_at >= ${from} AND received_at < ${toExclusive} GROUP BY 1`,
    sql`
      SELECT
        (SELECT COUNT(*)::int FROM reports WHERE created_at >= ${from} AND created_at < ${toExclusive}
           AND COALESCE(status, 'pending') NOT IN ('pending', 'in_review', 'dismissed')) AS actioned,
        (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch FROM (handled_at - created_at)) / 3600)
           FROM reports WHERE created_at >= ${from} AND created_at < ${toExclusive} AND handled_at IS NOT NULL) AS handling_median,
        (SELECT COUNT(*)::int FROM sanction_appeals WHERE created_at >= ${from} AND created_at < ${toExclusive}) AS appeals,
        (SELECT COUNT(*)::int FROM sanction_appeals WHERE created_at >= ${from} AND created_at < ${toExclusive}
           AND status = 'overturned') AS overturned,
        (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch FROM (decided_at - created_at)) / 3600)
           FROM sanction_appeals WHERE created_at >= ${from} AND created_at < ${toExclusive} AND decided_at IS NOT NULL) AS appeal_median
    `,
  ]);
  const row = figures[0];
  const received = zeroed<ReportReason>(REPORT_REASONS);
  for (const notice of notices) received[normalizeReason(typeof notice.key === "string" ? notice.key : null)] += num(notice.total);
  return {
    noticesReceived: received,
    noticesActioned: num(row?.actioned),
    medianHandlingHours: round1(numOrNull(row?.handling_median)),
    sanctionsByKind: tally<SanctionKind>(kinds, SANCTION_KINDS, oneOf(SANCTION_KINDS)),
    sanctionsByGround: tally<DecisionGround>(grounds, DECISION_GROUNDS, oneOf(DECISION_GROUNDS)),
    appealsReceived: num(row?.appeals),
    appealsOverturned: num(row?.overturned),
    medianAppealHours: round1(numOrNull(row?.appeal_median)),
    authorityRequests: tally<AuthorityKind>(authorities, AUTHORITY_KINDS, oneOf(AUTHORITY_KINDS)),
    automatedDecisions: 0,
  };
}
