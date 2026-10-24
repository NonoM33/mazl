import { describe, expect, test } from "bun:test";
import type { Sql } from "postgres";
import type { NewPurchase } from "../../src/features/credits/application/ports";
import { PgCreditsRepository } from "../../src/features/credits/infra/pg-credits-repository";
import { PgPlusStatus } from "../../src/features/credits/infra/pg-plus-status";

// No database here: a recording stand-in for the postgres.js tag (and its
// begin()) checks the shape of the SQL: the row lock, the idempotent insert,
// and that every value is bound as a parameter, never concatenated.

interface Call {
  readonly text: string;
  readonly values: readonly unknown[];
  readonly inTransaction: boolean;
}

function fakeSql(behaviour: (call: Call) => unknown[] | Error): { sql: Sql; calls: Call[] } {
  const calls: Call[] = [];
  let depth = 0;
  const tag = async (strings: TemplateStringsArray, ...values: unknown[]): Promise<unknown[]> => {
    const call = { text: strings.join("?"), values, inTransaction: depth > 0 };
    calls.push(call);
    const result = behaviour(call);
    if (result instanceof Error) throw result;
    return result;
  };
  const begin = async (callback: (transaction: typeof tag) => Promise<unknown>): Promise<unknown> => {
    depth += 1;
    try {
      return await callback(tag);
    } finally {
      depth -= 1;
    }
  };
  return { sql: Object.assign(tag, { begin }) as unknown as Sql, calls };
}

const has = (call: Call, fragment: string): boolean => call.text.replace(/\s+/g, " ").includes(fragment);
const find = (calls: Call[], fragment: string): Call | undefined => calls.find((call) => has(call, fragment));
const index = (calls: Call[], fragment: string): number => calls.findIndex((call) => has(call, fragment));

const PURCHASE: NewPurchase = {
  transactionId: "7000000000001'; DROP TABLE users; --",
  productId: "com.mazl.app.boost.3",
  kind: "boost",
  quantity: 3,
  environment: "Sandbox",
  purchasedAt: new Date("2026-10-24T10:00:00Z"),
};

describe("spend", () => {
  function spendBehaviour(balance: number, used: number): (call: Call) => unknown[] {
    return (call) => {
      if (has(call, "FROM credit_balances")) return [{ balance }];
      if (has(call, "COUNT(*)")) return [{ used }];
      if (has(call, "INSERT INTO credit_spends")) return [{ id: 42 }];
      return [];
    };
  }

  test("locks the balance row in a transaction before writing the debit", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(0, 0));
    const outcome = await new PgCreditsRepository(sql).spend({ userId: 7, kind: "super_like", allowance: 1, targetUserId: 50 });
    expect(outcome).toEqual({ ok: true, spendId: 42, source: "daily" });
    expect(calls.every((call) => call.inTransaction)).toBe(true);
    const lock = index(calls, "FOR UPDATE");
    expect(lock).toBeGreaterThanOrEqual(0);
    expect(has(calls[lock] as Call, "SELECT balance FROM credit_balances")).toBe(true);
    expect(lock).toBeLessThan(index(calls, "INSERT INTO credit_spends"));
    expect(lock).toBeLessThan(index(calls, "COUNT(*)"));
  });

  test("a daily debit does not touch the purchased balance", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(5, 0));
    await new PgCreditsRepository(sql).spend({ userId: 7, kind: "super_like", allowance: 1, targetUserId: undefined });
    expect(find(calls, "UPDATE credit_balances")).toBeUndefined();
    expect(find(calls, "INSERT INTO credit_spends")?.values).toEqual([7, "super_like", "daily", null]);
  });

  test("a purchased debit takes one credit off the balance, in the same transaction", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(2, 1));
    const outcome = await new PgCreditsRepository(sql).spend({ userId: 7, kind: "boost", allowance: 1, targetUserId: undefined });
    expect(outcome).toEqual({ ok: true, spendId: 42, source: "purchased" });
    const update = find(calls, "UPDATE credit_balances");
    expect(update).toBeDefined();
    expect(has(update as Call, "balance = balance - 1")).toBe(true);
    expect(update?.inTransaction).toBe(true);
    expect(update?.values).toEqual([7, "boost"]);
  });

  test("writes nothing when nothing is left", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(0, 1));
    const outcome = await new PgCreditsRepository(sql).spend({ userId: 7, kind: "boost", allowance: 1, targetUserId: undefined });
    expect(outcome).toEqual({ ok: false, reason: "exhausted" });
    expect(find(calls, "INSERT INTO credit_spends")).toBeUndefined();
    expect(find(calls, "UPDATE credit_balances")).toBeUndefined();
  });

  test("a negative balance is not spendable", async () => {
    const { sql } = fakeSql(spendBehaviour(-1, 1));
    expect(await new PgCreditsRepository(sql).spend({ userId: 7, kind: "boost", allowance: 1, targetUserId: undefined })).toEqual({ ok: false, reason: "exhausted" });
  });

  test("a super like already paid for this person is not paid twice, checked under the lock", async () => {
    const { sql, calls } = fakeSql((call) => {
      if (has(call, "target_user_id = ")) return [{ paid: 1 }];
      return spendBehaviour(5, 0)(call);
    });
    const outcome = await new PgCreditsRepository(sql).spend({
      userId: 7, kind: "super_like", allowance: 1, targetUserId: 50, guard: { kind: "once_per_target" },
    });
    expect(outcome).toEqual({ ok: false, reason: "already_spent" });
    const guard = index(calls, "target_user_id = ");
    expect(guard).toBeGreaterThan(index(calls, "FOR UPDATE"));
    expect(calls[guard]?.values).toEqual([7, "super_like", 50]);
    expect(find(calls, "INSERT INTO credit_spends")).toBeUndefined();
  });

  test("a boost paid within its running time is not paid twice, checked under the lock", async () => {
    const { sql, calls } = fakeSql((call) => {
      if (has(call, "INTERVAL '1 minute'")) return [{ paid: 1 }];
      return spendBehaviour(5, 0)(call);
    });
    const outcome = await new PgCreditsRepository(sql).spend({
      userId: 7, kind: "boost", allowance: 1, targetUserId: undefined, guard: { kind: "once_within", minutes: 30 },
    });
    expect(outcome).toEqual({ ok: false, reason: "already_spent" });
    const guard = index(calls, "INTERVAL '1 minute'");
    expect(guard).toBeGreaterThan(index(calls, "FOR UPDATE"));
    expect(calls[guard]?.values).toEqual([7, "boost", 30]);
    expect(find(calls, "INSERT INTO credit_spends")).toBeUndefined();
  });

  test("without a guard, no earlier debit is looked up", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(0, 0));
    await new PgCreditsRepository(sql).spend({ userId: 7, kind: "super_like", allowance: 1, targetUserId: 50 });
    expect(find(calls, "target_user_id = ")).toBeUndefined();
    expect(find(calls, "INTERVAL '1 minute'")).toBeUndefined();
  });

  test("creates the balance row on first use without failing when it exists", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(0, 0));
    await new PgCreditsRepository(sql).spend({ userId: 7, kind: "boost", allowance: 1, targetUserId: undefined });
    const seed = find(calls, "INSERT INTO credit_balances");
    expect(has(seed as Call, "ON CONFLICT (user_id, kind) DO NOTHING")).toBe(true);
  });

  test("the day is counted on the daily lines of the server calendar day", async () => {
    const { sql, calls } = fakeSql(spendBehaviour(0, 0));
    await new PgCreditsRepository(sql).spend({ userId: 7, kind: "boost", allowance: 1, targetUserId: undefined });
    const count = find(calls, "COUNT(*)") as Call;
    expect(has(count, "source = 'daily'")).toBe(true);
    expect(has(count, "created_at >= DATE_TRUNC('day', NOW())")).toBe(true);
  });
});

