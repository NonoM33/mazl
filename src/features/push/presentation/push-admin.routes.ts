import type { Context, Hono } from "hono";
import { z } from "zod";
import type { AdminAuthResult } from "../../admin/admin.auth";
import type { AppVariables } from "../../../shared/http/middleware";
import { idSchema, parseBody } from "../../../shared/http/validation";
import type { PushResult } from "../application/ports";
import type { EventAvailable, EventAvailableOutcome } from "../application/push-notifier";

// Administrators' pushes: tell a list of members that an event is open, send a
// test push to one member (the proof that a device receives them), and say
// whether pushes can leave at all. The key is never shown, only its presence.

const MAX_RECIPIENTS = 5000;

const eventAvailableSchema = z.object({
  event_id: idSchema,
  user_ids: z.array(idSchema).min(1).max(MAX_RECIPIENTS),
});

const testPushSchema = z.object({ user_id: idSchema });

export interface PushAdminDeps {
  readonly isAdmin: (c: Context) => AdminAuthResult;
  readonly isConfigured: () => boolean;
  // Published events only: a draft is not announced.
  readonly loadEvent: (eventId: number) => Promise<{ readonly id: number; readonly title: string } | null>;
  readonly notifier: {
    eventAvailable(event: EventAvailable): Promise<EventAvailableOutcome>;
    testPush(userId: number): Promise<PushResult>;
  };
}

export function registerPushAdminRoutes(app: Hono<{ Variables: AppVariables }>, deps: PushAdminDeps): void {
  app.get("/api/admin/push/status", (c) => {
    const auth = deps.isAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);
    return c.json({ success: true, configured: deps.isConfigured() });
  });

  app.post("/api/admin/push/event-available", async (c) => {
    const auth = deps.isAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);
    const parsed = await parseBody(eventAvailableSchema, c);
    if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
    if (!deps.isConfigured()) return c.json({ success: false, error: "push_not_configured" }, 503);
    try {
      const event = await deps.loadEvent(parsed.data.event_id);
      if (event === null) return c.json({ success: false, error: "Event not found" }, 404);
      const outcome = await deps.notifier.eventAvailable({ eventId: event.id, title: event.title, recipientIds: parsed.data.user_ids });
      console.log(`Event ${event.id} announced: ${outcome.sent} sent, ${outcome.skipped} skipped, ${outcome.failed} failed`);
      return c.json({ success: true, ...outcome });
    } catch (error: unknown) {
      console.error("Event announcement failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "Failed to announce the event" }, 500);
    }
  });

  app.post("/api/admin/push/test", async (c) => {
    const auth = deps.isAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);
    const parsed = await parseBody(testPushSchema, c);
    if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
    const result = await deps.notifier.testPush(parsed.data.user_id);
    return result.ok ? c.json({ success: true, sent: true }) : c.json({ success: false, sent: false, error: result.reason }, 502);
  });
}
