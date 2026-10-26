import { Hono } from "hono";
import { verifyJWT, extractBearerToken } from "../../auth";
import {
  getEvents,
  getPublishedEventById,
  rsvpToEvent,
  deleteRsvp,
  getUserRsvp,
} from "../../db";
import { assertAdmin } from "../admin/admin.auth";
import { parseRecordId } from "../admin/admin.pagination";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { isIsoDate, parseBody, parseId, parsePage, rsvpBodySchema } from "../../shared/http/validation";
import type { EventAlerts } from "./application/event-alerts";
import { EVENT_ALREADY_OPEN_CODE, EVENT_COMING_SOON_CODE } from "./domain/event-availability";

// Presentation layer for the EVENTS feature (classic events only — NOT couple
// events). `GET /api/events/:id` keeps its OPTIONAL auth: a Bearer token is read
// best-effort to populate `userRsvp`, but no token is required. Only published
// events exist for the public; a draft answers like an unknown id.
// A "coming soon" event (availability) refuses every registration with the code
// event_coming_soon; a member may ask to be told when it opens (« Me prévenir »).

const EVENTS_DEFAULT_LIMIT = 50;
const EVENTS_MAX_LIMIT = 50;

// The organiser is a member: the app has no use for their id, the public gets
// none. The fixture key of a test event is internal too.
function publicEvent<T extends Record<string, unknown>>(event: T): Omit<T, "organizer_id" | "fixture_key"> {
  const { organizer_id: _organizer, fixture_key: _fixture, ...publicFields } = event;
  return publicFields;
}

// The member behind an optional Bearer token, or null.
function optionalMember(header: string | undefined): number | null {
  const token = extractBearerToken(header);
  const payload = token ? verifyJWT(token) : null;
  return payload ? parseInt(payload.sub) : null;
}

export function registerEventsRoutes(app: Hono<{ Variables: AppVariables }>, alerts: EventAlerts): void {
  // Get public events
  app.get("/api/events", async (c) => {
    try {
      const type = c.req.query("type");
      const from = c.req.query("from");
      if (from !== undefined && !isIsoDate(from)) {
        return c.json({ success: false, error: "from: must be a valid YYYY-MM-DD date" }, 400);
      }
      const fromDate = from || new Date().toISOString().split("T")[0];
      const { limit, offset } = parsePage(c.req.query("limit"), c.req.query("offset"), {
        defaultLimit: EVENTS_DEFAULT_LIMIT,
        maxLimit: EVENTS_MAX_LIMIT,
      });

      const events = await getEvents({
        type: type || undefined,
        fromDate,
        publishedOnly: true,
        limit,
        offset,
      });

      return c.json({ success: true, events: events.map((event) => publicEvent(event)) });
    } catch (error: unknown) {
      console.error("Events error:", error);
      return c.json({ success: false, error: "Failed to get events" }, 500);
    }
  });

  // Get event by ID
  app.get("/api/events/:id", async (c) => {
    try {
      const eventId = parseId(c.req.param("id"));
      if (eventId === null) {
        return c.json({ success: false, error: "Invalid event id" }, 400);
      }
      const event = await getPublishedEventById(eventId);

      if (!event) {
        return c.json({ success: false, error: "Event not found" }, 404);
      }

      // A signed-in member also gets their registration and their alert, inside
      // the event too (user_rsvp_status, notify_requested: what the app reads).
      const userId = optionalMember(c.req.header("Authorization"));
      const userRsvp = userId === null ? null : await getUserRsvp(eventId, userId);
      const notifyRequested = userId === null ? false : await alerts.isRequested(eventId, userId);
      const status = (userRsvp as { status?: unknown } | null)?.status;
      return c.json({
        success: true,
        event: { ...publicEvent(event), user_rsvp_status: typeof status === "string" ? status : null, notify_requested: notifyRequested },
        userRsvp,
      });
    } catch (error: unknown) {
      console.error("Event error:", error);
      return c.json({ success: false, error: "Failed to get event" }, 500);
    }
  });

  // RSVP to event
  app.post("/api/events/:id/rsvp", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const eventId = parseId(c.req.param("id"));
      if (eventId === null) {
        return c.json({ success: false, error: "Invalid event id" }, 400);
      }
      const parsed = await parseBody(rsvpBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }

      const outcome = await rsvpToEvent(eventId, userId, parsed.data.status ?? "going");
      switch (outcome.kind) {
        case "not_found":
          return c.json({ success: false, error: "Event not found" }, 404);
        case "coming_soon":
          return c.json({ success: false, error: "Registrations for this event are not open yet", code: EVENT_COMING_SOON_CODE }, 409);
        case "over":
          return c.json({ success: false, error: "Event is over" }, 400);
        case "full":
          return c.json({ success: false, error: "Event is full" }, 400);
        case "registered":
          return c.json({ success: true, rsvp: outcome.rsvp });
      }
    } catch (error: unknown) {
      console.error("RSVP error:", error);
      return c.json({ success: false, error: "Failed to RSVP" }, 500);
    }
  });

  // Cancel RSVP
  app.delete("/api/events/:id/rsvp", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const eventId = parseId(c.req.param("id"));
      if (eventId === null) {
        return c.json({ success: false, error: "Invalid event id" }, 400);
      }

      await deleteRsvp(eventId, userId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Cancel RSVP error:", error);
      return c.json({ success: false, error: "Failed to cancel RSVP" }, 500);
    }
  });

  // « Me prévenir »: tell me by push when this coming soon event opens.
  app.post("/api/events/:id/notify", requireAuth, async (c) => {
    try {
      const eventId = parseId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Invalid event id" }, 400);
      switch (await alerts.request(eventId, c.get("userId"))) {
        case "not_found":
          return c.json({ success: false, error: "Event not found" }, 404);
        case "already_open":
          return c.json({ success: false, error: "Registrations for this event are already open", code: EVENT_ALREADY_OPEN_CODE }, 409);
        default:
          return c.json({ success: true, notifyRequested: true });
      }
    } catch (error: unknown) {
      console.error("Event alert error:", error);
      return c.json({ success: false, error: "Failed to save the alert" }, 500);
    }
  });

  app.delete("/api/events/:id/notify", requireAuth, async (c) => {
    try {
      const eventId = parseId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Invalid event id" }, 400);
      if ((await alerts.withdraw(eventId, c.get("userId"))) === "not_found") return c.json({ success: false, error: "Event not found" }, 404);
      return c.json({ success: true, notifyRequested: false });
    } catch (error: unknown) {
      console.error("Event alert error:", error);
      return c.json({ success: false, error: "Failed to remove the alert" }, 500);
    }
  });

  // Opens a coming soon event to registrations and pushes every member who asked
  // to be told (administrators only). Opening an open event sends the alerts that
  // are still waiting.
  app.post("/api/admin/events/:id/open", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);
    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const outcome = await alerts.open(eventId);
      if (outcome.kind === "not_found") return c.json({ success: false, error: "Not found" }, 404);
      return c.json({ success: true, status: outcome.kind, notified: outcome.notified, pending: outcome.pending });
    } catch (error: unknown) {
      console.error("Open event error:", error);
      return c.json({ success: false, error: "Failed to open the event" }, 500);
    }
  });
}
