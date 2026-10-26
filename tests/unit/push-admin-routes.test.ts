import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import type { AppVariables } from "../../src/shared/http/middleware";
import type { EventAvailable, EventAvailableOutcome } from "../../src/features/push/application/push-notifier";
import type { PushResult } from "../../src/features/push/application/ports";
import { registerPushAdminRoutes, type PushAdminDeps } from "../../src/features/push/presentation/push-admin.routes";

// The administrators' push routes: tell a list of members that an event is
// open, send a test push to one member, and say whether pushes can leave at
// all. Only an administrator gets past the guard; nothing here reaches OneSignal.

const events: Record<number, { id: number; title: string }> = { 12: { id: 12, title: "Shabbat à Paris" } };
let told: EventAvailable[] = [];
let tested: number[] = [];
let configured = true;
let app: Hono<{ Variables: AppVariables }>;

beforeEach(() => {
  told = [];
  tested = [];
  configured = true;
  const deps: PushAdminDeps = {
    isAdmin: (c) => (c.req.header("authorization") === "Bearer admin" ? { ok: true } : { ok: false, error: "Unauthorized" }),
    isConfigured: () => configured,
    loadEvent: (id) => Promise.resolve(events[id] ?? null),
    notifier: {
      eventAvailable: (event): Promise<EventAvailableOutcome> => {
        told.push(event);
        return Promise.resolve({ requested: event.recipientIds.length, sent: event.recipientIds.length, skipped: 0, failed: 0 });
      },
      testPush: (userId): Promise<PushResult> => {
        tested.push(userId);
        return Promise.resolve(configured ? { ok: true } : { ok: false, reason: "not_configured" });
      },
    },
  };
  app = new Hono<{ Variables: AppVariables }>();
  registerPushAdminRoutes(app, deps);
});

const post = (path: string, body: unknown, admin = true) =>
  app.request(path, { method: "POST", headers: { "content-type": "application/json", ...(admin ? { authorization: "Bearer admin" } : {}) }, body: JSON.stringify(body) });

describe("POST /api/admin/push/event-available", () => {
  test("tells the members of the list about the published event, with its own title", async () => {
    const res = await post("/api/admin/push/event-available", { event_id: 12, user_ids: [3, 4] });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, requested: 2, sent: 2, skipped: 0, failed: 0 });
    expect(told).toEqual([{ eventId: 12, title: "Shabbat à Paris", recipientIds: [3, 4] }]);
  });

  test("an unknown or unpublished event is 404, and nobody is told", async () => {
    const res = await post("/api/admin/push/event-available", { event_id: 99, user_ids: [3] });
    expect(res.status).toBe(404);
    expect(told).toEqual([]);
  });

  test("an empty, too long or malformed list is 400", async () => {
    for (const user_ids of [[], Array.from({ length: 5001 }, (_, i) => i + 1), ["3"], [0]]) {
      expect((await post("/api/admin/push/event-available", { event_id: 12, user_ids })).status).toBe(400);
    }
    expect(told).toEqual([]);
  });

  test("without pushes configured it says so (503) instead of pretending", async () => {
    configured = false;
    const res = await post("/api/admin/push/event-available", { event_id: 12, user_ids: [3] });
    expect(res.status).toBe(503);
    expect(told).toEqual([]);
  });

  test("a member is refused", async () => {
    expect((await post("/api/admin/push/event-available", { event_id: 12, user_ids: [3] }, false)).status).toBe(401);
    expect(told).toEqual([]);
  });
});

describe("POST /api/admin/push/test", () => {
  test("sends a test push to the member and answers what the provider said", async () => {
    const res = await post("/api/admin/push/test", { user_id: 44 });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, sent: true });
    expect(tested).toEqual([44]);
  });

  test("a push that did not leave is 502 with the reason", async () => {
    configured = false;
    const res = await post("/api/admin/push/test", { user_id: 44 });
    expect(res.status).toBe(502);
    expect(await res.json()).toEqual({ success: false, sent: false, error: "not_configured" });
  });

  test("a member is refused", async () => {
    expect((await post("/api/admin/push/test", { user_id: 44 }, false)).status).toBe(401);
    expect(tested).toEqual([]);
  });
});

describe("GET /api/admin/push/status", () => {
  test("says whether pushes can leave, never the key", async () => {
    const res = await app.request("/api/admin/push/status", { headers: { authorization: "Bearer admin" } });
    expect(await res.json()).toEqual({ success: true, configured: true });
    expect((await app.request("/api/admin/push/status")).status).toBe(401);
  });
});
