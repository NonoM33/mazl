import { detectRiskSignals } from "../domain/risk-signals";
import type { MemberFileDto, MemberRefDto, SanctionDto } from "../presentation/dto";
import { notFound } from "./errors";
import type { Clock, MembersRepository, ReportsRepository, SanctionsRepository } from "./ports";
import { buildReportItems } from "./report-items";

const BLOCKING_KINDS: ReadonlySet<string> = new Set(["restriction", "suspension", "ban"]);

export function activeSanctionOf(sanctions: readonly SanctionDto[], now: Date): SanctionDto | null {
  const active = sanctions.filter(
    (sanction) =>
      sanction.revokedAt === null &&
      BLOCKING_KINDS.has(sanction.kind) &&
      new Date(sanction.startsAt).getTime() <= now.getTime() &&
      (sanction.endsAt === null || new Date(sanction.endsAt).getTime() > now.getTime()),
  );
  return active[0] ?? null;
}

export class MembersService {
  constructor(
    private readonly members: MembersRepository,
    private readonly reports: ReportsRepository,
    private readonly sanctions: SanctionsRepository,
    private readonly clock: Clock,
  ) {}

  search(query: string, limit: number, offset: number): Promise<{ readonly members: readonly MemberRefDto[]; readonly total: number }> {
    return this.members.search(query, limit, offset);
  }

  async file(id: number): Promise<MemberFileDto> {
    const profile = await this.members.profile(id);
    if (!profile) throw notFound("Membre");
    const now = this.clock();
    const [received, sanctions, stats, facts] = await Promise.all([
      this.reports.against(id),
      this.sanctions.listForMember(id),
      this.members.stats(id),
      this.members.riskFacts(id),
    ]);
    return {
      member: profile,
      reportsReceived: await buildReportItems(received, this.reports, now),
      reportsMade: stats.reportsMade,
      sanctions,
      activeSanction: activeSanctionOf(sanctions, now),
      riskSignals: detectRiskSignals(facts),
      stats: { matches: stats.matches, blocksReceived: stats.blocksReceived, likesReceived7d: stats.likesReceived7d },
    };
  }
}

