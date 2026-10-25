import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { teaserOf } from "../../src/features/likes-visibility/domain/teaser";
import { registerLikesVisibility } from "../../src/features/likes-visibility/likes-visibility.module";
import type { AppVariables } from "../../src/shared/http/middleware";

// « Voir qui vous a aimé » is a mazl+ benefit (CGV §2.1). Without mazl+, the
// received likes must not carry what identifies the person: a blur drawn by
// the client hides nothing from someone reading the response.

const like = { user_id: 41, display_name: "Jonas", picture: "https://example.com/media/photos/9?exp=1&sig=x", age: 34, is_verified: true, liked_at: "2026-10-24T10:00:00.000Z" };

describe("teaser of a received like", () => {
  test("keeps the first name, the badge and the date, drops photo, id and age", () => {
    expect(teaserOf(like)).toEqual({ display_name: "Jonas", is_verified: true, liked_at: "2026-10-24T10:00:00.000Z" });
  });
});

function appWith(plus: boolean) {
  const app = new Hono<{ Variables: AppVariables }>();
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => { c.set("userId", 7); await next(); });
  registerLikesVisibility(app, { authenticate, plusStatus: { isPlus: () => Promise.resolve(plus) } });
  app.get("/api/likes/received", (c) => c.json({ success: true, count: 1, likes: [like] }));
  app.get("/api/likes/received/count", (c) => c.json({ success: true, count: 1 }));
  return app;
}

describe("GET /api/likes/received", () => {
  test("without mazl+, the response has no photo, id nor age, and keeps the count", async () => {
    const body = (await (await appWith(false).request("/api/likes/received")).json()) as { count: number; likes: Record<string, unknown>[] };
    expect(body.count).toBe(1);
    expect(body.likes[0]).toEqual({ display_name: "Jonas", is_verified: true, liked_at: like.liked_at });
    expect(JSON.stringify(body)).not.toContain("example.com");
  });

  test("with mazl+, the response is untouched", async () => {
    const body = (await (await appWith(true).request("/api/likes/received")).json()) as { likes: unknown[] };
    expect(body.likes[0]).toEqual(like);
  });

  test("is_premium sits at the root of the answer, whatever the likes", async () => {
    const free = (await (await appWith(false).request("/api/likes/received")).json()) as Record<string, unknown>;
    const plus = (await (await appWith(true).request("/api/likes/received")).json()) as Record<string, unknown>;
    expect([free.is_premium, plus.is_premium]).toEqual([false, true]);
    expect(Object.keys(free).sort()).toEqual(["count", "is_premium", "likes", "success"]);
  });

  test("the count route and errors are left alone", async () => {
    expect(await (await appWith(false).request("/api/likes/received/count")).json()).toEqual({ success: true, count: 1 });
    const failing = new Hono<{ Variables: AppVariables }>();
    registerLikesVisibility(failing, { authenticate: createMiddleware(async (c, next) => { c.set("userId", 7); await next(); }), plusStatus: { isPlus: () => Promise.resolve(false) } });
    failing.get("/api/likes/received", (c) => c.json({ success: false, error: "Failed" }, 500));
    const res = await failing.request("/api/likes/received");
    expect(res.status).toBe(500);
    expect(await res.json()).toEqual({ success: false, error: "Failed" });
  });
});
