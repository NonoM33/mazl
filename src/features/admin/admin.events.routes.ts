import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import {
  getEvents,
  createEvent,
  updateEvent,
  deleteEvent,
  getEventAttendees,
  getEventFullDetails,
  addEventPhoto,
  deleteEventPhoto,
  checkInAttendee,
  exportEventAttendees,
  duplicateEvent,
  sql,
} from "../../db";
import { isReduction, readMemberPrice } from "../events/domain/member-price";
import { assertAdmin } from "./admin.auth";
import { toCsv } from "./admin.csv";
import { parsePagination, parseRecordId } from "./admin.pagination";

// Admin events routes, moved verbatim from the monolith (src/index.ts). Two
// original blocks are preserved in order: the "ADMIN EVENTS" CRUD block, then
// (after members) the "MODULE 2: GESTION EVENTS" block (details, photos,
// check-in, export, duplicate). Same paths, behaviour, payloads, status codes.

export function registerAdminEventsCrudRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get all events (admin)
  app.get("/api/admin/events", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const { limit, offset } = parsePagination(c.req.query("limit"), c.req.query("offset"));

      const events = await getEvents({
        publishedOnly: false,
        limit,
        offset,
      });

      return c.json({ success: true, events });
    } catch (error: unknown) {
      console.error("Admin events error:", error);
      return c.json({ success: false, error: "Failed to get events" }, 500);
    }
  });

  // Create event (admin)
  app.post("/api/admin/events", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const body = await c.req.json();

      if (!body.title || !body.date) {
        return c.json({ success: false, error: "Title and date required" }, 400);
      }
      const memberPrice = readMemberPrice(body.memberPriceCents);
      if (memberPrice.kind === "invalid" || (memberPrice.kind === "set" && !isReduction(memberPrice.cents, body.price ?? 0))) {
        return c.json({ success: false, error: "member_price_invalid" }, 400);
      }

      const event = await createEvent({
        title: body.title,
        description: body.description,
        eventType: body.eventType,
        location: body.location,
        address: body.address,
        latitude: body.latitude,
        longitude: body.longitude,
        date: body.date,
        time: body.time,
        endTime: body.endTime,
        price: body.price,
        currency: body.currency,
        maxAttendees: body.maxAttendees,
        imageUrl: body.imageUrl,
        isPublished: body.isPublished ?? false,
        ...(memberPrice.kind === "set" ? { memberPriceCents: memberPrice.cents } : {}),
      });

      return c.json({ success: true, event });
    } catch (error: unknown) {
      console.error("Create event error:", error);
      return c.json({ success: false, error: "Failed to create event" }, 500);
    }
  });

  // Update event (admin)
  app.put("/api/admin/events/:id", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const body = await c.req.json();

      const memberPrice = readMemberPrice(body.memberPriceCents);
      if (memberPrice.kind === "invalid") return c.json({ success: false, error: "member_price_invalid" }, 400);
      if (memberPrice.kind === "set") {
        // Against the price this update leaves the event with.
        const [stored] = await sql<{ price: string }[]>`SELECT price FROM events WHERE id = ${eventId}`;
        if (stored === undefined) return c.json({ success: false, error: "Not found" }, 404);
        if (!isReduction(memberPrice.cents, body.price ?? stored.price)) return c.json({ success: false, error: "member_price_invalid" }, 400);
      }

      const event = await updateEvent(eventId, {
        title: body.title,
        description: body.description,
        eventType: body.eventType,
        location: body.location,
        address: body.address,
        latitude: body.latitude,
        longitude: body.longitude,
        date: body.date,
        time: body.time,
        endTime: body.endTime,
        price: body.price,
        currency: body.currency,
        maxAttendees: body.maxAttendees,
        imageUrl: body.imageUrl,
        isPublished: body.isPublished,
        ...(memberPrice.kind === "set" ? { memberPriceCents: memberPrice.cents } : {}),
        ...(memberPrice.kind === "remove" ? { memberPriceCents: null } : {}),
      });

      return c.json({ success: true, event });
    } catch (error: unknown) {
      console.error("Update event error:", error);
      return c.json({ success: false, error: "Failed to update event" }, 500);
    }
  });

  // Delete event (admin)
  app.delete("/api/admin/events/:id", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      await deleteEvent(eventId);
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete event error:", error);
      return c.json({ success: false, error: "Failed to delete event" }, 500);
    }
  });

  // Get event attendees (admin)
  app.get("/api/admin/events/:id/attendees", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const attendees = await getEventAttendees(eventId);
      return c.json({ success: true, attendees });
    } catch (error: unknown) {
      console.error("Event attendees error:", error);
      return c.json({ success: false, error: "Failed to get attendees" }, 500);
    }
  });
}

