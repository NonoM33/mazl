import type { AuditTargetType } from "../application/ports";

// GET /api/backoffice/audit?actor&action&targetType&targetId&limit&offset   (audit.read)
export interface AuditEntryDto {
  readonly id: number;
  readonly createdAt: string;
  readonly actor: string;
  readonly action: string;
  readonly targetType: AuditTargetType;
  readonly targetId: string | null;
  readonly justification: string | null;
  readonly details: Readonly<Record<string, unknown>> | null;
  readonly hash: string;
}

export interface AuditPageDto {
  readonly entries: readonly AuditEntryDto[];
  readonly total: number;
}

// GET /api/backoffice/audit/verify   (audit.read)
export type AuditVerificationDto =
  | { readonly ok: true; readonly entries: number; readonly headHash: string }
  | { readonly ok: false; readonly brokenAtId: number; readonly entries: number };
