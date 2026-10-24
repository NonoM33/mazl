// Per-user sliding-window counter, the same rule as the HTTP rate limiter
// (shared/http/rate-limit.ts) but callable from anywhere, so that a REST route
// and a WebSocket frame can draw from one quota. State is per process.

const SWEEP_THRESHOLD = 5000;

export interface SlidingWindowOptions {
  readonly max: number;
  readonly windowMs: number;
  readonly now?: () => number;
}

export type WindowVerdict = { readonly allowed: true } | { readonly allowed: false; readonly retryAfterSeconds: number };

export interface SlidingWindow {
  // Records the hit when it is allowed; a refused hit is not recorded.
  attempt(userId: number): WindowVerdict;
  // Users currently tracked (for tests and monitoring).
  size(): number;
}

export function createSlidingWindow(options: SlidingWindowOptions): SlidingWindow {
  const { max, windowMs } = options;
  const now = options.now ?? Date.now;
  const hits = new Map<number, number[]>();

  function recent(userId: number, at: number): number[] {
    const live = (hits.get(userId) ?? []).filter((time) => time > at - windowMs);
    if (live.length > 0) hits.set(userId, live);
    else hits.delete(userId);
    return live;
  }

  // Users who never come back would otherwise stay in memory forever.
  function sweep(at: number): void {
    if (hits.size < SWEEP_THRESHOLD) return;
    for (const userId of [...hits.keys()]) recent(userId, at);
  }

  return {
    attempt(userId) {
      const at = now();
      sweep(at);
      const live = recent(userId, at);
      const oldest = live[0];
      if (live.length >= max && oldest !== undefined) {
        return { allowed: false, retryAfterSeconds: Math.max(1, Math.ceil((oldest + windowMs - at) / 1000)) };
      }
      live.push(at);
      hits.set(userId, live);
      return { allowed: true };
    },
    size: () => hits.size,
  };
}
