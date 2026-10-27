import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { teaserOf } from "../../src/features/likes-visibility/domain/teaser";
import { registerLikesVisibility } from "../../src/features/likes-visibility/likes-visibility.module";
import type { AppVariables } from "../../src/shared/http/middleware";
import { resetKeyCacheForTests } from "../../src/shared/crypto/keys";

// « Voir qui vous a aimé » is a mazl+ benefit (CGV §2.1). Without mazl+, the
// received likes must not carry what identifies the person: a blur drawn by
// the client hides nothing from someone reading the response.

const previousKey = process.env.MEDIA_SIGNING_KEY;
beforeAll(() => {
  process.env.MEDIA_SIGNING_KEY = Buffer.alloc(32, 7).toString("base64");
  resetKeyCacheForTests();
});
afterAll(() => {
  if (previousKey === undefined) delete process.env.MEDIA_SIGNING_KEY;
  else process.env.MEDIA_SIGNING_KEY = previousKey;
  resetKeyCacheForTests();
});

const like = { user_id: 41, display_name: "Jonas", picture: "https://example.com/media/photos/9?exp=1&sig=x", age: 34, is_verified: true, liked_at: "2026-10-24T10:00:00.000Z" };

describe("teaser of a received like", () => {
  test("keeps the first name, the badge, the date and the blurred photo, drops photo, id and age", () => {
    expect(teaserOf(like, () => "https://example.com/blur")).toEqual({
      display_name: "Jonas",
      is_verified: true,
      liked_at: "2026-10-24T10:00:00.000Z",
      is_super_like: false,
      blurredPhotoUrl: "https://example.com/blur",
    });
  });

  test("a Super Like is marked, a missing photo gives no blurred url", () => {
    const teaser = teaserOf({ ...like, is_super_like: true }, () => null);
    expect([teaser.is_super_like, teaser.blurredPhotoUrl]).toEqual([true, null]);
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
    const [teaser] = body.likes;
    expect(Object.keys(teaser ?? {}).sort()).toEqual(["blurredPhotoUrl", "display_name", "is_super_like", "is_verified", "liked_at"]);
    // The photo of the like was /media/photos/9: only its blurred variant is handed out.
    expect(String(teaser?.blurredPhotoUrl)).toMatch(/^\/media\/photos\/9\/blur\?exp=\d+&sig=[\w-]+$/);
    expect(JSON.stringify(body)).not.toContain("example.com");
    expect(JSON.stringify(body)).not.toMatch(/user_id|"picture"|"age"/);
    expect(JSON.stringify(body)).not.toMatch(/\/media\/photos\/9\?/);
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
