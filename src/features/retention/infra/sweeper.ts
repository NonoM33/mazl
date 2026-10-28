import { describeReport, totalDeleted, type PurgeReport } from "../application/purge";

export function startRetentionSweeper(run: () => Promise<PurgeReport>, intervalMs: number): () => void {
  let running = false;
  const timer = setInterval(() => {
    if (running) return;
    running = true;
    run()
      .then((report) => {
        if (totalDeleted(report) > 0) console.info(describeReport(report));
      })
      .catch((error: unknown) => console.error("retention: purge failed", error instanceof Error ? error.name : "unknown"))
      .finally(() => {
        running = false;
      });
  }, intervalMs);
  return () => clearInterval(timer);
}
