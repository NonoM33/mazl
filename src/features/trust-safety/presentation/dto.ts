import type {
  AppealStatus,
  AuthorityKind,
  AuthorityStatus,
  DecisionGround,
  Priority,
  ReportReason,
  ReportStatus,
  RiskSignal,
  SanctionKind,
  StatementOfReasons,
} from "../domain/types";

// HTTP contract of trust & safety, under /api/backoffice. Envelope:
// { success: true, data } | { success: false, error, message? }.
// Members are shown by display name and id; e-mails only in the member file.

export interface MemberRefDto {
  readonly id: number;
  readonly displayName: string | null;
  readonly photoUrl: string | null;
  readonly verification: "none" | "selfie" | "identity";
  readonly active: boolean;
}

// GET /reports?status&priority&assigned=me|none|all&reason&limit&offset   (reports.read)
// Sorted by priority, then due date (oldest SLA first).
export interface ReportListItemDto {
  readonly id: number;
  readonly createdAt: string;
  readonly reason: ReportReason;
  readonly priority: Priority;
  readonly status: ReportStatus;
  readonly dueAt: string;
  readonly overdue: boolean;
  readonly assignedTo: string | null;
  readonly reported: MemberRefDto;
  readonly reporterId: number | null;
  // Other open reports against the same member.
  readonly otherOpenReports: number;
  readonly hasMessage: boolean;
  readonly excerpt: string | null; // first 140 characters of the reporter's details
}

export interface ReportPageDto {
  readonly reports: readonly ReportListItemDto[];
  readonly total: number;
  readonly counts: Readonly<Record<Priority, number>>;
  readonly overdue: number;
}

export interface SanctionDto {
  readonly id: number;
  readonly memberId: number;
  readonly kind: SanctionKind;
  readonly ground: DecisionGround;
  readonly startsAt: string;
  readonly endsAt: string | null;
  readonly decidedBy: string;
  readonly reportId: number | null;
  readonly revokedAt: string | null;
  readonly revokedBy: string | null;
  readonly statement: StatementOfReasons;
  readonly appeal: AppealDto | null;
}

export interface AppealDto {
  readonly id: number;
  readonly sanctionId: number;
  readonly memberId: number;
  readonly createdAt: string;
  readonly message: string;
  readonly status: AppealStatus;
  readonly decidedBy: string | null;
  readonly decidedAt: string | null;
  readonly decisionNote: string | null;
  // Who took the contested decision: an appeal must be decided by someone else.
  readonly sanctionDecidedBy: string;
  readonly sanctionKind: SanctionKind;
}

// GET /reports/:id   (reports.read)
export interface ReportDetailDto extends ReportListItemDto {
  readonly details: string | null;
  readonly reportedMessage: { readonly id: number; readonly content: string | null; readonly unsent: boolean; readonly sentAt: string } | null;
  readonly memberHistory: {
    readonly reports: readonly ReportListItemDto[];
    readonly sanctions: readonly SanctionDto[];
    readonly blocksReceived: number;
    readonly accountAgeDays: number;
  };
  readonly riskSignals: readonly RiskSignal[];
  // The lightest sanction the ladder suggests given the history (never applied alone).
  readonly suggestedSanction: SanctionKind | null;
  readonly handledBy: string | null;
  readonly handledAt: string | null;
  readonly decisionNote: string | null;
}

// POST /reports/:id/assign  { to: "me" | null }   (reports.decide)
// POST /reports/:id/decision (reports.decide; sanctions.apply / sanctions.ban as needed)
export interface ReportDecisionBody {
  readonly outcome: "dismissed" | "actioned";
  readonly note: string; // internal, mandatory, 3..2000 chars
  readonly sanction?: SanctionInput;
}

export interface SanctionInput {
  readonly kind: SanctionKind;
  readonly ground: DecisionGround;
  // Facts told to the member (DSA art. 17), 10..2000 chars, no third-party personal data.
  readonly facts: string;
  // Days for a restriction or suspension (1..365); ignored for warning and ban.
  readonly durationDays?: number;
}

