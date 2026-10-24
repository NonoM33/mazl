import { PurgeFailedError, STALE_AFTER_DAYS } from "../domain/types";
import type { DocumentFileStore, DocumentRepository, PurgeScope, PurgeTarget } from "./ports";

export interface SweepSummary {
  decided: number;
  stale: number;
}

export interface Purger {
  purgeDecided(scope: PurgeScope): Promise<number>;
  purgeStale(maxAgeDays?: number): Promise<number>;
  sweep(): Promise<SweepSummary>;
}

export function createPurger(deps: { repo: DocumentRepository; store: DocumentFileStore }): Purger {
  // File first, row second: a crash in between leaves a row that points to a
  // missing file (retried by the next sweep), never a file nobody points to.
  async function purgeTargets(targets: readonly PurgeTarget[]): Promise<number> {
    const purged: number[] = [];
    let failed = 0;
    for (const target of targets) {
      try {
        if (target.filename) await deps.store.remove(target.filename);
        purged.push(target.id);
      } catch {
        failed += 1;
      }
    }
    if (purged.length > 0) await deps.repo.markPurged(purged);
    if (failed > 0) throw new PurgeFailedError(failed);
    return purged.length;
  }

  async function purgeDecided(scope: PurgeScope): Promise<number> {
    return purgeTargets(await deps.repo.findDecidedUnpurged(scope));
  }

  async function purgeStale(maxAgeDays: number = STALE_AFTER_DAYS): Promise<number> {
    return purgeTargets(await deps.repo.findStaleUndecided(maxAgeDays));
  }

  async function sweep(): Promise<SweepSummary> {
    const decided = await purgeDecided("all");
    const stale = await purgeStale();
    return { decided, stale };
  }

  return { purgeDecided, purgeStale, sweep };
}
