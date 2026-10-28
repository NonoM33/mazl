import type { RetentionRule } from "../domain/rules";
import type { RetentionStore } from "./ports";

export type PurgeReport = Readonly<Record<string, number>>;

// One pass over every rule. Idempotent: a second pass finds nothing left to delete.
export async function runRetentionPass(store: RetentionStore, rules: readonly RetentionRule[]): Promise<PurgeReport> {
  const report: Record<string, number> = {};
  for (const rule of rules) report[rule.table] = await store.purge(rule);
  return report;
}

export function totalDeleted(report: PurgeReport): number {
  return Object.values(report).reduce((sum, count) => sum + count, 0);
}

export function describeReport(report: PurgeReport): string {
  const parts = Object.entries(report).map(([table, count]) => `${table}=${count}`);
  return `retention: purged ${parts.join(" ")}`;
}
