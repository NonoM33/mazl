import { Hono } from "hono";
import type { MiddlewareHandler } from "hono";
import { AppealsService } from "../../src/features/trust-safety/application/appeals-service";
import { SanctionEffects } from "../../src/features/trust-safety/application/effects";
import { MembersService } from "../../src/features/trust-safety/application/members-service";
import { OverviewService } from "../../src/features/trust-safety/application/overview-service";
import type {
  AccountEnforcement,
  AppealsRepository,
  AuthorityRepository,
  FiguresRepository,
  MemberNotifier,
  MembersRepository,
  NewSanction,
  ReportRow,
  ReportsRepository,
  SanctionsRepository,
} from "../../src/features/trust-safety/application/ports";
import { ReportsService } from "../../src/features/trust-safety/application/reports-service";
import { SanctionsService } from "../../src/features/trust-safety/application/sanctions-service";
import { registerTrustSafetyRoutes } from "../../src/features/trust-safety/presentation/trust-safety.routes";
import type { AppealDto, MemberRefDto, SanctionDto } from "../../src/features/trust-safety/presentation/dto";
import type { AuditEntryInput } from "../../src/features/audit/application/ports";
import type { RequirePermission, StaffVariables } from "../../src/features/staff/application/ports";
import { isStaffRole, roleGrants } from "../../src/features/staff/domain/roles";

type Mutable<T> = { -readonly [K in keyof T]: T[K] };
type Stored = Mutable<SanctionDto> & { appealCodeHash: string };

export const NOW = new Date("2026-10-24T12:00:00Z");

export function member(id: number): MemberRefDto {
  return { id, displayName: `Membre ${id}`, photoUrl: null, verification: "none", active: true };
}

export function report(id: number, overrides: Partial<ReportRow> = {}): ReportRow {
  return {
    id,
    createdAt: new Date("2026-10-24T08:00:00Z"),
    reason: "harassment",
    status: "pending",
    assignedTo: null,
    reported: member(100 + id),
    reporterId: 1,
    messageId: null,
    details: "details",
    handledBy: null,
    handledAt: null,
    decisionNote: null,
    ...overrides,
  };
}

// In-memory world shared by the fake repositories.
export class World {
  reports: ReportRow[] = [];
  sanctions: Stored[] = [];
  appeals: AppealDto[] = [];
  private nextId = 1;

  addSanction(sanction: NewSanction): SanctionDto {
    const dto: Stored = {
      id: this.nextId++,
      memberId: sanction.memberId,
      kind: sanction.kind,
      ground: sanction.ground,
      startsAt: sanction.startsAt.toISOString(),
      endsAt: sanction.endsAt ? sanction.endsAt.toISOString() : null,
      decidedBy: sanction.decidedBy,
      reportId: sanction.reportId,
      revokedAt: null,
      revokedBy: null,
      statement: sanction.statement,
      appeal: null,
      appealCodeHash: sanction.appealCodeHash,
    };
    this.sanctions.push(dto);
    return dto;
  }

  addAppeal(sanctionId: number, message: string): AppealDto | null {
    const sanction = this.sanctions.find((candidate) => candidate.id === sanctionId);
    if (!sanction || this.appeals.some((appeal) => appeal.sanctionId === sanctionId)) return null;
    const appeal: AppealDto = {
      id: this.nextId++,
      sanctionId,
      memberId: sanction.memberId,
      createdAt: NOW.toISOString(),
      message,
      status: "pending",
      decidedBy: null,
      decidedAt: null,
      decisionNote: null,
      sanctionDecidedBy: sanction.decidedBy,
      sanctionKind: sanction.kind,
    };
    this.appeals.push(appeal);
    return appeal;
  }
}

