import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import type { ClientContext } from "../../src/features/analytics/domain/events";
import type { AnalyticsEvent } from "../../src/features/analytics/domain/events";
import { registerAnalyticsRoutes } from "../../src/features/analytics/presentation/analytics.routes";
import { withMessageAnalytics } from "../../src/features/analytics/presentation/message-analytics";
import { observeServerEvents } from "../../src/features/analytics/presentation/server-events";
import type { AppVariables } from "../../src/shared/http/middleware";

const NOW = new Date("2026-10-26T12:00:00Z");
const USER = 7;

class FakeAnalytics {
  readonly client: Array<{ userId: number; context: ClientContext; events: readonly unknown[] }> = [];
  readonly server: Array<{ userId: number; event: AnalyticsEvent | null }> = [];

  recordClientEvents(userId: number, context: ClientContext, events: readonly unknown[]): Promise<number> {
    this.client.push({ userId, context, events });
    return Promise.resolve(events.length);
  }

  recordServerEvent(userId: number, event: AnalyticsEvent | null): void {
    this.server.push({ userId, event });
  }
}

const signedIn = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
  if (c.req.header("Authorization") !== "Bearer ok") return c.json({ success: false }, 401);
  c.set("userId", USER);
  await next();
});

const passThrough = createMiddleware<{ Variables: AppVariables }>(async (_c, next) => {
  await next();
});

function relayApp(analytics: FakeAnalytics): Hono<{ Variables: AppVariables }> {
  const app = new Hono<{ Variables: AppVariables }>();
  registerAnalyticsRoutes(app, { authenticate: signedIn, limiter: passThrough, analytics });
  return app;
}

const post = (app: Hono<{ Variables: AppVariables }>, body: unknown, token = "ok"): Promise<Response> => {
  const text = typeof body === "string" ? body : JSON.stringify(body);
  return Promise.resolve(
    app.request("/api/analytics/events", {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", "Content-Length": String(text.length) },
      body: text,
    }),
  );
};

describe("POST /api/analytics/events", () => {
  test("relays the batch for the signed-in member and answers 202 with the accepted count", async () => {
    const analytics = new FakeAnalytics();
    const response = await post(relayApp(analytics), { platform: "ios", app_version: "1.0.0+3", events: [{ name: "app_opened" }] });
    expect(response.status).toBe(202);
    expect(await response.json()).toEqual({ success: true, accepted: 1 });
    expect(analytics.client).toEqual([{ userId: USER, context: { platform: "ios", appVersion: "1.0.0+3" }, events: [{ name: "app_opened" }] }]);
  });

  test("needs a session", async () => {
    const analytics = new FakeAnalytics();
    expect((await post(relayApp(analytics), { platform: "ios", app_version: "1.0.0", events: [] }, "nope")).status).toBe(401);
    expect(analytics.client).toEqual([]);
  });

  test("refuses a malformed envelope, an unknown platform and more than 50 events", async () => {
    const analytics = new FakeAnalytics();
    const app = relayApp(analytics);
    expect((await post(app, "not json")).status).toBe(400);
    expect((await post(app, { platform: "tv", app_version: "1.0.0", events: [] })).status).toBe(400);
    expect((await post(app, { platform: "ios", app_version: "1.0.0", events: "x" })).status).toBe(400);
    const many = Array.from({ length: 51 }, () => ({ name: "app_opened" }));
    expect((await post(app, { platform: "ios", app_version: "1.0.0", events: many })).status).toBe(400);
    expect(analytics.client).toEqual([]);
  });

  test("refuses a body over 64 KB", async () => {
    const analytics = new FakeAnalytics();
    const padding = "x".repeat(70 * 1024);
    const response = await post(relayApp(analytics), { platform: "ios", app_version: "1.0.0", events: [{ name: "app_opened", padding }] });
    expect(response.status).toBe(413);
    expect(analytics.client).toEqual([]);
  });
});

// The routes observed are fakes answering like the real ones (pinned by their own tests).
function observedApp(analytics: FakeAnalytics, answer: (path: string) => { status: number; body: unknown }): Hono<{ Variables: AppVariables }> {
  const app = new Hono<{ Variables: AppVariables }>();
  app.use("/api/*", observeServerEvents(analytics, () => NOW));
  app.post("/api/*", signedIn, async (c) => {
    await c.req.json().catch(() => undefined);
    const { status, body } = answer(c.req.path);
    return c.json(body as Record<string, unknown>, status as 200);
  });
  return app;
}