export function registerAdminEventsModuleRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get event full details (admin)
  app.get("/api/admin/events/:id/details", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const event = await getEventFullDetails(eventId);

      if (!event) {
        return c.json({ success: false, error: "Event not found" }, 404);
      }

      return c.json({ success: true, event });
    } catch (error: unknown) {
      console.error("Get event details error:", error);
      return c.json({ success: false, error: "Failed to get event" }, 500);
    }
  });

  // Upload event photo (admin)
  app.post("/api/admin/events/:id/photos", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const body = await c.req.json();

      if (!body.url) {
        return c.json({ success: false, error: "URL required" }, 400);
      }

      const photo = await addEventPhoto({
        eventId,
        url: body.url,
        position: body.position,
        isCover: body.isCover,
      });

      return c.json({ success: true, photo });
    } catch (error: unknown) {
      console.error("Add photo error:", error);
      return c.json({ success: false, error: "Failed to add photo" }, 500);
    }
  });

  // Delete event photo (admin)
  app.delete("/api/admin/events/:id/photos/:photoId", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const photoId = parseRecordId(c.req.param("photoId"));
      if (photoId === null) return c.json({ success: false, error: "Not found" }, 404);
      await deleteEventPhoto(photoId);
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete photo error:", error);
      return c.json({ success: false, error: "Failed to delete photo" }, 500);
    }
  });

  // Check-in attendee (admin)
  app.post("/api/admin/events/:id/checkin", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const { userId } = await c.req.json();

      if (!userId) {
        return c.json({ success: false, error: "User ID required" }, 400);
      }

      const checkin = await checkInAttendee({
        eventId,
        userId,
        checkedInBy: auth.email || "admin",
      });

      return c.json({ success: true, checkin });
    } catch (error: unknown) {
      console.error("Check-in error:", error);
      return c.json({ success: false, error: "Failed to check in" }, 500);
    }
  });

  // Export attendees CSV (admin)
  app.get("/api/admin/events/:id/export", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const attendees = await exportEventAttendees(eventId);

      // Generate CSV
      const headers = ["email", "name", "display_name", "status", "paid", "rsvp_at", "checked_in_at"];
      const csv = toCsv(headers, attendees as Array<Record<string, unknown>>);

      return new Response(csv, {
        headers: {
          "Content-Type": "text/csv",
          "Content-Disposition": `attachment; filename="event-${eventId}-attendees.csv"`,
        },
      });
    } catch (error: unknown) {
      console.error("Export error:", error);
      return c.json({ success: false, error: "Failed to export" }, 500);
    }
  });

  // Duplicate event (admin)
  app.post("/api/admin/events/:id/duplicate", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const eventId = parseRecordId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Not found" }, 404);
      const newEvent = await duplicateEvent(eventId);

      if (!newEvent) {
        return c.json({ success: false, error: "Event not found" }, 404);
      }

      return c.json({ success: true, event: newEvent });
    } catch (error: unknown) {
      console.error("Duplicate error:", error);
      return c.json({ success: false, error: "Failed to duplicate" }, 500);
    }
  });
}
