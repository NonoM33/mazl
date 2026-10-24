import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import type { PlusStatus } from "../../src/features/credits/application/ports";
import { LikeAllowanceService } from "../../src/features/like-allowance/application/like-allowance-service";
import type { LikeLedger } from "../../src/features/like-allowance/application/ports";
import { createLikeAllowanceGuard } from "../../src/features/like-allowance/presentation/like-allowance.routes";
import type { AppVariables } from "../../src/shared/http/middleware";

class FakeLedger implements LikeLedger {
  likes = new Set<number>();
  countToday = 0;
  likesToday(): Promise<number> { return Promise.resolve(this.countToday); }
  hasLiked(_userId: number, targetUserId: number): Promise<boolean> { return Promise.resolve(this.likes.has(targetUserId)); }
  resetsAt(): Promise<Date> { return Promise.resolve(new Date("2026-10-25T00:00:00.000Z")); }
}

function service(ledger: FakeLedger, isPlus = false): LikeAllowanceService {
  const plus: PlusStatus = { isPlus: () => Promise.resolve(isPlus) };
  return new LikeAllowanceService(ledger, plus);
}

describe("like allowance", () => {
  test("a free member has 10 likes a day and the count goes down", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 4;
    expect(await service(ledger).allowance(1)).toEqual({ daily_allowance: 10, remaining: 6, resets_at: "2026-10-25T00:00:00.000Z" });
  });

  test("the 10th like passes, the 11th is refused", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 9;
    expect((await service(ledger).checkLike(1, 50)).allowed).toBe(true);
    ledger.countToday = 10;
    const verdict = await service(ledger).checkLike(1, 51);
    expect(verdict.allowed).toBe(false);
    if (!verdict.allowed) expect(verdict.allowance.remaining).toBe(0);
  });

  test("liking again someone already liked is free, even at the cap", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 10;
    ledger.likes.add(50);
    expect((await service(ledger).checkLike(1, 50)).allowed).toBe(true);
  });

  test("mazl+ is unlimited: null allowance, never refused", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 500;
    const plus = service(ledger, true);
    expect(await plus.allowance(1)).toEqual({ daily_allowance: null, remaining: null, resets_at: "2026-10-25T00:00:00.000Z" });
    expect((await plus.checkLike(1, 60)).allowed).toBe(true);
  });

  test("the next day starts from zero again", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 10;
    expect((await service(ledger).checkLike(1, 70)).allowed).toBe(false);
    ledger.countToday = 0;
    expect((await service(ledger).checkLike(1, 70)).allowed).toBe(true);
  });
});

describe("like allowance guard on a Hono app", () => {
  function appWith(ledger: FakeLedger): Hono<{ Variables: AppVariables }> {
    const app = new Hono<{ Variables: AppVariables }>();
    const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
      c.set("userId", 1);
      await next();
    });
    app.post("/api/swipes", authenticate, createLikeAllowanceGuard({ authenticate, allowance: service(ledger) }));
    // Stands for the matching handler: it reads the body again.
    app.post("/api/swipes", async (c) => {
      const body = (await c.req.json()) as { action: string; target_user_id: number };
      return c.json({ success: true, seen: body });
    });
    return app;
  }

  const post = (app: Hono<{ Variables: AppVariables }>, body: string) =>
    app.request("/api/swipes", { method: "POST", headers: { "Content-Type": "application/json" }, body });

  test("answers 402 likes_exhausted with the allowance", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 10;
    const response = await post(appWith(ledger), JSON.stringify({ target_user_id: 9, action: "like" }));
    expect(response.status).toBe(402);
    expect(await response.json()).toEqual({
      success: false,
      error: "likes_exhausted",
      allowance: { daily_allowance: 10, remaining: 0, resets_at: "2026-10-25T00:00:00.000Z" },
    });
  });

  test("lets a pass through at the cap, and the next handler still reads the body", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 10;
    const response = await post(appWith(ledger), JSON.stringify({ target_user_id: 9, action: "pass" }));
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ success: true, seen: { target_user_id: 9, action: "pass" } });
  });

  test("lets a like through under the cap and the next handler reads the same body", async () => {
    const response = await post(appWith(new FakeLedger()), JSON.stringify({ target_user_id: 9, action: "like" }));
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ success: true, seen: { target_user_id: 9, action: "like" } });
  });

  test("a target id beyond the database range never reaches the ledger", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 10;
    const response = await post(appWith(ledger), JSON.stringify({ target_user_id: 2_147_483_648, action: "like" }));
    expect(response.status).toBe(200);
  });

  test("an unreadable body is left to the existing handler", async () => {
    const ledger = new FakeLedger();
    ledger.countToday = 10;
    const response = await post(appWith(ledger), "{not json");
    expect(response.status).not.toBe(402);
  });
});
