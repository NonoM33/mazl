import { comparePriority } from "../domain/priority";
import { suggestSanction } from "../domain/ladder";
import { detectRiskSignals } from "../domain/risk-signals";
import type { Priority, ReportReason, ReportStatus } from "../domain/types";
import type {
  ConversationDto,
  ReportDecisionBody,
  ReportDetailDto,
  ReportListItemDto,
  ReportPageDto,
  SanctionDto,
} from "../presentation/dto";
import { TrustSafetyError, notFound } from "./errors";
import type { SanctionEffects } from "./effects";
import type {
  Clock,
  ConversationReader,
  MembersRepository,
  RandomBytes,
  ReportRow,
  ReportsRepository,
  SanctionsRepository,
} from "./ports";
import { buildReportItems, isOpen } from "./report-items";
import { prepareSanction } from "./sanction-factory";

export interface ReportQuery {
  readonly status?: ReportStatus;
  readonly priority?: Priority;
  readonly assigned: "me" | "none" | "all";
  readonly reason?: ReportReason;
  readonly limit: number;
  readonly offset: number;
}

export interface DecisionOutcome {
  readonly reportId: number;
  readonly status: ReportStatus;
  readonly sanction: SanctionDto | null;
  // Shown once, to the staff member who decided; only its hash is stored.
  readonly appealCode: string | null;
}

export interface ReportsServiceDeps {
  readonly reports: ReportsRepository;
  readonly sanctions: SanctionsRepository;
  readonly members: MembersRepository;
  readonly conversations: ConversationReader;
  readonly effects: SanctionEffects;
  readonly clock: Clock;
  readonly random: RandomBytes;
}

const OPEN_STATUSES: readonly ReportStatus[] = ["pending", "in_review"];

function emptyCounts(): Record<Priority, number> {
  return { P1: 0, P2: 0, P3: 0, P4: 0 };
}

export class ReportsService {
  constructor(private readonly deps: ReportsServiceDeps) {}

  async list(query: ReportQuery, staffEmail: string): Promise<ReportPageDto> {
    const now = this.deps.clock();
    const assigned = query.assigned === "me" ? { to: staffEmail } : query.assigned;
    const rows = await this.deps.reports.list({
      statuses: query.status ? [query.status] : OPEN_STATUSES,
      reason: query.reason,
      assigned,
    });
    const items = await buildReportItems(rows, this.deps.reports, now);
    const counts = emptyCounts();
    for (const item of items) counts[item.priority] += 1;
    const shown = (query.priority ? items.filter((item) => item.priority === query.priority) : items).sort(
      (a, b) => comparePriority(a.priority, b.priority) || a.dueAt.localeCompare(b.dueAt),
    );
    return {
      reports: shown.slice(query.offset, query.offset + query.limit),
      total: shown.length,
      counts,
      overdue: shown.filter((item) => item.overdue).length,
    };
  }

  async detail(id: number): Promise<ReportDetailDto> {
    const row = await this.row(id);
    const now = this.deps.clock();
    const memberId = row.reported.id;
    const [item] = await buildReportItems([row], this.deps.reports, now);
    const [history, sanctions, stats, facts, message] = await Promise.all([
      this.deps.reports.against(memberId),
      this.deps.sanctions.listForMember(memberId),
      this.deps.members.stats(memberId),
      this.deps.members.riskFacts(memberId),
      row.messageId === null ? Promise.resolve(null) : this.deps.reports.message(row.messageId),
    ]);
    if (!item) throw notFound("Signalement");
    const past = sanctions.map((sanction) => ({ kind: sanction.kind, revoked: sanction.revokedAt !== null }));
    return {
      ...item,
      details: row.details,
      reportedMessage: message,
      memberHistory: {
        reports: await buildReportItems(history, this.deps.reports, now),
        sanctions,
        blocksReceived: stats.blocksReceived,
        accountAgeDays: facts.accountAgeDays,
      },
      riskSignals: detectRiskSignals(facts),
      suggestedSanction: isOpen(row) ? suggestSanction(row.reason, past) : null,
      handledBy: row.handledBy,
      handledAt: row.handledAt ? row.handledAt.toISOString() : null,
      decisionNote: row.decisionNote,
    };
  }

  async assign(id: number, to: "me" | null, staffEmail: string): Promise<ReportListItemDto> {
    const row = await this.row(id);
    if (!isOpen(row)) throw new TrustSafetyError("already_decided", 409, "Ce signalement est déjà traité");
    const updated = await this.deps.reports.assign(id, to === "me" ? staffEmail : null);
    if (!updated) throw notFound("Signalement");
    const [item] = await buildReportItems([updated], this.deps.reports, this.deps.clock());
    if (!item) throw notFound("Signalement");
    return item;
  }

  async decide(id: number, body: ReportDecisionBody, staffEmail: string): Promise<DecisionOutcome> {
    const row = await this.row(id);
    const now = this.deps.clock();
    const prepared = body.sanction
      ? prepareSanction({
          memberId: row.reported.id,
          input: body.sanction,
          decidedBy: staffEmail,
          reportId: id,
          note: body.note,
          origin: "member_report",
          now,
          random: this.deps.random,
        })
      : null;
    const result = await this.deps.reports.decide({
      reportId: id,
      outcome: body.outcome,
      note: body.note,
      decidedBy: staffEmail,
      sanction: prepared ? prepared.sanction : null,
    });
    if (result.kind === "not_found") throw notFound("Signalement");
    if (result.kind === "already_decided") throw new TrustSafetyError("already_decided", 409, "Ce signalement est déjà traité");
    if (result.sanction && prepared) await this.deps.effects.issued(result.sanction, prepared.appealCode);
    return {
      reportId: id,
      status: result.status,
      sanction: result.sanction,
      appealCode: prepared ? prepared.appealCode : null,
    };
  }

  // The caller audits the read before sending the content on.
  async conversation(id: number): Promise<{ readonly report: ReportRow; readonly conversation: ConversationDto }> {
    const report = await this.row(id);
    return { report, conversation: await this.deps.conversations.forReport(report) };
  }

  private async row(id: number): Promise<ReportRow> {
    const row = await this.deps.reports.find(id);
    if (!row) throw notFound("Signalement");
    return row;
  }
}
