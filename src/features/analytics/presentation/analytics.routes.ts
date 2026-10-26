import type { Hono, MiddlewareHandler } from "hono";
import { bodyLimit } from "hono/body-limit";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import type { AnalyticsService } from "../application/analytics-service";
import { parseClientContext } from "../domain/events";

export interface AnalyticsRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  // Per member, applied after authenticate.
  readonly limiter: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly analytics: Pick<AnalyticsService, "recordClientEvents">;
}

const MAX_EVENTS_PER_BATCH = 50;
const MAX_BODY_BYTES = 64 * 1024;

// The envelope only: each event is checked against the tracking plan by the service.
const batchSchema = z.object({
  platform: z.string(),
  app_version: z.string(),
  events: z.array(z.unknown()).max(MAX_EVENTS_PER_BATCH),
});

export function registerAnalyticsRoutes(app: Hono<{ Variables: AppVariables }>, deps: AnalyticsRouteDeps): void {
  // The app and the website relay their events here; the server alone talks to OpenPanel.
  app.post(
    "/api/analytics/events",
    bodyLimit({ maxSize: MAX_BODY_BYTES, onError: (c) => c.json({ success: false, error: "payload_too_large" }, 413) }),
    deps.authenticate,
    deps.limiter,
    async (c) => {
      const raw: unknown = await c.req.json().catch(() => undefined);
      const batch = batchSchema.safeParse(raw);
      const context = batch.success ? parseClientContext(batch.data) : null;
      if (!batch.success || context === null) return c.json({ success: false, error: "invalid_body" }, 400);
      try {
        const accepted = await deps.analytics.recordClientEvents(c.get("userId"), context, batch.data.events);
        return c.json({ success: true, accepted }, 202);
      } catch (error: unknown) {
        console.error("Analytics relay failed:", error instanceof Error ? error.name : "unknown");
        return c.json({ success: false, error: "internal_error" }, 500);
      }
    },
  );
}
