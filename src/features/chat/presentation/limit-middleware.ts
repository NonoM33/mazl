import { createMiddleware } from "hono/factory";
import type { AppVariables } from "../../../shared/http/middleware";
import type { SlidingWindow } from "../application/sliding-window";

// Hono middleware over a shared window; same 429 answer as the generic limiter
// (shared/http/rate-limit.ts). Must run after requireAuth.
export function limitBy(window: SlidingWindow) {
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const verdict = window.attempt(c.get("userId"));
    if (!verdict.allowed) {
      c.header("Retry-After", String(verdict.retryAfterSeconds));
      return c.json({ success: false, error: "rate_limited", retry_after: verdict.retryAfterSeconds }, 429);
    }
    await next();
  });
}