describe("cancelSpend", () => {
  test("gives a purchased credit back", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "DELETE FROM credit_spends") ? [{ kind: "boost", source: "purchased" }] : []));
    await new PgCreditsRepository(sql).cancelSpend(7, 42);
    expect(find(calls, "DELETE FROM credit_spends")?.values).toEqual([42, 7]);
    expect(has(find(calls, "UPDATE credit_balances") as Call, "balance = balance + 1")).toBe(true);
  });

  test("a daily debit just disappears from the journal", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "DELETE FROM credit_spends") ? [{ kind: "boost", source: "daily" }] : []));
    await new PgCreditsRepository(sql).cancelSpend(7, 42);
    expect(find(calls, "UPDATE credit_balances")).toBeUndefined();
  });

  test("an unknown debit does nothing", async () => {
    const { sql, calls } = fakeSql(() => []);
    await new PgCreditsRepository(sql).cancelSpend(7, 42);
    expect(calls).toHaveLength(1);
  });
});

describe("recordPurchase", () => {
  test("inserts idempotently on the transactionId, then credits the balance", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "INSERT INTO credit_purchases") ? [{ transaction_id: "x" }] : []));
    expect(await new PgCreditsRepository(sql).recordPurchase(7, PURCHASE)).toBe("credited");
    const insert = find(calls, "INSERT INTO credit_purchases") as Call;
    expect(has(insert, "ON CONFLICT (transaction_id) DO NOTHING")).toBe(true);
    expect(insert.inTransaction).toBe(true);
    const balance = find(calls, "INSERT INTO credit_balances") as Call;
    expect(has(balance, "ON CONFLICT (user_id, kind) DO UPDATE SET balance = credit_balances.balance + EXCLUDED.balance")).toBe(true);
    expect(balance.values).toEqual([7, "boost", 3]);
  });

  test("a transaction Apple refunded before it was credited is refused, and nothing is written", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "FROM credit_revocations") ? [{ revoked_at: new Date() }] : []));
    expect(await new PgCreditsRepository(sql).recordPurchase(7, PURCHASE)).toBe("revoked");
    expect(find(calls, "INSERT INTO credit_purchases")).toBeUndefined();
    expect(find(calls, "INSERT INTO credit_balances")).toBeUndefined();
  });

  test("takes the per-transaction lock before looking at revocations and purchases", async () => {
    const { sql, calls } = fakeSql(() => []);
    await new PgCreditsRepository(sql).recordPurchase(7, PURCHASE);
    const lock = index(calls, "pg_advisory_xact_lock");
    expect(lock).toBe(0);
    expect(calls[lock]?.values).toEqual([PURCHASE.transactionId]);
    expect(lock).toBeLessThan(index(calls, "FROM credit_revocations"));
    expect(lock).toBeLessThan(index(calls, "INSERT INTO credit_purchases"));
  });

  test("a transaction already credited to the same member credits nothing more", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "SELECT user_id") ? [{ user_id: 7 }] : []));
    expect(await new PgCreditsRepository(sql).recordPurchase(7, PURCHASE)).toBe("already_credited");
    expect(find(calls, "INSERT INTO credit_balances")).toBeUndefined();
  });

  test("a transaction held by another member is reported, not credited", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "SELECT user_id") ? [{ user_id: 8 }] : []));
    expect(await new PgCreditsRepository(sql).recordPurchase(7, PURCHASE)).toBe("owned_by_another_user");
    expect(find(calls, "INSERT INTO credit_balances")).toBeUndefined();
  });
});