function fakeReports(world: World): ReportsRepository {
  const find = (id: number) => world.reports.find((row) => row.id === id) ?? null;
  return {
    list: async (filter) => world.reports.filter((row) => filter.statuses.includes(row.status)),
    find: async (id) => find(id),
    against: async (memberId) => world.reports.filter((row) => row.reported.id === memberId),
    contexts: async (ids) =>
      new Map(ids.map((id) => [id, { openReports: world.reports.filter((row) => row.reported.id === id && row.status === "pending").length, sanctionedRecently: false }])),
    assign: async (id, to) => {
      const row = find(id);
      if (!row) return null;
      const updated: ReportRow = { ...row, assignedTo: to, status: to ? "in_review" : "pending" };
      world.reports = world.reports.map((candidate) => (candidate.id === id ? updated : candidate));
      return updated;
    },
    decide: async (decision) => {
      const row = find(decision.reportId);
      if (!row) return { kind: "not_found" };
      if (row.status !== "pending" && row.status !== "in_review") return { kind: "already_decided" };
      const sanction = decision.sanction ? world.addSanction(decision.sanction) : null;
      world.reports = world.reports.map((candidate) => (candidate.id === row.id ? { ...candidate, status: decision.outcome } : candidate));
      return { kind: "decided", status: decision.outcome, sanction };
    },
    message: async () => null,
  };
}

function fakeSanctions(world: World): SanctionsRepository {
  const withAppeal = (sanction: Stored): SanctionDto => {
    const { appealCodeHash: _hash, ...dto } = sanction;
    return { ...dto, appeal: world.appeals.find((appeal) => appeal.sanctionId === sanction.id) ?? null };
  };
  return {
    insert: async (sanction) => world.addSanction(sanction),
    find: async (id) => {
      const found = world.sanctions.find((candidate) => candidate.id === id);
      return found ? withAppeal(found) : null;
    },
    listForMember: async (memberId) => world.sanctions.filter((candidate) => candidate.memberId === memberId).map(withAppeal),
    revoke: async (id, by) => {
      const found = world.sanctions.find((candidate) => candidate.id === id);
      if (!found) return { kind: "not_found" };
      if (found.revokedAt) return { kind: "already_revoked" };
      found.revokedAt = NOW.toISOString();
      found.revokedBy = by;
      return { kind: "revoked", sanction: withAppeal(found) };
    },
    findByReference: async (reference) => {
      const found = world.sanctions.find((candidate) => candidate.statement.reference === reference);
      return found ? { sanction: withAppeal(found), appealCodeHash: found.appealCodeHash } : null;
    },
    hasActiveBlocking: async (memberId) =>
      world.sanctions.some((candidate) => candidate.memberId === memberId && !candidate.revokedAt && (candidate.kind === "suspension" || candidate.kind === "ban")),
  };
}

function fakeAppeals(world: World): AppealsRepository {
  return {
    create: async (input) => world.addAppeal(input.sanctionId, input.message),
    list: async (status) => {
      const appeals = world.appeals.filter((appeal) => !status || appeal.status === status);
      return { appeals, total: appeals.length };
    },
    find: async (id) => world.appeals.find((appeal) => appeal.id === id) ?? null,
    decide: async (input) => {
      const appeal = world.appeals.find((candidate) => candidate.id === input.id);
      if (!appeal) return { kind: "not_found" };
      if (appeal.status !== "pending") return { kind: "already_decided" };
      const decided: AppealDto = { ...appeal, status: input.outcome, decidedBy: input.by, decidedAt: NOW.toISOString(), decisionNote: input.note };
      world.appeals = world.appeals.map((candidate) => (candidate.id === input.id ? decided : candidate));
      const sanction = world.sanctions.find((candidate) => candidate.id === appeal.sanctionId);
      if (!sanction) return { kind: "not_found" };
      if (input.outcome === "overturned") sanction.revokedAt = NOW.toISOString();
      const { appealCodeHash: _hash, ...dto } = sanction;
      return { kind: "decided", appeal: decided, sanction: { ...dto, appeal: decided } };
    },
  };
}

const fakeMembers: MembersRepository = {
  search: async () => ({ members: [], total: 0 }),
  profile: async (id) =>
    id > 1000
      ? null
      : { ...member(id), email: "x@example.com", createdAt: NOW.toISOString(), lastActiveAt: null, age: 30, city: "Paris", gender: null, denomination: null, photos: [], bio: null },
  stats: async () => ({ matches: 0, blocksReceived: 0, likesReceived7d: 0, reportsMade: 0 }),
  riskFacts: async () => ({ messages: [], accountAgeDays: 30, reportsCount: 0, blocksReceived: 0, verified: true }),
};

const fakeAuthorities: AuthorityRepository = {
  list: async () => ({ requests: [], total: 0 }),
  create: async (input) => ({ id: 1, ...input, createdAt: NOW.toISOString() }),
  update: async () => null,
};

