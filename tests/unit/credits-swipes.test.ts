import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { CreditsService } from "../../src/features/credits/application/credits-service";
import type { CreditsView } from "../../src/features/credits/domain/view";
import { registerSwipeRoute, type SwipeResult, type SwipeStore } from "../../src/features/matching/swipe.routes";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import type { AppVariables } from "../../src/shared/http/middleware";
import { FakePlusStatus, InMemoryCredits } from "./support/credits-fakes";
import { FakeJwsVerifier } from "./support/subscriptions-fakes";

// POST /api/swipes with action super_like: the debit comes before the swipe is
// recorded, is undone when recording fails, and is never taken twice for the
// same target (docs/premium/CREDITS.md).

const USER = 1;

interface SwipeBody {
  success: boolean;
  match?: boolean;
  targetUserId?: number;
  error?: string;
  credits: CreditsView;
}

class FakeSwipes implements SwipeStore {
  readonly stored = new Map<string, string>();
  readonly matches: Array<readonly [number, number]> = [];
  recorded = 0;
  failRecord = false;
  reciprocal = false;

  async currentAction(userId: number, targetUserId: number): Promise<string | null> {
    return this.stored.get(`${userId}:${targetUserId}`) ?? null;
  }

  unreachable = new Set<number>();

  async canSwipeOn(_userId: number, targetUserId: number): Promise<boolean> {
    return !this.unreachable.has(targetUserId);
  }

  async record(userId: number, targetUserId: number, action: string): Promise<SwipeResult> {
    if (this.failRecord) throw new Error("database unavailable");
    this.recorded += 1;
    this.stored.set(`${userId}:${targetUserId}`, action);
    return this.reciprocal && action !== "pass" ? { match: true, targetUserId } : { match: false };
  }

  async onMatch(userId: number, targetUserId: number): Promise<void> {
    this.matches.push([userId, targetUserId]);
  }
}

let repository: InMemoryCredits;
let plus: FakePlusStatus;
let swipes: FakeSwipes;
let app: Hono<{ Variables: AppVariables }>;

beforeEach(() => {
  repository = new InMemoryCredits();
  plus = new FakePlusStatus();
  swipes = new FakeSwipes();
  const transactions = new TransactionVerifier(new FakeJwsVerifier(), { bundleId: "com.mazl.app", productIds: [] });
  const credits = new CreditsService({ repository, plus, transactions });
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const id = Number(c.req.header("x-test-user"));
    if (!Number.isInteger(id)) return c.json({ success: false, error: "Invalid token" }, 401);
    c.set("userId", id);
    await next();
  });
  app = new Hono<{ Variables: AppVariables }>();
  registerSwipeRoute(app, { authenticate, credits, swipes });
});

async function swipe(target: number, action: string, user: number | null = USER): Promise<{ status: number; body: SwipeBody }> {
  const res = await app.request("/api/swipes", {
    method: "POST",
    headers: { "content-type": "application/json", ...(user === null ? {} : { "x-test-user": String(user) }) },
    body: JSON.stringify({ target_user_id: target, action }),
  });
  return { status: res.status, body: (await res.json()) as SwipeBody };
}

describe("likes and passes are not credits", () => {
  test("a like or a pass debits nothing and keeps the former response", async () => {
    for (const action of ["like", "pass"]) {
      const { status, body } = await swipe(20, action);
      expect(status).toBe(200);
      expect(body as unknown).toEqual({ success: true, match: false });
    }
    expect(repository.spends).toHaveLength(0);
  });

  test("requires authentication", async () => {
    expect((await swipe(20, "super_like", null)).status).toBe(401);
  });

  test("400 on a bad body, nothing debited", async () => {
    const res = await app.request("/api/swipes", {
      method: "POST",
      headers: { "content-type": "application/json", "x-test-user": "1" },
      body: JSON.stringify({ target_user_id: 20, action: "mega_like" }),
    });
    expect(res.status).toBe(400);
    expect(repository.spends).toHaveLength(0);
  });
});