describe("refundPurchase", () => {
  test("marks the purchase refunded once and takes the quantity off the balance", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "UPDATE credit_purchases") ? [{ user_id: 7, kind: "boost", quantity: 3 }] : []));
    expect(await new PgCreditsRepository(sql).refundPurchase("t1")).toBe("refunded");
    const mark = find(calls, "UPDATE credit_purchases") as Call;
    expect(has(mark, "refunded_at = NOW()")).toBe(true);
    expect(has(mark, "refunded_at IS NULL")).toBe(true);
    expect(find(calls, "INSERT INTO credit_balances")?.values).toEqual([7, "boost", -3]);
  });

  test("a replay finds the purchase already refunded and changes nothing", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "SELECT 1") ? [{ "?column?": 1 }] : []));
    expect(await new PgCreditsRepository(sql).refundPurchase("t1")).toBe("already_refunded");
    expect(find(calls, "INSERT INTO credit_balances")).toBeUndefined();
  });

  test("an unknown transaction is unknown, and remembered as revoked under the same lock", async () => {
    const { sql, calls } = fakeSql(() => []);
    expect(await new PgCreditsRepository(sql).refundPurchase("t1")).toBe("unknown");
    const remember = find(calls, "INSERT INTO credit_revocations") as Call;
    expect(has(remember, "ON CONFLICT (transaction_id) DO NOTHING")).toBe(true);
    expect(remember.values).toEqual(["t1"]);
    expect(remember.inTransaction).toBe(true);
    expect(index(calls, "pg_advisory_xact_lock")).toBe(0);
  });

  test("a known transaction is not recorded as revoked", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "SELECT 1") ? [{ "?column?": 1 }] : []));
    await new PgCreditsRepository(sql).refundPurchase("t1");
    expect(find(calls, "INSERT INTO credit_revocations")).toBeUndefined();
  });
});

describe("snapshot", () => {
  test("reads daily usage and purchased balances per kind", async () => {
    const resetsAt = new Date("2026-10-25T00:00:00Z");
    const { sql } = fakeSql((call) => {
      if (has(call, "FROM credit_spends")) return [{ kind: "super_like", used: 2 }];
      if (has(call, "FROM credit_balances")) return [{ kind: "boost", balance: -1 }];
      return [{ resets_at: resetsAt }];
    });
    expect(await new PgCreditsRepository(sql).snapshot(7)).toEqual({
      dailyUsed: { super_like: 2, boost: 0 },
      balances: { super_like: 0, boost: -1 },
      resetsAt,
    });
  });
});

describe("PgPlusStatus", () => {
  test("is mazl+ only with an active row whose expiry is still ahead, read on the subscriptions table", async () => {
    const { sql, calls } = fakeSql(() => [{ active: 1 }]);
    expect(await new PgPlusStatus(sql).isPlus(7)).toBe(true);
    const call = calls[0] as Call;
    expect(has(call, "FROM subscriptions")).toBe(true);
    expect(has(call, "status = 'active'")).toBe(true);
    expect(has(call, "expires_at > (NOW() AT TIME ZONE 'UTC')")).toBe(true);
    expect(call.values).toEqual([7]);
  });

  test("is free without such a row", async () => {
    const { sql } = fakeSql(() => []);
    expect(await new PgPlusStatus(sql).isPlus(7)).toBe(false);
  });
});

describe("parameters", () => {
  test("binds every value, never concatenating it into the SQL text", async () => {
    const { sql, calls } = fakeSql((call) => (has(call, "INSERT INTO credit_purchases") ? [{ transaction_id: "x" }] : []));
    const repository = new PgCreditsRepository(sql);
    await repository.recordPurchase(7, PURCHASE);
    await repository.refundPurchase(PURCHASE.transactionId);
    for (const call of calls) expect(call.text).not.toContain("DROP TABLE");
    expect(find(calls, "INSERT INTO credit_purchases")?.values).toContain(PURCHASE.transactionId);
  });
});
