import type { Hono, MiddlewareHandler } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
import { INTERNAL_ERROR, fail, logFailure, ok } from "../../../shared/http/envelope";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import type { SwipeUndoService } from "../application/swipe-undo-service";

export interface SwipeUndoRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly undo: SwipeUndoService;
}

const UNDOS_PER_MINUTE = 20;

// POST /api/swipes/undo: takes back the last pass or like. 402 undo_limit_reached
// once the free one of the day is used, 404 nothing_to_undo, 409 undo_not_possible.
export function registerSwipeUndoRoute(app: Hono<{ Variables: AppVariables }>, deps: SwipeUndoRouteDeps): void {
  const limiter = createRateLimiter({ max: UNDOS_PER_MINUTE, windowMs: 60_000 });
  app.post("/api/swipes/undo", deps.authenticate, limiter, async (c) => {
    try {
      const outcome = await deps.undo.undo(c.get("userId"));
      switch (outcome.kind) {
        case "undone":
          return ok(c, { target_user_id: outcome.targetUserId, action: outcome.action, remaining_free_undos: outcome.remainingFreeUndos });
        case "limit_reached":
          return fail(c, "undo_limit_reached", 402);
        case "nothing_to_undo":
          return fail(c, "nothing_to_undo", 404);
        case "not_possible":
          return fail(c, "undo_not_possible", 409);
      }
    } catch (error: unknown) {
      logFailure("Undo failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });
}
