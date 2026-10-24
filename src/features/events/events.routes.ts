import { Hono } from "hono";
import { verifyJWT, extractBearerToken } from "../../auth";
import {
  getEvents,
  getPublishedEventById,
  rsvpToEvent,
  deleteRsvp,
  getUserRsvp,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { isIsoDate, parseBody, parseId, parsePage, rsvpBodySchema } from "../../shared/http/validation";

// Presentation layer for the EVENTS feature (classic events only — NOT couple
// events). `GET /api/events/:id` keeps its OPTIONAL auth: a Bearer token is read
// best-effort to populate `userRsvp`, but no token is required. Only published
// events exist for the public; a draft answers like an unknown id.

const EVENTS_DEFAULT_LIMIT = 50;
const EVENTS_MAX_LIMIT = 50;

// The organiser is a member: the app has no use for their id, the public gets none.
function withoutOrganizer<T extends Record<string, unknown>>(event: T): Omit<T, "organizer_id"> {
  const { organizer_id: _organizer, ...publicFields } = event;
  return publicFields;
}

export function registerEventsRoutes(app: Hono<{ Variables: AppVariables }>): void {
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

      return c.json({ success: true, events: events.map((event) => withoutOrganizer(event)) });
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

      // Check if user is logged in to get RSVP status
      let userRsvp = null;
      const token = extractBearerToken(c.req.header("Authorization"));
      if (token) {
        const payload = verifyJWT(token);
        if (payload) {
          const userId = parseInt(payload.sub);
          userRsvp = await getUserRsvp(eventId, userId);
        }
      }

      return c.json({ success: true, event: withoutOrganizer(event), userRsvp });
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
}
