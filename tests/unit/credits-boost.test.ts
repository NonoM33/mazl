import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { CreditsService } from "../../src/features/credits/application/credits-service";
import type { CreditsView } from "../../src/features/credits/domain/view";
import { registerBoostRoutes, type BoostRecord, type BoostStore } from "../../src/features/engagement/boost.routes";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import type { AppVariables } from "../../src/shared/http/middleware";
import { FakePlusStatus, InMemoryCredits } from "./support/credits-fakes";
import { FakeJwsVerifier } from "./support/subscriptions-fakes";

// Boost activation and status against the credits (docs/premium/CREDITS.md):
// the debit comes before the insertion, an active boost blocks everything, and
// a failed insertion gives the credit back.

const USER = 1;
const MINUTE = 60 * 1000;

interface StatusBody {
  success: boolean;
  error?: string;
  is_active?: boolean;
  expires_at?: string | null;
  active_until?: string | null;
  remaining_boosts?: number;
  boosts_used_today?: number;
  views_during_boost?: number;
  likes_during_boost?: number;
  boost?: BoostRecord;
  status?: Record<string, unknown>;
  credits: CreditsView;
}

type MutableBoost = { -readonly [K in keyof BoostRecord]: BoostRecord[K] };

class FakeBoosts implements BoostStore {
  readonly rows: MutableBoost[] = [];
  failActivate = false;
  private nextId = 1;

  async getActive(userId: number): Promise<BoostRecord | null> {
    return this.rows.find((r) => r.user_id === userId && r.expires_at.getTime() > Date.now()) ?? null;
  }

  async usedToday(userId: number): Promise<number> {
    return this.rows.filter((r) => r.user_id === userId).length;
  }

  async activate(userId: number, minutes: number): Promise<BoostRecord> {
    if (this.failActivate) throw new Error("database unavailable");
    const now = new Date();
    const row = { id: this.nextId++, user_id: userId, activated_at: now, expires_at: new Date(now.getTime() + minutes * MINUTE), created_at: now };
    this.rows.push(row);
    return row;
  }

  expireAll(): void {
    for (const row of this.rows) row.expires_at = new Date(Date.now() - 1000);
  }
}

let repository: InMemoryCredits;
let plus: FakePlusStatus;
let boosts: FakeBoosts;
let app: Hono<{ Variables: AppVariables }>;

beforeEach(() => {
  repository = new InMemoryCredits();
  plus = new FakePlusStatus();
  boosts = new FakeBoosts();
  const transactions = new TransactionVerifier(new FakeJwsVerifier(), { bundleId: "com.mazl.app", productIds: [] });
  const credits = new CreditsService({ repository, plus, transactions });
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const id = Number(c.req.header("x-test-user"));
    if (!Number.isInteger(id)) return c.json({ success: false, error: "Invalid token" }, 401);
    c.set("userId", id);
    await next();
  });
  app = new Hono<{ Variables: AppVariables }>();
  registerBoostRoutes(app, { authenticate, credits, boosts });
});

async function call(method: "GET" | "POST", path: string, user: number | null = USER): Promise<{ status: number; body: StatusBody }> {
  const res = await app.request(path, { method, headers: user === null ? {} : { "x-test-user": String(user) } });
  return { status: res.status, body: (await res.json()) as StatusBody };
}
const activate = (user: number | null = USER) => call("POST", "/api/boost/activate", user);
const status = (user: number | null = USER) => call("GET", "/api/boost/status", user);

