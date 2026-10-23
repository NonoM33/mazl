import type { SweepSummary } from "../application/purge-documents";

export const PURGE_INTERVAL_MS = 6 * 60 * 60 * 1000;

interface Timer {
  cancel(): void;
}

interface SchedulerOptions {
  schedule?: (fn: () => void, ms: number) => Timer;
  log?: (line: string) => void;
}

const realSchedule = (fn: () => void, ms: number): Timer => {
  const handle = setInterval(fn, ms);
  handle.unref();
  return { cancel: () => clearInterval(handle) };
};

// Runs the sweep at boot and then every 6 hours. A failing run is logged
// (counts only) and retried at the next tick.
export function startPurgeScheduler(run: () => Promise<SweepSummary>, options: SchedulerOptions = {}): () => void {
  const log = options.log ?? ((line: string) => console.log(line));
  const schedule = options.schedule ?? realSchedule;

  const tick = (): void => {
    run().then(
      (summary) => {
        if (summary.decided + summary.stale > 0) {
          log(`documents purge: ${summary.decided} decided, ${summary.stale} stale`);
        }
      },
      (error: unknown) => {
        log(`documents purge failed: ${error instanceof Error ? error.name : "unknown error"}`);
      },
    );
  };

  tick();
  const timer = schedule(tick, PURGE_INTERVAL_MS);
  return () => timer.cancel();
}