// GET /reports/:id/conversation?justification=…   (conversations.read)
// The justification (10..500 chars) is written in the audit journal with the read.
export interface ConversationDto {
  readonly conversationId: number | null;
  readonly participants: readonly MemberRefDto[];
  readonly messages: readonly {
    readonly id: number;
    readonly senderId: number;
    readonly type: "text" | "photo" | "voice";
    readonly content: string | null;
    readonly sentAt: string;
    readonly unsent: boolean;
    readonly reported: boolean;
  }[];
}

// GET /members?q=&limit&offset   (members.read) — q matches id, display name or e-mail.
// GET /members/:id                (members.read)
export interface MemberFileDto {
  readonly member: MemberRefDto & {
    readonly email: string;
    readonly createdAt: string;
    readonly lastActiveAt: string | null;
    readonly age: number | null;
    readonly city: string | null;
    readonly gender: string | null;
    readonly denomination: string | null;
    readonly photos: readonly string[];
    readonly bio: string | null;
  };
  readonly reportsReceived: readonly ReportListItemDto[];
  readonly reportsMade: number;
  readonly sanctions: readonly SanctionDto[];
  readonly activeSanction: SanctionDto | null;
  readonly riskSignals: readonly RiskSignal[];
  readonly stats: { readonly matches: number; readonly blocksReceived: number; readonly likesReceived7d: number };
}

// POST /members/:id/sanctions  SanctionInput & { note }   (sanctions.apply; ban: sanctions.ban)
// POST /sanctions/:id/revoke   { note }                   (sanctions.apply)

// GET /appeals?status   (appeals.decide)
// POST /appeals/:id/decision { outcome: "upheld" | "overturned", note }   (appeals.decide)
//   409 same_decider when the caller decided the contested sanction.
// Public, no account needed (a banned member cannot sign in):
// POST /api/appeals { reference, appealCode, message }  — the code comes with the statement of reasons.

// GET/POST/PATCH /authorities   (authorities.manage)
export interface AuthorityRequestDto {
  readonly id: number;
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
  readonly createdAt: string;
}

// GET /dashboard   (dashboard.read) — aggregated figures only, no personal data.
export interface DashboardDto {
  readonly generatedAt: string;
  readonly reports: {
    readonly open: number;
    readonly byPriority: Readonly<Record<Priority, number>>;
    readonly overdue: number;
    readonly receivedLast7d: number;
    readonly medianHandlingHours30d: number | null;
    readonly daily: readonly { readonly day: string; readonly received: number; readonly handled: number }[]; // 30 days
  };
  readonly sanctions30d: Readonly<Record<SanctionKind, number>>;
  readonly appeals: { readonly pending: number; readonly decided30d: number; readonly overturnRate30d: number | null };
  readonly verification: { readonly pending: number; readonly verifiedMembers: number };
  readonly members: { readonly total: number; readonly new7d: number; readonly active7d: number; readonly matches7d: number };
  readonly authorities: { readonly open: number };
}

// GET /transparency?from=YYYY-MM-DD&to=YYYY-MM-DD[&format=csv]   (dashboard.read)
// DSA art. 15 figures for the period.
export interface TransparencyDto {
  readonly from: string;
  readonly to: string;
  readonly noticesReceived: Readonly<Record<ReportReason, number>>;
  readonly noticesActioned: number;
  readonly medianHandlingHours: number | null;
  readonly sanctionsByKind: Readonly<Record<SanctionKind, number>>;
  readonly sanctionsByGround: Readonly<Record<DecisionGround, number>>;
  readonly appealsReceived: number;
  readonly appealsOverturned: number;
  readonly medianAppealHours: number | null;
  readonly authorityRequests: Readonly<Record<AuthorityKind, number>>;
  readonly automatedDecisions: 0;
}

// GET /verification/queue   (verification.review) — members waiting for a manual review.
export interface VerificationQueueItemDto {
  readonly memberId: number;
  readonly displayName: string | null;
  readonly submittedAt: string;
  readonly kind: "documents" | "selfie" | "identity";
  readonly status: string;
  readonly photoUrl: string | null;
}
