export type RetentionUnit = "days" | "months" | "years";

export type RetentionTable = "location_updates" | "face_verification_sessions" | "moderation_logs" | "banned_document_fingerprints";
export type RetentionColumn = "created_at" | "banned_at";

export interface RetentionRule {
  readonly table: RetentionTable;
  readonly column: RetentionColumn;
  readonly amount: number;
  readonly unit: RetentionUnit;
  // A row is kept while it is still live, whatever its age (an unexpired session).
  readonly keepWhileUnexpired: boolean;
}

// The retention periods announced in the privacy policy.
export const RETENTION_RULES: readonly RetentionRule[] = [
  { table: "location_updates", column: "created_at", amount: 30, unit: "days", keepWhileUnexpired: false },
  { table: "face_verification_sessions", column: "created_at", amount: 12, unit: "months", keepWhileUnexpired: true },
  { table: "moderation_logs", column: "created_at", amount: 12, unit: "months", keepWhileUnexpired: false },
  { table: "banned_document_fingerprints", column: "banned_at", amount: 5, unit: "years", keepWhileUnexpired: false },
];

export const RETENTION_INTERVAL_MS = 6 * 60 * 60 * 1000;
