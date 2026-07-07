import { Hono } from "hono";
import { verifyJWT, extractBearerToken } from "../../auth";
import {
  getEvents,
  getEventById,
  createRsvp,
  deleteRsvp,
  getUserRsvp,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";

// Presentation layer for the EVENTS feature (classic events only — NOT couple
// events). These routes are moved verbatim from the monolith (src/index.ts).
// Behaviour, payloads, status codes and ordering are identical to the original
// inline handlers. `GET /api/events/:id` keeps its OPTIONAL auth: a Bearer token
// is read best-effort to populate `userRsvp`, but no token is required.
export function registerEventsRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get public events
  app.get("/api/events", async (c) => {
    try {
      const type = c.req.query("type");
      const fromDate = c.req.query("from") || new Date().toISOString().split("T")[0];
      const limit = parseInt(c.req.query("limit") || "50");
      const offset = parseInt(c.req.query("offset") || "0");

      const events = await getEvents({
        type: type || undefined,
        fromDate,
        publishedOnly: true,
        limit,
        offset,
      });

      return c.json({ success: true, events });
    } catch (error: unknown) {
      console.error("Events error:", error);
      return c.json({ success: false, error: "Failed to get events" }, 500);
    }
  });

  // Get event by ID
  app.get("/api/events/:id", async (c) => {
    try {
      const eventId = parseInt(c.req.param("id"));
      const event = await getEventById(eventId);

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

      return c.json({ success: true, event, userRsvp });
    } catch (error: unknown) {
      console.error("Event error:", error);
      return c.json({ success: false, error: "Failed to get event" }, 500);
    }
  });

  // RSVP to event
  app.post("/api/events/:id/rsvp", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const eventId = parseInt(c.req.param("id"));
      const { status } = await c.req.json().catch(() => ({ status: "going" }));

      const event = await getEventById(eventId);
      if (!event) {
        return c.json({ success: false, error: "Event not found" }, 404);
      }

      // Check max attendees
      const eventRecord = event as { max_attendees?: number; attendee_count?: number };
      if (
        eventRecord.max_attendees &&
        (eventRecord.attendee_count ?? 0) >= eventRecord.max_attendees
      ) {
        return c.json({ success: false, error: "Event is full" }, 400);
      }

      const rsvp = await createRsvp(eventId, userId, status || "going");

      return c.json({ success: true, rsvp });
    } catch (error: unknown) {
      console.error("RSVP error:", error);
      return c.json({ success: false, error: "Failed to RSVP" }, 500);
    }
  });

  // Cancel RSVP
  app.delete("/api/events/:id/rsvp", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const eventId = parseInt(c.req.param("id"));

      await deleteRsvp(eventId, userId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Cancel RSVP error:", error);
      return c.json({ success: false, error: "Failed to cancel RSVP" }, 500);
    }
  });
}
