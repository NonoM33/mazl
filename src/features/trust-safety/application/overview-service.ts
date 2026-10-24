import { PRIORITIES, type Priority } from "../domain/types";
import type { DashboardDto, TransparencyDto, VerificationQueueItemDto } from "../presentation/dto";
import type { Clock, FiguresRepository, ReportsRepository } from "./ports";
import { buildReportItems } from "./report-items";

const DAY_MS = 86_400_000;

export class OverviewService {
  constructor(
    private readonly figures: FiguresRepository,
    private readonly reports: ReportsRepository,
    private readonly clock: Clock,
  ) {}

  async dashboard(): Promise<DashboardDto> {
    const now = this.clock();
    const [figures, rows] = await Promise.all([
      this.figures.dashboard(now),
      this.reports.list({ statuses: ["pending", "in_review"], assigned: "all" }),
    ]);
    const items = await buildReportItems(rows, this.reports, now);
    const byPriority = Object.fromEntries(PRIORITIES.map((priority) => [priority, 0])) as Record<Priority, number>;
    for (const item of items) byPriority[item.priority] += 1;
    return {
      ...figures,
      generatedAt: now.toISOString(),
      reports: {
        ...figures.reports,
        open: items.length,
        byPriority,
        overdue: items.filter((item) => item.overdue).length,
      },
    };
  }

  // Calendar days in UTC, both ends included.
  async transparency(from: string, to: string): Promise<TransparencyDto> {
    const start = new Date(`${from}T00:00:00.000Z`);
    const endExclusive = new Date(new Date(`${to}T00:00:00.000Z`).getTime() + DAY_MS);
    return { from, to, ...(await this.figures.transparency(start, endExclusive)) };
  }

  verificationQueue(): Promise<readonly VerificationQueueItemDto[]> {
    return this.figures.verificationQueue(200);
  }
}