describe("GET /api/boost/status", () => {
  test("requires authentication", async () => {
    expect((await status(null)).status).toBe(401);
  });

  test("keeps every former key and adds credits; a free member has no included boost", async () => {
    const { status: code, body } = await status();
    expect(code).toBe(200);
    expect(body).toEqual({
      success: true,
      is_active: false,
      expires_at: null,
      active_until: null,
      remaining_boosts: 0,
      boosts_used_today: 0,
      views_during_boost: 0,
      likes_during_boost: 0,
      credits: expect.anything(),
    });
    expect(body.credits.boost.available).toBe(0);
  });

  test("remaining_boosts is credits.boost.available, purchased credits included", async () => {
    plus.plus.add(USER);
    repository.setBalance(USER, "boost", 2);
    const { body } = await status();
    expect(body.remaining_boosts).toBe(3);
    expect(body.credits.boost.available).toBe(3);
  });
});

describe("POST /api/boost/activate", () => {
  test("requires authentication", async () => {
    expect((await activate(null)).status).toBe(401);
  });

  test("402 boosts_exhausted for a free member without purchased boost, nothing inserted", async () => {
    const { status: code, body } = await activate();
    expect(code).toBe(402);
    expect(body.success).toBe(false);
    expect(body.error).toBe("boosts_exhausted");
    expect(body.credits.boost.available).toBe(0);
    expect(boosts.rows).toHaveLength(0);
  });

  test("a mazl+ member boosts once a day: 201 with the boost, the status and credits", async () => {
    plus.plus.add(USER);
    const { status: code, body } = await activate();
    expect(code).toBe(201);
    expect(body.success).toBe(true);
    expect(body.boost?.user_id).toBe(USER);
    expect(body.is_active).toBe(true);
    expect(body.status?.is_active).toBe(true);
    expect(body.remaining_boosts).toBe(0);
    expect(body.credits.boost).toMatchObject({ daily_remaining: 0, available: 0 });
    expect(boosts.rows).toHaveLength(1);
  });

  test("a free member who bought boosts can use them", async () => {
    repository.setBalance(USER, "boost", 3);
    const { status: code, body } = await activate();
    expect(code).toBe(201);
    expect(body.credits.boost).toMatchObject({ purchased_balance: 2, available: 2 });
    expect(repository.spends[0]?.source).toBe("purchased");
  });

  test("409 boost_already_active when one is running, and nothing is debited", async () => {
    repository.setBalance(USER, "boost", 3);
    await activate();
    const { status: code, body } = await activate();
    expect(code).toBe(409);
    expect(body.error).toBe("boost_already_active");
    expect(repository.balance(USER, "boost")).toBe(2);
    expect(repository.spends).toHaveLength(1);
    expect(boosts.rows).toHaveLength(1);
  });

  test("409 comes before 402: an active boost is reported even with nothing left", async () => {
    plus.plus.add(USER);
    await activate();
    expect((await activate()).status).toBe(409);
  });

  test("once the boost has ended, the next one is a new debit", async () => {
    repository.setBalance(USER, "boost", 2);
    await activate();
    boosts.expireAll();
    repository.age(31);
    expect((await activate()).status).toBe(201);
    expect(repository.balance(USER, "boost")).toBe(0);
  });

  test("two simultaneous activations make one boost and one debit, the other is 409", async () => {
    repository.setBalance(USER, "boost", 3);
    const codes = (await Promise.all([activate(), activate()])).map((r) => r.status).sort();
    expect(codes).toEqual([201, 409]);
    expect(repository.spends).toHaveLength(1);
    expect(repository.balance(USER, "boost")).toBe(2);
    expect(boosts.rows).toHaveLength(1);
  });

  test("the debit is undone when the boost cannot be inserted", async () => {
    repository.setBalance(USER, "boost", 1);
    boosts.failActivate = true;
    const failed = await activate();
    expect(failed.status).toBe(500);
    expect(repository.balance(USER, "boost")).toBe(1);
    expect(repository.spends).toHaveLength(0);

    boosts.failActivate = false;
    expect((await activate()).status).toBe(201);
  });

  test("an undone daily debit gives the daily boost back", async () => {
    plus.plus.add(USER);
    boosts.failActivate = true;
    expect((await activate()).status).toBe(500);
    boosts.failActivate = false;
    expect((await activate()).status).toBe(201);
  });
});
