import { Hono } from "hono";
import {
  getCoupleByUserId,
  getCoupleActivities,
  getCoupleActivity,
  saveCoupleActivity,
  passCoupleActivity,
  getSavedActivities,
  removeSavedActivity,
  createCoupleBooking,
  getCoupleBookings,
  getCoupleEvents,
  getCoupleRegisteredEvents,
  getCoupleEvent,
  registerForCoupleEvent,
  cancelCoupleEventRegistration,
  getCoupleMemories,
  addCoupleMemory,
  deleteCoupleMemory,
  getCoupleDates,
  addCoupleDate,
  updateCoupleDate,
  deleteCoupleDate,
  getBucketList,
  addBucketListItem,
  completeBucketListItem,
  deleteBucketListItem,
  getCoupleStats,
  getCoupleAchievements,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parseBody } from "../../shared/http/validation";
import {
  bookingBodySchema,
  bucketItemBodySchema,
  coupleId,
  dateBodySchema,
  dateUpdateBodySchema,
  GENERIC_SERVER_ERROR,
  memoryBodySchema,
  parsePagination,
  parseRouteId,
  saveActivityBodySchema,
  type CoupleRow,
} from "./couple.shared";

// COUPLE feature — content endpoints: activities feed, saved activities,
// bookings, events, memories, dates, bucket-list and stats/achievements. Moved
// verbatim from src/index.ts. The literal `activities` / `saved` / `events`
// (with `events/registered` before `events/:id`) routes preserve their exact
// original relative order so parameterised segments never capture literals.
export function registerCoupleContentRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // ============ COUPLE MODE - ACTIVITIES FEED ============

  // Get couple activities feed
  app.get("/api/couple/activities", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const page = parsePagination(c.req.query("limit"), c.req.query("offset"));
      if (!page) return c.json({ success: false, error: "limit must be 1-100 and offset 0 or more" }, 400);
      const category = c.req.query("category");

      const activities = await getCoupleActivities(coupleId(couple as CoupleRow), page.limit, page.offset, category || undefined);

      return c.json({ success: true, activities });
    } catch (error: unknown) {
      console.error("Get couple activities error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Get single activity detail
  app.get("/api/couple/activities/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const activityId = parseRouteId(c.req.param("id"));
      if (activityId === null) return c.json({ success: false, error: "Activity not found" }, 404);
      const activity = await getCoupleActivity(activityId);

      if (!activity) return c.json({ success: false, error: "Activity not found" }, 404);

      return c.json({ success: true, activity });
    } catch (error: unknown) {
      console.error("Get activity error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Save activity (swipe up / bookmark)
  app.post("/api/couple/activities/:id/save", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const activityId = parseRouteId(c.req.param("id"));
      if (activityId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      const body = saveActivityBodySchema.safeParse(await c.req.json().catch(() => ({})));
      if (!body.success) return c.json({ success: false, error: "Invalid notes" }, 400);
      if (!(await getCoupleActivity(activityId))) {
        return c.json({ success: false, error: "Activity not found" }, 404);
      }

      await saveCoupleActivity(coupleId(couple as CoupleRow), activityId, body.data.notes ?? undefined);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Save activity error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Pass activity (swipe left)
  app.post("/api/couple/activities/:id/pass", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const activityId = parseRouteId(c.req.param("id"));
      if (activityId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      if (!(await getCoupleActivity(activityId))) {
        return c.json({ success: false, error: "Activity not found" }, 404);
      }
      await passCoupleActivity(coupleId(couple as CoupleRow), activityId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Pass activity error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Get saved activities
  app.get("/api/couple/saved", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const activities = await getSavedActivities(coupleId(couple as CoupleRow));

      return c.json({ success: true, activities });
    } catch (error: unknown) {
      console.error("Get saved activities error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Remove saved activity
  app.delete("/api/couple/saved/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const activityId = parseRouteId(c.req.param("id"));
      if (activityId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      await removeSavedActivity(coupleId(couple as CoupleRow), activityId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Remove saved activity error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Create booking
  app.post("/api/couple/bookings", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const parsed = await parseBody(bookingBodySchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const result = await createCoupleBooking({
        coupleId: coupleId(couple as CoupleRow),
        activityId: parsed.data.activityId,
        eventId: parsed.data.eventId,
        bookingDate: parsed.data.bookingDate,
        bookingTime: parsed.data.bookingTime,
        notes: parsed.data.notes,
      });
      if (!result.ok) return c.json({ success: false, error: result.error }, result.status);

      return c.json({ success: true, booking: result.booking });
    } catch (error: unknown) {
      console.error("Create booking error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Get bookings
  app.get("/api/couple/bookings", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const bookings = await getCoupleBookings(coupleId(couple as CoupleRow));

      return c.json({ success: true, bookings });
    } catch (error: unknown) {
      console.error("Get bookings error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // ============ COUPLE MODE - EVENTS ============

  // Get couple events
  app.get("/api/couple/events", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const page = parsePagination(c.req.query("limit"), c.req.query("offset"));
      if (!page) return c.json({ success: false, error: "limit must be 1-100 and offset 0 or more" }, 400);
      const category = c.req.query("category");

      const events = await getCoupleEvents(page.limit, page.offset, category || undefined);

      return c.json({ success: true, events });
    } catch (error: unknown) {
      console.error("Get couple events error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Get registered events (must be before :id route)
  app.get("/api/couple/events/registered", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const events = await getCoupleRegisteredEvents(coupleId(couple as CoupleRow));

      return c.json({ success: true, events });
    } catch (error: unknown) {
      console.error("Get registered events error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Get single event
  app.get("/api/couple/events/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const eventId = parseRouteId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Event not found" }, 404);
      const event = await getCoupleEvent(eventId);

      if (!event) return c.json({ success: false, error: "Event not found" }, 404);

      return c.json({ success: true, event });
    } catch (error: unknown) {
      console.error("Get event error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Register for event
  app.post("/api/couple/events/:id/register", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const eventId = parseRouteId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Event not found" }, 404);
      const result = await registerForCoupleEvent(coupleId(couple as CoupleRow), eventId);
      if (!result.ok) return c.json({ success: false, error: result.error }, result.status);

      return c.json({ success: true, registration: result.registration });
    } catch (error: unknown) {
      console.error("Register for event error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Cancel registration
  app.delete("/api/couple/events/:id/register", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const eventId = parseRouteId(c.req.param("id"));
      if (eventId === null) return c.json({ success: false, error: "Event not found" }, 404);
      await cancelCoupleEventRegistration(coupleId(couple as CoupleRow), eventId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Cancel registration error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });
  // ============ COUPLE MODE - MEMORIES ============

  // Get memories
  app.get("/api/couple/memories", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const memories = await getCoupleMemories(coupleId(couple as CoupleRow));

      return c.json({ success: true, memories });
    } catch (error: unknown) {
      console.error("Get memories error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Add memory
  app.post("/api/couple/memories", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const parsed = await parseBody(memoryBodySchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const memory = await addCoupleMemory({
        coupleId: coupleId(couple as CoupleRow),
        type: parsed.data.type,
        title: parsed.data.title ?? undefined,
        content: parsed.data.content ?? undefined,
        imageUrl: parsed.data.imageUrl ?? undefined,
        memoryDate: parsed.data.memoryDate ?? undefined,
        location: parsed.data.location ?? undefined,
        createdBy: userId,
      });

      return c.json({ success: true, memory });
    } catch (error: unknown) {
      console.error("Add memory error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Delete memory
  app.delete("/api/couple/memories/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const memoryId = parseRouteId(c.req.param("id"));
      if (memoryId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      await deleteCoupleMemory(coupleId(couple as CoupleRow), memoryId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete memory error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // ============ COUPLE MODE - DATES ============

  // Get dates
  app.get("/api/couple/dates", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const dates = await getCoupleDates(coupleId(couple as CoupleRow));

      return c.json({ success: true, dates });
    } catch (error: unknown) {
      console.error("Get dates error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Add date
  app.post("/api/couple/dates", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const parsed = await parseBody(dateBodySchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const date = await addCoupleDate({
        coupleId: coupleId(couple as CoupleRow),
        title: parsed.data.title,
        date: parsed.data.date,
        type: parsed.data.type,
        isRecurring: parsed.data.isRecurring ?? undefined,
        remindDaysBefore: parsed.data.remindDaysBefore ?? undefined,
        notes: parsed.data.notes ?? undefined,
      });

      return c.json({ success: true, date });
    } catch (error: unknown) {
      console.error("Add date error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Update date
  app.put("/api/couple/dates/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const dateId = parseRouteId(c.req.param("id"));
      if (dateId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      const parsed = await parseBody(dateUpdateBodySchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);

      const date = await updateCoupleDate(coupleId(couple as CoupleRow), dateId, parsed.data);

      return c.json({ success: true, date });
    } catch (error: unknown) {
      console.error("Update date error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Delete date
  app.delete("/api/couple/dates/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const dateId = parseRouteId(c.req.param("id"));
      if (dateId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      await deleteCoupleDate(coupleId(couple as CoupleRow), dateId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete date error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // ============ COUPLE MODE - BUCKET LIST ============

  // Get bucket list
  app.get("/api/couple/bucket-list", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const items = await getBucketList(coupleId(couple as CoupleRow));

      return c.json({ success: true, items });
    } catch (error: unknown) {
      console.error("Get bucket list error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Add bucket list item
  app.post("/api/couple/bucket-list", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const parsed = await parseBody(bucketItemBodySchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const item = await addBucketListItem({
        coupleId: coupleId(couple as CoupleRow),
        title: parsed.data.title,
        description: parsed.data.description ?? undefined,
        category: parsed.data.category ?? undefined,
        targetDate: parsed.data.targetDate ?? undefined,
      });

      return c.json({ success: true, item });
    } catch (error: unknown) {
      console.error("Add bucket list item error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Complete bucket list item
  app.post("/api/couple/bucket-list/:id/complete", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const itemId = parseRouteId(c.req.param("id"));
      if (itemId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      const item = await completeBucketListItem(coupleId(couple as CoupleRow), itemId);

      return c.json({ success: true, item });
    } catch (error: unknown) {
      console.error("Complete bucket list item error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Delete bucket list item
  app.delete("/api/couple/bucket-list/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const itemId = parseRouteId(c.req.param("id"));
      if (itemId === null) return c.json({ success: false, error: "Invalid id" }, 400);
      await deleteBucketListItem(coupleId(couple as CoupleRow), itemId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete bucket list item error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // ============ COUPLE MODE - STATS & ACHIEVEMENTS ============

  // Get couple stats
  app.get("/api/couple/stats", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const couple = await getCoupleByUserId(userId);
      if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

      const stats = await getCoupleStats(coupleId(couple as CoupleRow));
      const achievements = await getCoupleAchievements(coupleId(couple as CoupleRow));

      return c.json({ success: true, stats, achievements });
    } catch (error: unknown) {
      console.error("Get couple stats error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });
}
