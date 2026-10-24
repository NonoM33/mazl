import type { Context } from "hono";
import { createMiddleware } from "hono/factory";
import { clientIp } from "./client-ip";
import type { AppVariables } from "./middleware";

// In-memory sliding windows (CONTRAT.md §2.3). State is per process, which is
// enough to slow scraping and guessing down on a single instance; blocked
// requests are not recorded. Authenticated routes are limited per user id and
// must run after requireAuth; public routes are limited per client address.

const SWEEP_THRESHOLD = 5000;

export interface RateLimiterOptions {
  readonly max: number;
  readonly windowMs: number;
  readonly now?: () => number;
}

interface SlidingWindow<K> {
  // Seconds until a slot frees up when the key is at its limit, otherwise null.
  retryAfter(key: K, at: number): number | null;
  record(key: K, at: number): void;
  forget(key: K): void;
}

function createSlidingWindow<K>(max: number, windowMs: number): SlidingWindow<K> {
  const hits = new Map<K, number[]>();

  function recent(key: K, at: number): number[] {
    const live = (hits.get(key) ?? []).filter((t) => t > at - windowMs);
    if (live.length > 0) hits.set(key, live);
    else hits.delete(key);
    return live;
  }

  // Keys that never come back would otherwise stay in memory forever.
  function sweep(at: number): void {
    if (hits.size < SWEEP_THRESHOLD) return;
    for (const key of [...hits.keys()]) recent(key, at);
  }

  return {
    retryAfter(key, at) {
      sweep(at);
      const live = recent(key, at);
      const oldest = live[0];
      if (live.length < max || oldest === undefined) return null;
      return Math.max(1, Math.ceil((oldest + windowMs - at) / 1000));
    },
    record(key, at) {
      hits.set(key, [...recent(key, at), at]);
    },
    forget(key) {
      hits.delete(key);
    },
  };
}

function tooManyRequests(c: Context, retryAfter: number): Response {
  c.header("Retry-After", String(retryAfter));
  return c.json({ success: false, error: "rate_limited", retry_after: retryAfter }, 429);
}

export function createRateLimiter(options: RateLimiterOptions) {
  const now = options.now ?? Date.now;
  const window = createSlidingWindow<number>(options.max, options.windowMs);
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const at = now();
    const userId = c.get("userId");
    const retryAfter = window.retryAfter(userId, at);
    if (retryAfter !== null) return tooManyRequests(c, retryAfter);
    window.record(userId, at);
    await next();
  });
}

export function createIpRateLimiter(options: RateLimiterOptions) {
  const now = options.now ?? Date.now;
  const window = createSlidingWindow<string>(options.max, options.windowMs);
  return createMiddleware(async (c, next) => {
    const at = now();
    const address = clientIp(c);
    const retryAfter = window.retryAfter(address, at);
    if (retryAfter !== null) return tooManyRequests(c, retryAfter);
    window.record(address, at);
    await next();
  });
}

export interface AttemptGuardOptions {
  readonly maxFailures: number;
  readonly windowMs: number;
  readonly now?: () => number;
}

export interface AttemptGuard {
  // Seconds the key stays locked out, or null when it may try again.
  lockedFor(key: string): number | null;
  recordFailure(key: string): void;
  forget(key: string): void;
}

// Counts FAILED attempts only. Once a key reaches the limit it is locked out,
// right answer included, until its oldest failure leaves the window.
export function createAttemptGuard(options: AttemptGuardOptions): AttemptGuard {
  const now = options.now ?? Date.now;
  const window = createSlidingWindow<string>(options.maxFailures, options.windowMs);
  return {
    lockedFor: (key) => window.retryAfter(key, now()),
    recordFailure: (key) => window.record(key, now()),
    forget: (key) => window.forget(key),
  };
}

export { tooManyRequests };

// A plain counter per arbitrary key (an e-mail address, say), for limits that
// are not about a request's sender.
export function createKeyedLimiter(options: RateLimiterOptions): { retryAfter(key: string): number | null; hit(key: string): void } {
  const guard = createAttemptGuard({ maxFailures: options.max, windowMs: options.windowMs, now: options.now });
  return { retryAfter: (key) => guard.lockedFor(key), hit: (key) => guard.recordFailure(key) };
}
