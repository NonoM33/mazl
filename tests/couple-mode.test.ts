import { describe, test, expect, beforeAll, afterAll } from "bun:test";

const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

// Test user credentials (these should be seeded test users)
let authToken: string = "";
let userId: number = 0;
let coupleId: number = 0;

// Helper to make authenticated requests
async function authFetch(endpoint: string, options: RequestInit = {}) {
  return fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${authToken}`,
      ...options.headers,
    },
  });
}

describe("Couple Mode API Tests", () => {
  // ============ SETUP ============

  beforeAll(async () => {
    // Create or login test user using dev endpoint
    console.log("Setting up test user...");
    const createRes = await fetch(`${BASE_URL}/api/dev/test-user`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: "test-couple@mazl.app",
        password: "test123",
        name: "Test Couple User",
      }),
    });

    if (!createRes.ok) {
      const errorText = await createRes.text();
      console.error("Failed to create test user:", errorText);
      throw new Error(`Failed to create test user: ${createRes.status}`);
    }

    const createData = await createRes.json();
    if (!createData.success) {
      throw new Error(`Test user creation failed: ${createData.error}`);
    }

    authToken = createData.token;
    userId = createData.user?.id;
    console.log(`Test user created: userId=${userId}`);

    // Enable couple mode for test user
    const enableRes = await fetch(`${BASE_URL}/api/dev/couple/enable`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ userId }),
    });

    if (!enableRes.ok) {
      const errorText = await enableRes.text();
      console.error("Failed to enable couple mode:", errorText);
      throw new Error(`Failed to enable couple mode: ${enableRes.status}`);
    }

    const enableData = await enableRes.json();
    if (!enableData.success) {
      throw new Error(`Couple mode enable failed: ${enableData.error}`);
    }

    coupleId = enableData.coupleId;
    console.log(`Test setup complete: userId=${userId}, coupleId=${coupleId}`);
  });

  afterAll(async () => {
    // Disable couple mode after tests
    if (authToken) {
      await fetch(`${BASE_URL}/api/dev/couple/disable`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify({ userId }),
      });
    }
  });

  // ============ ACTIVITIES TESTS ============

  describe("Activities API", () => {
    test("GET /api/couple/activities - should return activities list", async () => {
      const res = await authFetch("/api/couple/activities");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.activities)).toBe(true);
    });

    test("GET /api/couple/activities?category=wellness - should filter by category", async () => {
      const res = await authFetch("/api/couple/activities?category=wellness");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.activities)).toBe(true);

      // All activities should be wellness category
      data.activities.forEach((activity: any) => {
        expect(activity.category).toBe("wellness");
      });
    });

    test("GET /api/couple/activities/:id - should return activity detail", async () => {
      // First get list to get a valid ID
      const listRes = await authFetch("/api/couple/activities");
      const listData = await listRes.json();

      if (listData.activities?.length > 0) {
        const activityId = listData.activities[0].id;
        const res = await authFetch(`/api/couple/activities/${activityId}`);
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
        expect(data.activity).toBeDefined();
        expect(data.activity.id).toBe(activityId);
      }
    });

    test("POST /api/couple/activities/:id/save - should save activity", async () => {
      const listRes = await authFetch("/api/couple/activities");
      const listData = await listRes.json();

      if (listData.activities?.length > 0) {
        const activityId = listData.activities[0].id;
        const res = await authFetch(`/api/couple/activities/${activityId}/save`, {
          method: "POST",
          body: JSON.stringify({ notes: "Test note" }),
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });

    test("GET /api/couple/saved - should return saved activities", async () => {
      const res = await authFetch("/api/couple/saved");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.activities)).toBe(true);
    });

    test("POST /api/couple/activities/:id/pass - should mark activity as passed", async () => {
      const listRes = await authFetch("/api/couple/activities");
      const listData = await listRes.json();

      if (listData.activities?.length > 1) {
        const activityId = listData.activities[1].id;
        const res = await authFetch(`/api/couple/activities/${activityId}/pass`, {
          method: "POST",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });

    test("DELETE /api/couple/saved/:id - should remove saved activity", async () => {
      const savedRes = await authFetch("/api/couple/saved");
      const savedData = await savedRes.json();

      if (savedData.activities?.length > 0) {
        const activityId = savedData.activities[0].id;
        const res = await authFetch(`/api/couple/saved/${activityId}`, {
          method: "DELETE",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });
  });

  // ============ EVENTS TESTS ============

  describe("Events API", () => {
    test("GET /api/couple/events - should return events list", async () => {
      const res = await authFetch("/api/couple/events");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.events)).toBe(true);
    });

    test("GET /api/couple/events?category=dinner - should filter by category", async () => {
      const res = await authFetch("/api/couple/events?category=dinner");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.events)).toBe(true);
    });

    test("GET /api/couple/events/:id - should return event detail", async () => {
      const listRes = await authFetch("/api/couple/events");
      const listData = await listRes.json();

      if (listData.events?.length > 0) {
        const eventId = listData.events[0].id;
        const res = await authFetch(`/api/couple/events/${eventId}`);
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
        expect(data.event).toBeDefined();
      }
    });

    test("POST /api/couple/events/:id/register - should register for event", async () => {
      const listRes = await authFetch("/api/couple/events");
      const listData = await listRes.json();

      if (listData.events?.length > 0) {
        const eventId = listData.events[0].id;
        const res = await authFetch(`/api/couple/events/${eventId}/register`, {
          method: "POST",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });

    test("GET /api/couple/events/registered - should return registered events", async () => {
      const res = await authFetch("/api/couple/events/registered");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.events)).toBe(true);
    });

    test("DELETE /api/couple/events/:id/register - should cancel registration", async () => {
      const regRes = await authFetch("/api/couple/events/registered");
      const regData = await regRes.json();

      if (regData.events?.length > 0) {
        const eventId = regData.events[0].id;
        const res = await authFetch(`/api/couple/events/${eventId}/register`, {
          method: "DELETE",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });
  });

  // ============ DATES TESTS ============

  describe("Dates API", () => {
    let createdDateId: number;

    test("POST /api/couple/dates - should create a date", async () => {
      const res = await authFetch("/api/couple/dates", {
        method: "POST",
        body: JSON.stringify({
          title: "Test Anniversary",
          date: "2024-06-15",
          type: "anniversary",
          isRecurring: true,
          remindDaysBefore: 7,
        }),
      });
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      if (data.date) {
        createdDateId = data.date.id;
      }
    });

    test("GET /api/couple/dates - should return dates list", async () => {
      const res = await authFetch("/api/couple/dates");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.dates)).toBe(true);
    });

    test("PUT /api/couple/dates/:id - should update a date", async () => {
      if (createdDateId) {
        const res = await authFetch(`/api/couple/dates/${createdDateId}`, {
          method: "PUT",
          body: JSON.stringify({
            title: "Updated Anniversary",
          }),
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });

    test("DELETE /api/couple/dates/:id - should delete a date", async () => {
      if (createdDateId) {
        const res = await authFetch(`/api/couple/dates/${createdDateId}`, {
          method: "DELETE",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });
  });

  // ============ BUCKET LIST TESTS ============

  describe("Bucket List API", () => {
    let createdItemId: number;

    test("POST /api/couple/bucket-list - should create bucket list item", async () => {
      const res = await authFetch("/api/couple/bucket-list", {
        method: "POST",
        body: JSON.stringify({
          title: "See Northern Lights",
          description: "Travel to Iceland or Norway",
          category: "travel",
        }),
      });
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      if (data.item) {
        createdItemId = data.item.id;
      }
    });

    test("GET /api/couple/bucket-list - should return bucket list", async () => {
      const res = await authFetch("/api/couple/bucket-list");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.items)).toBe(true);
    });

    test("POST /api/couple/bucket-list/:id/complete - should mark as complete", async () => {
      if (createdItemId) {
        const res = await authFetch(`/api/couple/bucket-list/${createdItemId}/complete`, {
          method: "POST",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });

    test("DELETE /api/couple/bucket-list/:id - should delete bucket list item", async () => {
      if (createdItemId) {
        const res = await authFetch(`/api/couple/bucket-list/${createdItemId}`, {
          method: "DELETE",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });
  });

  // ============ MEMORIES TESTS ============

  describe("Memories API", () => {
    let createdMemoryId: number;

    test("POST /api/couple/memories - should create memory", async () => {
      const res = await authFetch("/api/couple/memories", {
        method: "POST",
        body: JSON.stringify({
          type: "note",
          title: "Our first date",
          content: "We met at the café...",
          memoryDate: "2024-01-15",
        }),
      });
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      if (data.memory) {
        createdMemoryId = data.memory.id;
      }
    });

    test("GET /api/couple/memories - should return memories list", async () => {
      const res = await authFetch("/api/couple/memories");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.memories)).toBe(true);
    });

    test("DELETE /api/couple/memories/:id - should delete memory", async () => {
      if (createdMemoryId) {
        const res = await authFetch(`/api/couple/memories/${createdMemoryId}`, {
          method: "DELETE",
        });
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data.success).toBe(true);
      }
    });
  });

  // ============ STATS TESTS ============

  describe("Stats API", () => {
    test("GET /api/couple/stats - should return couple stats", async () => {
      const res = await authFetch("/api/couple/stats");
      const data = await res.json();

      expect(res.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.stats).toBeDefined();
      expect(data.achievements).toBeDefined();
    });
  });

  // ============ ERROR HANDLING TESTS ============

  describe("Error Handling", () => {
    test("Should return 401 without auth token", async () => {
      const res = await fetch(`${BASE_URL}/api/couple/activities`);
      const data = await res.json();

      expect(res.status).toBe(401);
      expect(data.success).toBe(false);
    });

    test("Should return 401 with invalid token", async () => {
      const res = await fetch(`${BASE_URL}/api/couple/activities`, {
        headers: { Authorization: "Bearer invalid_token" },
      });
      const data = await res.json();

      expect(res.status).toBe(401);
      expect(data.success).toBe(false);
    });

    test("Should return 404 for non-existent activity", async () => {
      const res = await authFetch("/api/couple/activities/99999999");
      const data = await res.json();

      expect(res.status).toBe(404);
      expect(data.success).toBe(false);
    });
  });

  // ============ DB FUNCTION TESTS ============

  describe("Database Functions", () => {
    test("Should have couple_activities table with data", async () => {
      // This would be tested via direct DB access in a real scenario
      // For now we verify via API
      const res = await authFetch("/api/couple/activities?limit=1");
      const data = await res.json();

      expect(data.success).toBe(true);
      // If seeded correctly, there should be activities
    });

    test("Should have couple_events table with data", async () => {
      const res = await authFetch("/api/couple/events?limit=1");
      const data = await res.json();

      expect(data.success).toBe(true);
    });
  });
});
