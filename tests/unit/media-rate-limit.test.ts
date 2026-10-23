import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createRateLimiter } from "../../src/shared/http/rate-limit";
import type { AppVariables } from "../../src/shared/http/middleware";

// CONTRAT.md §2.3: per-user sliding window; over the limit the answer is 429
// { success: false, error: "rate_limited", retry_after: <seconds> }.

function buildApp(max: number, windowMs: number, clock: { now: number }) {
  const app = new Hono<{ Variables: AppVariables }>();
  const limiter = createRateLimiter({ max, windowMs, now: () => clock.now });
  app.get("/x", async (c, next) => {
    c.set("userId", Number(c.req.header("x-user")));
    await next();
  }, limiter, (c) => c.json({ ok: true }));
  return app;
}

const call = (app: Hono<{ Variables: AppVariables }>, user: number) =>
  app.request("/x", { headers: { "x-user": String(user) } });

describe("rate limiter (contract 2.3)", () => {
  test("allows exactly max requests then answers 429 with the contract body", async () => {
    const clock = { now: 1_000_000 };
    const app = buildApp(3, 3_600_000, clock);
    for (let i = 0; i < 3; i++) expect((await call(app, 1)).status).toBe(200);
    const res = await call(app, 1);
    expect(res.status).toBe(429);
    const body = (await res.json()) as { success: boolean; error: string; retry_after: number };
    expect(body.success).toBe(false);
    expect(body.error).toBe("rate_limited");
    expect(body.retry_after).toBe(3600);
    expect(res.headers.get("Retry-After")).toBe("3600");
  });

  test("users are counted separately", async () => {
    const clock = { now: 0 };
    const app = buildApp(1, 1000, clock);
    expect((await call(app, 1)).status).toBe(200);
    expect((await call(app, 2)).status).toBe(200);
    expect((await call(app, 1)).status).toBe(429);
  });

  test("the window slides: retry_after counts down and old hits expire", async () => {
    const clock = { now: 10_000 };
    const app = buildApp(2, 60_000, clock);
    await call(app, 1); // t = 10 s
    clock.now = 40_000;
    await call(app, 1); // t = 40 s
    clock.now = 50_000;
    const blocked = await call(app, 1);
    expect(blocked.status).toBe(429);
    expect(((await blocked.json()) as { retry_after: number }).retry_after).toBe(20); // first hit leaves at 70 s
    clock.now = 70_001;
    expect((await call(app, 1)).status).toBe(200); // first hit expired, second still counted
    expect((await call(app, 1)).status).toBe(429);
  });

  test("blocked requests do not extend the penalty", async () => {
    const clock = { now: 0 };
    const app = buildApp(1, 10_000, clock);
    await call(app, 1);
    for (let i = 0; i < 20; i++) {
      clock.now += 100;
      expect((await call(app, 1)).status).toBe(429);
    }
    clock.now = 10_001;
    expect((await call(app, 1)).status).toBe(200);
  });
});