const call = (app: Hono<{ Variables: AppVariables }>, path: string, body: unknown = {}): Promise<Response> =>
  Promise.resolve(
    app.request(path, { method: "POST", headers: { Authorization: "Bearer ok", "Content-Type": "application/json" }, body: JSON.stringify(body) }),
  );

const names = (analytics: FakeAnalytics) => analytics.server.map(({ userId, event }) => [userId, event?.name, event?.properties]);

describe("server events observed on the routes", () => {
  test("a swipe without match: one swipe event with its action", async () => {
    const analytics = new FakeAnalytics();
    await call(observedApp(analytics, () => ({ status: 200, body: { success: true, match: false } })), "/api/swipes", {
      target_user_id: 9,
      action: "pass",
    });
    expect(names(analytics)).toEqual([[USER, "swipe", { action: "pass" }]]);
  });

  test("a reciprocal like: the swipe, then a match for each member", async () => {
    const analytics = new FakeAnalytics();
    await call(observedApp(analytics, () => ({ status: 200, body: { success: true, match: true, targetUserId: 9 } })), "/api/swipes", {
      target_user_id: 9,
      action: "super_like",
    });
    expect(names(analytics)).toEqual([
      [USER, "swipe", { action: "super_like" }],
      [USER, "match_created", { via: "super_like", role: "initiator" }],
      [9, "match_created", { via: "super_like", role: "receiver" }],
    ]);
  });

  test("a refused swipe (402, 404) records nothing", async () => {
    const analytics = new FakeAnalytics();
    await call(observedApp(analytics, () => ({ status: 402, body: { success: false } })), "/api/swipes", { target_user_id: 9, action: "super_like" });
    expect(analytics.server).toEqual([]);
  });

  test("a validated subscription and a credited consumable", async () => {
    const analytics = new FakeAnalytics();
    const app = observedApp(analytics, (path) =>
      path.includes("subscriptions")
        ? { status: 200, body: { success: true, subscription: { plan_type: "monthly", status: "active", product_id: "com.mazl.app.plus.1m" } } }
        : { status: 200, body: { success: true, credited: true, kind: "boost", quantity: 3 } },
    );
    await call(app, "/api/subscriptions/apple/verify");
    await call(app, "/api/credits/apple/verify");
    expect(names(analytics)).toEqual([
      [USER, "purchase_validated", { kind: "subscription", product_id: "com.mazl.app.plus.1m", plan_type: "monthly" }],
      [USER, "purchase_validated", { kind: "consumable", product: "boost" }],
    ]);
  });

  test("a consumable already credited (replay) is not counted twice", async () => {
    const analytics = new FakeAnalytics();
    await call(observedApp(analytics, () => ({ status: 200, body: { success: true, credited: false, kind: "boost" } })), "/api/credits/apple/verify");
    expect(analytics.server).toEqual([]);
  });

  test("verifications: face and identity, approved or rejected", async () => {
    const analytics = new FakeAnalytics();
    const app = observedApp(analytics, (path) => ({
      status: 200,
      body: path.endsWith("identity") ? { success: true, verified: false, reason: "expired" } : { success: true, verified: true },
    }));
    await call(app, "/api/verification/face/submit");
    await call(app, "/api/verification/identity");
    expect(names(analytics)).toEqual([
      [USER, "verification_submitted", { step: "face", outcome: "approved" }],
      [USER, "verification_submitted", { step: "identity", outcome: "rejected" }],
    ]);
  });

  test("other routes are not observed, and the response reaches the client intact", async () => {
    const analytics = new FakeAnalytics();
    const response = await call(observedApp(analytics, () => ({ status: 200, body: { success: true, match: true } })), "/api/profile");
    expect(await response.json()).toEqual({ success: true, match: true });
    expect(analytics.server).toEqual([]);
  });
});

describe("message analytics", () => {
  test("a stored message counts for its sender only, and the push still goes out", () => {
    const analytics = new FakeAnalytics();
    const pushed: number[] = [];
    const notifier = withMessageAnalytics({ messageCreated: (event) => pushed.push(event.recipientId) }, analytics, () => NOW);
    notifier.messageCreated({ conversationId: 3, senderId: USER, recipientId: 9 });
    expect(pushed).toEqual([9]);
    expect(names(analytics)).toEqual([[USER, "message_sent", {}]]);
  });
});
