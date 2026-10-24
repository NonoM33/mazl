import type { Sql } from "postgres";
import type {
  DecisionResult,
  MemberReportContext,
  ReportDecision,
  ReportedMessage,
  ReportFilter,
  ReportRow,
  ReportsRepository,
} from "../application/ports";
import { RECENT_SANCTION_DAYS } from "../domain/priority";
import { REPORT_REASONS, type ReportReason, type ReportStatus } from "../domain/types";
import { loadMemberRefs } from "./member-refs";
import { isoRequired, mapReason, mapStatus, num, numOrNull, text, type Row } from "./mappers";
import { insertSanction } from "./pg-sanctions";

const LIST_LIMIT = 2000;

const COLUMNS = (sql: Sql) => sql`
  r.id, r.created_at, r.reason, COALESCE(r.status, 'pending') AS status, r.assigned_to, r.reported_user_id,
  r.reporter_id, r.message_id, r.details, r.handled_by, r.handled_at, r.decision_note
`;

function statusCondition(sql: Sql, status: ReportStatus) {
  switch (status) {
    case "pending":
      return sql`COALESCE(r.status, 'pending') = 'pending'`;
    case "in_review":
      return sql`r.status = 'in_review'`;
    case "dismissed":
      return sql`r.status = 'dismissed'`;
    case "actioned":
      return sql`COALESCE(r.status, 'pending') NOT IN ('pending', 'in_review', 'dismissed')`;
  }
}

function reasonCondition(sql: Sql, reason: ReportReason | undefined) {
  if (!reason) return sql``;
  if (reason !== "other") return sql`AND lower(r.reason) = ${reason}`;
  const known = REPORT_REASONS.filter((candidate) => candidate !== "other");
  return sql`AND (lower(r.reason) = 'other' OR lower(r.reason) NOT IN ${sql(known)})`;
}

function assignedCondition(sql: Sql, assigned: ReportFilter["assigned"]) {
  if (assigned === "all") return sql``;
  if (assigned === "none") return sql`AND r.assigned_to IS NULL`;
  return sql`AND r.assigned_to = ${assigned.to}`;
}

export class PgReportsRepository implements ReportsRepository {
  constructor(private readonly sql: Sql) {}

  async list(filter: ReportFilter): Promise<readonly ReportRow[]> {
    const sql = this.sql;
    const statuses = filter.statuses.map((status) => statusCondition(sql, status));
    const statusSql = statuses.reduce((all, next) => sql`${all} OR ${next}`);
    const rows = await sql`
      SELECT ${COLUMNS(sql)} FROM reports r
      WHERE r.reported_user_id IS NOT NULL AND (${statusSql}) ${reasonCondition(sql, filter.reason)} ${assignedCondition(sql, filter.assigned)}
      ORDER BY r.created_at DESC, r.id DESC LIMIT ${LIST_LIMIT}
    `;
    return this.withMembers(rows);
  }

  async find(id: number): Promise<ReportRow | null> {
    const rows = await this.sql`SELECT ${COLUMNS(this.sql)} FROM reports r WHERE r.id = ${id} AND r.reported_user_id IS NOT NULL`;
    return (await this.withMembers(rows))[0] ?? null;
  }

  async against(memberId: number): Promise<readonly ReportRow[]> {
    const rows = await this.sql`
      SELECT ${COLUMNS(this.sql)} FROM reports r WHERE r.reported_user_id = ${memberId}
      ORDER BY r.created_at DESC, r.id DESC LIMIT 200
    `;
    return this.withMembers(rows);
  }

  async contexts(memberIds: readonly number[], now: Date): Promise<ReadonlyMap<number, MemberReportContext>> {
    const contexts = new Map<number, MemberReportContext>();
    if (memberIds.length === 0) return contexts;
    const rows = await this.sql`
      SELECT u.id,
        (SELECT COUNT(*)::int FROM reports r WHERE r.reported_user_id = u.id
           AND COALESCE(r.status, 'pending') IN ('pending', 'in_review')) AS open_reports,
        EXISTS (SELECT 1 FROM member_sanctions s WHERE s.user_id = u.id AND s.revoked_at IS NULL
           AND s.created_at >= ${now}::timestamptz - make_interval(days => ${RECENT_SANCTION_DAYS})) AS recent
      FROM users u WHERE u.id IN ${this.sql(memberIds)}
    `;
    for (const row of rows) contexts.set(num(row.id), { openReports: num(row.open_reports), sanctionedRecently: row.recent === true });
    return contexts;
  }

  async assign(id: number, to: string | null): Promise<ReportRow | null> {
    const rows = await this.sql`
      UPDATE reports SET
        assigned_to = ${to}::text,
        assigned_at = CASE WHEN ${to}::text IS NULL THEN NULL ELSE now() END,
        status = CASE
          WHEN ${to}::text IS NOT NULL AND COALESCE(status, 'pending') = 'pending' THEN 'in_review'
          WHEN ${to}::text IS NULL AND status = 'in_review' THEN 'pending'
          ELSE status END
      WHERE id = ${id} RETURNING id
    `;
    return rows.length === 0 ? null : this.find(id);
  }

  async decide(decision: ReportDecision): Promise<DecisionResult> {
    return this.sql.begin(async (transaction): Promise<DecisionResult> => {
      // postgres.js types TransactionSql without its call signature; it is one.
      const tx = transaction as unknown as Sql;
      const locked = await tx`SELECT COALESCE(status, 'pending') AS status FROM reports WHERE id = ${decision.reportId} FOR UPDATE`;
      const current = locked[0];
      if (!current) return { kind: "not_found" };
      if (current.status !== "pending" && current.status !== "in_review") return { kind: "already_decided" };
      const sanction = decision.sanction ? await insertSanction(tx, decision.sanction) : null;
      const status: ReportStatus = decision.outcome;
      await tx`
        UPDATE reports SET status = ${status}, handled_by = ${decision.decidedBy}, handled_at = now(),
          decision_note = ${decision.note}, action_taken = ${sanction ? sanction.kind : decision.outcome}
        WHERE id = ${decision.reportId}
      `;
      return { kind: "decided", status, sanction };
    });
  }

  async message(id: number): Promise<ReportedMessage | null> {
    const rows = await this.sql`SELECT id, type, content, unsent_at, created_at FROM messages WHERE id = ${id}`;
    const row = rows[0];
    if (!row) return null;
    return {
      id: num(row.id),
      content: row.type === "text" ? text(row.content) : null,
      unsent: row.unsent_at !== null,
      sentAt: isoRequired(row.created_at),
    };
  }

  private async withMembers(rows: readonly Row[]): Promise<ReportRow[]> {
    const refs = await loadMemberRefs(this.sql, [...new Set(rows.map((row) => num(row.reported_user_id)))]);
    const result: ReportRow[] = [];
    for (const row of rows) {
      const reported = refs.get(num(row.reported_user_id));
      if (!reported) continue;
      result.push({
        id: num(row.id),
        createdAt: new Date(isoRequired(row.created_at)),
        reason: mapReason(row.reason),
        status: mapStatus(row.status),
        assignedTo: text(row.assigned_to),
        reported,
        reporterId: numOrNull(row.reporter_id),
        messageId: numOrNull(row.message_id),
        details: text(row.details),
        handledBy: text(row.handled_by),
        handledAt: row.handled_at instanceof Date ? row.handled_at : null,
        decisionNote: text(row.decision_note),
      });
    }
    return result;
  }
}
