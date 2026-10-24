import { computePriority, dueAt, isOverdue } from "../domain/priority";
import type { ReportListItemDto } from "../presentation/dto";
import type { ReportRow, ReportsRepository } from "./ports";

const EXCERPT_LENGTH = 140;
const OPEN: ReadonlySet<string> = new Set(["pending", "in_review"]);

export function isOpen(row: ReportRow): boolean {
  return OPEN.has(row.status);
}

// Priority and SLA are computed here, never stored: they follow the member's
// situation at the moment the queue is read.
export async function buildReportItems(
  rows: readonly ReportRow[],
  reports: Pick<ReportsRepository, "contexts">,
  now: Date,
): Promise<ReportListItemDto[]> {
  const memberIds = [...new Set(rows.map((row) => row.reported.id))];
  const contexts = await reports.contexts(memberIds, now);
  return rows.map((row) => {
    const context = contexts.get(row.reported.id) ?? { openReports: 0, sanctionedRecently: false };
    const priority = computePriority(row.reason, {
      openReportsOnMember: context.openReports,
      sanctionedRecently: context.sanctionedRecently,
    });
    const due = dueAt(row.createdAt, priority);
    return {
      id: row.id,
      createdAt: row.createdAt.toISOString(),
      reason: row.reason,
      priority,
      status: row.status,
      dueAt: due.toISOString(),
      overdue: isOpen(row) && isOverdue(due, now),
      assignedTo: row.assignedTo,
      reported: row.reported,
      reporterId: row.reporterId,
      otherOpenReports: Math.max(0, context.openReports - (isOpen(row) ? 1 : 0)),
      hasMessage: row.messageId !== null,
      excerpt: row.details === null ? null : row.details.slice(0, EXCERPT_LENGTH),
    };
  });
}
