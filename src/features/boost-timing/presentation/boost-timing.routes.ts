import type { Hono, MiddlewareHandler } from "hono";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import { INTERNAL_ERROR, INVALID_BODY, fail, logFailure, ok, readJson } from "../../../shared/http/envelope";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import type { BoostTimingService } from "../application/boost-timing-service";
import type { ActivityRecorder } from "../application/activity-recorder";

export interface BoostTimingRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly timing: BoostTimingService;
  readonly activity: ActivityRecorder;
}

export const scheduleBodySchema = z.object({ at: z.iso.datetime({ offset: true }) });

// GET /api/boost/best-time, POST|DELETE /api/boost/schedule, and the counter of
// sessions fed by the first page of GET /api/discover.
export function registerBoostTimingRoutes(app: Hono<{ Variables: AppVariables }>, deps: BoostTimingRouteDeps): void {
  const { authenticate, timing, activity } = deps;
  const writes = createRateLimiter({ max: 30, windowMs: 60 * 60 * 1000 });

  // Registered before the matching routes: the feed answers, then a session is counted.
  app.get("/api/discover", authenticate, async (c, next) => {
    await next();
    const offset = c.req.query("offset");
    if (c.res.status === 200 && (offset === undefined || offset === "0")) {
      void activity.touch(c.get("userId")).catch((error: unknown) => logFailure("City activity not counted", error));
    }
  });

  app.get("/api/boost/best-time", authenticate, async (c) => {
    try {
      const view = await timing.bestTime(c.get("userId"));
      return ok(c, {
        city: view.city,
        best_time: view.bestTime === null ? null : { starts_at: view.bestTime.startsAt.toISOString(), weekday: view.bestTime.weekday, hour: view.bestTime.hour },
        scheduled_at: view.scheduledAt?.toISOString() ?? null,
      });
    } catch (error: unknown) {
      logFailure("Best time failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });

  app.post("/api/boost/schedule", authenticate, writes, async (c) => {
    try {
      const body = await readJson(c, scheduleBodySchema);
      if (!body.ok) return fail(c, INVALID_BODY, 400);
      const result = await timing.schedule(c.get("userId"), new Date(body.data.at));
      switch (result.kind) {
        case "scheduled":
          return ok(c, { scheduled_at: result.scheduledAt.toISOString() }, 201);
        case "invalid_time":
          return fail(c, "invalid_time", 400);
        case "boosts_exhausted":
          return fail(c, "boosts_exhausted", 402);
        case "already_scheduled":
          return fail(c, "already_scheduled", 409);
      }
    } catch (error: unknown) {
      logFailure("Boost schedule failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });

  app.delete("/api/boost/schedule", authenticate, writes, async (c) => {
    try {
      await timing.cancel(c.get("userId"));
      return ok(c, { scheduled_at: null });
    } catch (error: unknown) {
      logFailure("Boost schedule cancel failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });
}
