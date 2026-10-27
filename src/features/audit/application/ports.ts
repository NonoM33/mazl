// Immutable audit journal of every staff action (docs/backoffice/CADRAGE.md §5).
// Append-only: the table refuses UPDATE and DELETE (trigger), and each entry
// carries the SHA-256 of the previous one, so removing or editing a row breaks
// the chain and `verify` says where.

export type AuditTargetType =
  | "member"
  | "report"
  | "sanction"
  | "appeal"
  | "conversation"
  | "verification"
  | "authority_request"
  | "matching_params"
  | "storefront_product"
  | "storefront_campaign"
  | "concierge_request"
  | "staff"
  | "photo"
  | "system";

export interface AuditEntryInput {
  readonly actor: string;
  // Dotted verb: "report.decide", "conversation.read", "matching.publish"…
  readonly action: string;
  readonly targetType: AuditTargetType;
  readonly targetId: string | null;
  // Mandatory free text for sensitive reads (why the staff member looked).
  readonly justification?: string;
  // Small structured details. NEVER message contents, documents or secrets.
  readonly details?: Readonly<Record<string, unknown>>;
}

export interface AuditEntry extends AuditEntryInput {
  readonly id: number;
  readonly createdAt: string;
  readonly previousHash: string;
  readonly hash: string;
}

export interface AuditFilter {
  readonly actor?: string;
  readonly action?: string;
  readonly targetType?: AuditTargetType;
  readonly targetId?: string;
  readonly limit: number;
  readonly offset: number;
}

export type ChainVerification =
  | { readonly ok: true; readonly entries: number; readonly headHash: string }
  | { readonly ok: false; readonly brokenAtId: number; readonly entries: number };

export interface AuditLog {
  record(entry: AuditEntryInput): Promise<AuditEntry>;
  list(filter: AuditFilter): Promise<{ readonly entries: readonly AuditEntry[]; readonly total: number }>;
  verify(): Promise<ChainVerification>;
}
