import { createMiddleware } from "hono/factory";
import type { AppVariables } from "./middleware";

// In-memory sliding-window limiter keyed by user id (CONTRAT.md §2.3). Must run
// after requireAuth. State is per process, which is enough to slow scraping
// down on a single instance; blocked requests are not recorded.

const SWEEP_THRESHOLD = 5000;

export interface RateLimiterOptions {
  readonly max: number;
  readonly windowMs: number;
  readonly now?: () => number;
}

export function createRateLimiter(options: RateLimiterOptions) {
  const { max, windowMs } = options;
  const now = options.now ?? Date.now;
  const hits = new Map<number, number[]>();

  function recent(userId: number, at: number): number[] {
    const live = (hits.get(userId) ?? []).filter((t) => t > at - windowMs);
    if (live.length > 0) hits.set(userId, live);
    else hits.delete(userId);
    return live;
  }

  // Users who never come back would otherwise stay in memory forever.
  function sweep(at: number): void {
    if (hits.size < SWEEP_THRESHOLD) return;
    for (const userId of [...hits.keys()]) recent(userId, at);
  }

  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const at = now();
    sweep(at);
    const userId = c.get("userId");
    const live = recent(userId, at);
    const oldest = live[0];
    if (live.length >= max && oldest !== undefined) {
      const retryAfter = Math.max(1, Math.ceil((oldest + windowMs - at) / 1000));
      c.header("Retry-After", String(retryAfter));
      return c.json({ success: false, error: "rate_limited", retry_after: retryAfter }, 429);
    }
    live.push(at);
    hits.set(userId, live);
    await next();
  });
}
