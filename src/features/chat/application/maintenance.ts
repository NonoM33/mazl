// Runs a task now and then every `intervalMs`. A failing run is logged (kind of
// error only) and never stops the schedule. Returns the function that stops it.
export function startPeriodically(
  task: () => Promise<void>,
  intervalMs: number,
  schedule: typeof setInterval = setInterval,
): () => void {
  const run = (): void => {
    task().catch((error: unknown) => {
      console.error("Chat maintenance failed:", error instanceof Error ? error.name : "unknown");
    });
  };
  run();
  const timer = schedule(run, intervalMs);
  if (typeof timer === "object" && "unref" in timer) timer.unref();
  return () => clearInterval(timer);
}