describe("a target that cannot be swiped on", () => {
  test("is a 404 whatever the action, and a super like is neither debited nor recorded", async () => {
    swipes.unreachable.add(30);
    for (const action of ["like", "pass", "super_like"]) {
      expect((await swipe(30, action)).status).toBe(404);
    }
    expect(repository.spends).toHaveLength(0);
    expect(swipes.recorded).toBe(0);
    expect(swipes.matches).toEqual([]);
  });

  test("yourself is a 400 before anything else", async () => {
    expect((await swipe(USER, "super_like")).status).toBe(400);
    expect(repository.spends).toHaveLength(0);
  });
});

describe("super like", () => {
  test("a free member has one a day: debited, recorded, and the response carries credits", async () => {
    const { status, body } = await swipe(20, "super_like");
    expect(status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.match).toBe(false);
    expect(body.credits.super_like).toEqual({ daily_allowance: 1, daily_remaining: 0, purchased_balance: 0, available: 0 });
    expect(swipes.stored.get("1:20")).toBe("super_like");
    expect(repository.spends).toHaveLength(1);
  });

  test("the second one for another target is refused with 402 super_likes_exhausted and the balance", async () => {
    await swipe(20, "super_like");
    const { status, body } = await swipe(21, "super_like");
    expect(status).toBe(402);
    expect(body.success).toBe(false);
    expect(body.error).toBe("super_likes_exhausted");
    expect(body.credits.super_like.available).toBe(0);
    expect(swipes.stored.has("1:21")).toBe(false);
    expect(swipes.recorded).toBe(1);
  });

  test("falls back on purchased credits once the allowance is spent", async () => {
    repository.setBalance(USER, "super_like", 2);
    await swipe(20, "super_like");
    const { status, body } = await swipe(21, "super_like");
    expect(status).toBe(200);
    expect(body.credits.super_like).toMatchObject({ daily_remaining: 0, purchased_balance: 1, available: 1 });
    expect(repository.spends.map((s) => s.source)).toEqual(["daily", "purchased"]);
  });

  test("a mazl+ member sends five a day, the sixth is refused", async () => {
    plus.plus.add(USER);
    for (let target = 20; target < 25; target++) expect((await swipe(target, "super_like")).status).toBe(200);
    expect((await swipe(30, "super_like")).status).toBe(402);
  });

  test("replaying a super like to the same person debits nothing", async () => {
    const first = await swipe(20, "super_like");
    const again = await swipe(20, "super_like");
    expect(again.status).toBe(200);
    expect(repository.spends).toHaveLength(1);
    expect(again.body.credits).toEqual(first.body.credits);
  });

  test("two simultaneous super likes to the same new person cost one credit", async () => {
    repository.setBalance(USER, "super_like", 5);
    const [first, second] = await Promise.all([swipe(20, "super_like"), swipe(20, "super_like")]);
    expect([first.status, second.status]).toEqual([200, 200]);
    expect(repository.spends).toHaveLength(1);
    expect(repository.balance(USER, "super_like")).toBe(5);
  });

  test("a replay still succeeds when nothing is left to spend", async () => {
    await swipe(20, "super_like");
    expect((await swipe(20, "super_like")).status).toBe(200);
  });

  test("upgrading an earlier like to a super like is a new debit", async () => {
    await swipe(20, "like");
    const { status } = await swipe(20, "super_like");
    expect(status).toBe(200);
    expect(repository.spends).toHaveLength(1);
  });

  test("the debit is undone when the swipe cannot be recorded", async () => {
    swipes.failRecord = true;
    const failed = await swipe(20, "super_like");
    expect(failed.status).toBe(500);
    expect(repository.spends).toHaveLength(0);

    swipes.failRecord = false;
    const retried = await swipe(20, "super_like");
    expect(retried.status).toBe(200);
    expect(retried.body.credits.super_like.daily_remaining).toBe(0);
  });

  test("an undone purchased debit gives the purchased credit back", async () => {
    repository.setBalance(USER, "super_like", 1);
    await swipe(20, "super_like");
    swipes.failRecord = true;
    expect((await swipe(21, "super_like")).status).toBe(500);
    expect(repository.balance(USER, "super_like")).toBe(1);
  });

  test("a mutual super like still announces the match", async () => {
    swipes.reciprocal = true;
    const { body } = await swipe(20, "super_like");
    expect(body).toMatchObject({ success: true, match: true, targetUserId: 20 });
    expect(swipes.matches).toEqual([[USER, 20]]);
  });
});
