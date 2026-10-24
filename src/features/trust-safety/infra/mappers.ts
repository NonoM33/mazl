import { z } from "zod";
import { normalizeReason } from "../domain/priority";
import { DECISION_GROUNDS, SANCTION_KINDS, type ReportStatus } from "../domain/types";
import type { AppealDto, MemberRefDto, SanctionDto } from "../presentation/dto";

export type Row = Record<string, unknown>;

export function iso(value: unknown): string | null {
  return value instanceof Date ? value.toISOString() : null;
}

export function isoRequired(value: unknown): string {
  const text = iso(value);
  if (text === null) throw new Error("expected a timestamp column");
  return text;
}

export function text(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

export function num(value: unknown): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed)) throw new Error("expected a numeric column");
  return parsed;
}

export function numOrNull(value: unknown): number | null {
  return value === null || value === undefined ? null : num(value);
}

// Legacy statuses are mapped on read, the history is never rewritten.
export function mapStatus(raw: unknown): ReportStatus {
  const status = typeof raw === "string" ? raw : "pending";
  if (status === "pending" || status === "in_review" || status === "dismissed") return status;
  return "actioned";
}

export function mapReason(raw: unknown) {
  return normalizeReason(typeof raw === "string" ? raw : null);
}

const statementSchema = z.object({
  reference: z.string(),
  decision: z.enum(SANCTION_KINDS),
  scope: z.string(),
  facts: z.string(),
  ground: z.enum(DECISION_GROUNDS),
  groundText: z.string(),
  automatedDetection: z.boolean(),
  automatedDecision: z.literal(false),
  redress: z.string(),
  issuedAt: z.string(),
});

export function memberRef(row: Row): MemberRefDto {
  const verification = row.verification;
  return {
    id: num(row.id),
    displayName: text(row.display_name),
    photoUrl: text(row.photo_url),
    verification: verification === "identity" || verification === "selfie" ? verification : "none",
    active: row.is_active !== false,
  };
}

export function appealFrom(row: Row): AppealDto | null {
  if (row.a_id === null || row.a_id === undefined) return null;
  const status = row.a_status;
  return {
    id: num(row.a_id),
    sanctionId: num(row.id),
    memberId: num(row.user_id),
    createdAt: isoRequired(row.a_created_at),
    message: text(row.a_message) ?? "",
    status: status === "upheld" || status === "overturned" ? status : "pending",
    decidedBy: text(row.a_decided_by),
    decidedAt: iso(row.a_decided_at),
    decisionNote: text(row.a_decision_note),
    sanctionDecidedBy: text(row.decided_by) ?? "",
    sanctionKind: z.enum(SANCTION_KINDS).parse(row.kind),
  };
}

export function sanctionFrom(row: Row): SanctionDto {
  return {
    id: num(row.id),
    memberId: num(row.user_id),
    kind: z.enum(SANCTION_KINDS).parse(row.kind),
    ground: z.enum(DECISION_GROUNDS).parse(row.ground),
    startsAt: isoRequired(row.starts_at),
    endsAt: iso(row.ends_at),
    decidedBy: text(row.decided_by) ?? "",
    reportId: numOrNull(row.report_id),
    revokedAt: iso(row.revoked_at),
    revokedBy: text(row.revoked_by),
    statement: statementSchema.parse(row.statement),
    appeal: appealFrom(row),
  };
}