const emptyFigures: FiguresRepository = {
  dashboard: async () => {
    throw new Error("not used");
  },
  transparency: async () => ({
    noticesReceived: { underage: 0, offline_behavior: 0, harassment: 2, scam: 0, fake_profile: 0, inappropriate_photos: 0, spam: 0, other: 0 },
    noticesActioned: 1,
    medianHandlingHours: 3.5,
    sanctionsByKind: { warning: 1, restriction: 0, suspension: 0, ban: 0 },
    sanctionsByGround: {
      minor_on_platform: 0, threat_or_violence: 0, sexual_content: 0, harassment: 1, hate_speech: 0, scam_or_fraud: 0, impersonation: 0,
      fake_profile: 0, commercial_spam: 0, off_platform_solicitation: 0, inappropriate_photo: 0, illegal_content: 0, other_terms_breach: 0,
    },
    appealsReceived: 0,
    appealsOverturned: 0,
    medianAppealHours: null,
    authorityRequests: { judicial_requisition: 0, police_request: 0, pharos: 0, dsa_art18_notice: 0, other: 0 },
    automatedDecisions: 0,
  }),
  verificationQueue: async () => [],
};

// The role comes from a test header; the permission check is the real one.
export const fakeRequirePermission: RequirePermission = (permission): MiddlewareHandler<{ Variables: StaffVariables }> => {
  return async (c, next) => {
    const email = c.req.header("x-test-email");
    const role = c.req.header("x-test-role");
    if (!email || !isStaffRole(role)) return c.json({ success: false, error: "unauthorized" }, 401);
    if (!roleGrants(role, permission)) return c.json({ success: false, error: "forbidden" }, 403);
    c.set("staff", { email, role, mfa: true });
    await next();
  };
};

export function as(email: string, role: string, body?: unknown): RequestInit {
  const headers: Record<string, string> = { "x-test-email": email, "x-test-role": role, "content-type": "application/json" };
  return body === undefined ? { headers } : { method: "POST", headers, body: JSON.stringify(body) };
}

export interface Harness {
  readonly app: Hono;
  readonly world: World;
  readonly audit: AuditEntryInput[];
  readonly calls: string[];
  readonly notices: string[];
}

export function harness(): Harness {
  const world = new World();
  const audit: AuditEntryInput[] = [];
  const calls: string[] = [];
  const notices: string[] = [];
  const enforcement: AccountEnforcement = {
    disable: async (id) => void calls.push(`disable:${id}`),
    ban: async (id) => void calls.push(`ban:${id}`),
    enable: async (id) => void calls.push(`enable:${id}`),
    onDisabled: async (id) => void calls.push(`onDisabled:${id}`),
  };
  const notifier: MemberNotifier = {
    sanctionIssued: async (id, _statement, code) => void notices.push(`issued:${id}:${code}`),
    appealDecided: async (id, notice) => void notices.push(`appeal:${id}:${notice.outcome}`),
  };
  let counter = 0;
  const random = (length: number) => Uint8Array.from({ length }, (_, index) => (counter += 7 + index) % 256);
  const clock = () => NOW;
  const reports = fakeReports(world);
  const sanctions = fakeSanctions(world);
  const effects = new SanctionEffects(enforcement, sanctions, notifier);
  const services = {
    reports: new ReportsService({ reports, sanctions, members: fakeMembers, conversations: { forReport: async () => ({ conversationId: 9, participants: [], messages: [] }) }, effects, clock, random }),
    sanctions: new SanctionsService(sanctions, fakeMembers, effects, clock, random),
    members: new MembersService(fakeMembers, reports, sanctions, clock),
    appeals: new AppealsService(fakeAppeals(world), sanctions, effects, notifier, clock),
    overview: new OverviewService(emptyFigures, reports, clock),
    authorities: fakeAuthorities,
  };
  const app = new Hono();
  registerTrustSafetyRoutes(app, { requirePermission: fakeRequirePermission, audit: { record: async (entry) => (audit.push(entry), { ...entry, id: audit.length, createdAt: NOW.toISOString(), previousHash: "", hash: "" }) }, services });
  return { app, world, audit, calls, notices };
}
