import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createAttemptGuard, createIpRateLimiter } from "../../src/shared/http/rate-limit";

// Public routes (sign-in, admin sign-in, waitlist) have no user id yet: they
// are limited per client address. Password checks lock an address out after a
// few FAILED attempts, and then refuse even the right password until the
// window has passed, so that guessing cannot go on in the background.

const forwardedFor = (address: string) => ({ "x-forwarded-for": address });

describe("per-address limiter", () => {
  function buildApp(max: number, clock: { now: number }) {
    const app = new Hono();
    app.post("/x", createIpRateLimiter({ max, windowMs: 60_000, now: () => clock.now }), (c) => c.json({ ok: true }));
    return app;
  }

  test("allows max requests per address, then 429 with Retry-After and the contract body", async () => {
    const clock = { now: 0 };
    const app = buildApp(2, clock);
    const call = () => app.request("/x", { method: "POST", headers: forwardedFor("203.0.113.1") });
    expect((await call()).status).toBe(200);
    expect((await call()).status).toBe(200);
    const blocked = await call();
    expect(blocked.status).toBe(429);
    expect(blocked.headers.get("Retry-After")).toBe("60");
    expect(await blocked.json()).toEqual({ success: false, error: "rate_limited", retry_after: 60 });
  });

  test("addresses are counted apart, and a forged X-Forwarded-For prefix does not open a new bucket", async () => {
    const clock = { now: 0 };
    const app = buildApp(1, clock);
    const call = (xff: string) => app.request("/x", { method: "POST", headers: { "x-forwarded-for": xff } });
    expect((await call("203.0.113.1")).status).toBe(200);
    expect((await call("203.0.113.2")).status).toBe(200);
    expect((await call("9.9.9.9, 203.0.113.1")).status).toBe(429);
  });

  test("the window slides", async () => {
    const clock = { now: 0 };
    const app = buildApp(1, clock);
    const call = () => app.request("/x", { method: "POST", headers: forwardedFor("203.0.113.1") });
    await call();
    clock.now = 59_999;
    expect((await call()).status).toBe(429);
    clock.now = 60_001;
    expect((await call()).status).toBe(200);
  });
});

describe("failed-attempt guard", () => {
  test("locks a key after max failures, success does not count, the lock ends with the window", () => {
    const clock = { now: 0 };
    const guard = createAttemptGuard({ maxFailures: 3, windowMs: 900_000, now: () => clock.now });
    expect(guard.lockedFor("a")).toBeNull();
    guard.recordFailure("a");
    guard.recordFailure("a");
    expect(guard.lockedFor("a")).toBeNull();
    guard.recordFailure("a");
    expect(guard.lockedFor("a")).toBe(900);
    expect(guard.lockedFor("b")).toBeNull();
    clock.now = 600_000;
    expect(guard.lockedFor("a")).toBe(300);
    clock.now = 900_001;
    expect(guard.lockedFor("a")).toBeNull();
  });

  test("forgetting a key (successful sign-in) clears its failures", () => {
    const guard = createAttemptGuard({ maxFailures: 2, windowMs: 1000, now: () => 0 });
    guard.recordFailure("a");
    guard.forget("a");
    guard.recordFailure("a");
    expect(guard.lockedFor("a")).toBeNull();
  });
});
