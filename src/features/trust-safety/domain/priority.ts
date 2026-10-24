import { REPORT_REASONS, type Priority, type ReportReason } from "./types";

// Docs/backoffice/CADRAGE.md §6: priority comes from the reason, then moves up
// one notch for a member already in trouble. The SLA clock starts at the report.

const BASE_PRIORITY: Readonly<Record<ReportReason, Priority>> = {
  underage: "P1",
  offline_behavior: "P1",
  harassment: "P2",
  scam: "P2",
  fake_profile: "P3",
  inappropriate_photos: "P3",
  spam: "P4",
  other: "P4",
};

export const SLA_HOURS: Readonly<Record<Priority, number>> = { P1: 4, P2: 24, P3: 72, P4: 168 };

const ORDER: readonly Priority[] = ["P1", "P2", "P3", "P4"];

export const OPEN_REPORTS_ESCALATION_THRESHOLD = 3;
export const RECENT_SANCTION_DAYS = 90;

export function isReportReason(value: string): value is ReportReason {
  return (REPORT_REASONS as readonly string[]).includes(value);
}

// An unknown or missing reason is filed under "other", never rejected.
export function normalizeReason(raw: string | null | undefined): ReportReason {
  const candidate = (raw ?? "").trim().toLowerCase();
  return isReportReason(candidate) ? candidate : "other";
}

export function basePriority(reason: ReportReason): Priority {
  return BASE_PRIORITY[reason];
}

export function escalate(priority: Priority): Priority {
  const index = ORDER.indexOf(priority);
  return ORDER[Math.max(0, index - 1)] ?? "P1";
}

export interface PriorityContext {
  // Open reports against the member, the one being ranked included.
  readonly openReportsOnMember: number;
  // A sanction was issued against the member in the last 90 days.
  readonly sanctionedRecently: boolean;
}

export function computePriority(reason: ReportReason, context: PriorityContext): Priority {
  const base = basePriority(reason);
  const troubled = context.openReportsOnMember >= OPEN_REPORTS_ESCALATION_THRESHOLD || context.sanctionedRecently;
  return troubled ? escalate(base) : base;
}

export function dueAt(createdAt: Date, priority: Priority): Date {
  return new Date(createdAt.getTime() + SLA_HOURS[priority] * 3_600_000);
}

export function isOverdue(due: Date, now: Date): boolean {
  return now.getTime() > due.getTime();
}

export function comparePriority(a: Priority, b: Priority): number {
  return ORDER.indexOf(a) - ORDER.indexOf(b);
}
