import type {
  AppealDto,
  AuthorityRequestDto,
  ConversationDto,
  DashboardDto,
  MemberFileDto,
  MemberRefDto,
  SanctionDto,
  TransparencyDto,
  VerificationQueueItemDto,
} from "../presentation/dto";
import type { RecentMessage } from "../domain/risk-signals";
import type {
  AppealStatus,
  AuthorityKind,
  AuthorityStatus,
  DecisionGround,
  ReportReason,
  ReportStatus,
  SanctionKind,
  StatementOfReasons,
} from "../domain/types";

// ---- Reports -------------------------------------------------------------

export interface ReportRow {
  readonly id: number;
  readonly createdAt: Date;
  readonly reason: ReportReason;
  readonly status: ReportStatus;
  readonly assignedTo: string | null;
  readonly reported: MemberRefDto;
  readonly reporterId: number | null;
  readonly messageId: number | null;
  readonly details: string | null;
  readonly handledBy: string | null;
  readonly handledAt: Date | null;
  readonly decisionNote: string | null;
}

export interface ReportFilter {
  readonly statuses: readonly ReportStatus[];
  readonly reason?: ReportReason;
  readonly assigned: "all" | "none" | { readonly to: string };
}

export interface MemberReportContext {
  readonly openReports: number;
  readonly sanctionedRecently: boolean;
}

export interface NewSanction {
  readonly memberId: number;
  readonly kind: SanctionKind;
  readonly ground: DecisionGround;
  readonly startsAt: Date;
  readonly endsAt: Date | null;
  readonly decidedBy: string;
  readonly reportId: number | null;
  readonly statement: StatementOfReasons;
  readonly appealCodeHash: string;
  readonly note: string | null;
}

export interface ReportDecision {
  readonly reportId: number;
  readonly outcome: "dismissed" | "actioned";
  readonly note: string;
  readonly decidedBy: string;
  readonly sanction: NewSanction | null;
}

export type DecisionResult =
  | { readonly kind: "decided"; readonly status: ReportStatus; readonly sanction: SanctionDto | null }
  | { readonly kind: "not_found" }
  | { readonly kind: "already_decided" };

export interface ReportedMessage {
  readonly id: number;
  readonly content: string | null;
  readonly unsent: boolean;
  readonly sentAt: string;
}

export interface ReportsRepository {
  // Up to 2000 rows, newest first.
  list(filter: ReportFilter): Promise<readonly ReportRow[]>;
  find(id: number): Promise<ReportRow | null>;
  against(memberId: number): Promise<readonly ReportRow[]>;
  contexts(memberIds: readonly number[], now: Date): Promise<ReadonlyMap<number, MemberReportContext>>;
  assign(id: number, to: string | null): Promise<ReportRow | null>;
  // One transaction: the report, and the sanction when there is one.
  decide(decision: ReportDecision): Promise<DecisionResult>;
  message(id: number): Promise<ReportedMessage | null>;
}

export interface ConversationReader {
  forReport(report: ReportRow): Promise<ConversationDto>;
}

// ---- Sanctions and appeals ------------------------------------------------

export type RevokeResult =
  | { readonly kind: "revoked"; readonly sanction: SanctionDto }
  | { readonly kind: "not_found" }
  | { readonly kind: "already_revoked" };

export interface SanctionsRepository {
  insert(sanction: NewSanction): Promise<SanctionDto>;
  find(id: number): Promise<SanctionDto | null>;
  listForMember(memberId: number): Promise<readonly SanctionDto[]>;
  revoke(id: number, by: string, note: string): Promise<RevokeResult>;
  findByReference(reference: string): Promise<{ readonly sanction: SanctionDto; readonly appealCodeHash: string } | null>;
  // A suspension or ban in force now.
  hasActiveBlocking(memberId: number): Promise<boolean>;
}

export type AppealDecisionResult =
  | { readonly kind: "decided"; readonly appeal: AppealDto; readonly sanction: SanctionDto }
  | { readonly kind: "not_found" }
  | { readonly kind: "already_decided" };

export interface AppealsRepository {
  // null when the sanction already has an appeal.
  create(input: { sanctionId: number; memberId: number; message: string }): Promise<AppealDto | null>;
  list(status: AppealStatus | undefined, limit: number, offset: number): Promise<{ readonly appeals: readonly AppealDto[]; readonly total: number }>;
  find(id: number): Promise<AppealDto | null>;
  // One transaction; "overturned" also revokes the sanction.
  decide(input: { id: number; outcome: "upheld" | "overturned"; by: string; note: string }): Promise<AppealDecisionResult>;
}

// ---- Authorities ----------------------------------------------------------

export interface AuthorityInput {
  readonly kind: AuthorityKind;
  readonly authority: string;
  readonly reference: string;
  readonly receivedAt: string;
  readonly dueAt: string | null;
  readonly memberId: number | null;
  readonly scope: string;
  readonly status: AuthorityStatus;
  readonly handledBy: string | null;
  readonly notes: string | null;
}

export interface AuthorityRepository {
  list(status: AuthorityStatus | undefined, limit: number, offset: number): Promise<{ readonly requests: readonly AuthorityRequestDto[]; readonly total: number }>;
  create(input: AuthorityInput): Promise<AuthorityRequestDto>;
  update(id: number, patch: Partial<AuthorityInput>): Promise<AuthorityRequestDto | null>;
}

// ---- Members and figures --------------------------------------------------

export interface RiskFacts {
  readonly messages: readonly RecentMessage[];
  readonly accountAgeDays: number;
  readonly reportsCount: number;
  readonly blocksReceived: number;
  readonly verified: boolean;
}

export interface MembersRepository {
  search(query: string, limit: number, offset: number): Promise<{ readonly members: readonly MemberRefDto[]; readonly total: number }>;
  profile(id: number): Promise<MemberFileDto["member"] | null>;
  stats(id: number): Promise<MemberFileDto["stats"] & { readonly reportsMade: number }>;
  riskFacts(id: number): Promise<RiskFacts>;
}

export type DashboardFigures = Omit<DashboardDto, "reports"> & {
  readonly reports: Pick<DashboardDto["reports"], "receivedLast7d" | "medianHandlingHours30d" | "daily">;
};

export interface FiguresRepository {
  dashboard(now: Date): Promise<DashboardFigures>;
  transparency(from: Date, toExclusive: Date): Promise<Omit<TransparencyDto, "from" | "to">>;
  verificationQueue(limit: number): Promise<readonly VerificationQueueItemDto[]>;
}

// ---- Effects outside this feature ------------------------------------------

// What a sanction does to the account. Wired in src/index.ts: `ban` calls
// banUser (src/db.ts), `onDisabled` closes the member's sockets.
export interface AccountEnforcement {
  // Suspension: the account can no longer sign in.
  disable(userId: number): Promise<void>;
  // Ban: disable and block the identity document (banUser).
  ban(userId: number, reason: string, by: string): Promise<void>;
  // Lifting or expiry: the account is usable again.
  enable(userId: number): Promise<void>;
  // After disable or ban: close the open sessions and sockets.
  onDisabled(userId: number): Promise<void>;
}

export interface AppealOutcomeNotice {
  readonly appealId: number;
  readonly reference: string;
  readonly outcome: "upheld" | "overturned";
}

export interface MemberNotifier {
  sanctionIssued(userId: number, statement: StatementOfReasons, appealCode: string): Promise<void>;
  appealDecided(userId: number, notice: AppealOutcomeNotice): Promise<void>;
}

export type Clock = () => Date;
export type RandomBytes = (length: number) => Uint8Array;
