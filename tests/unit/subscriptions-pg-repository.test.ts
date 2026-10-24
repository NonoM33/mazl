import { describe, expect, test } from "bun:test";
import type { Sql } from "postgres";
import { TransactionOwnedByAnotherUserError } from "../../src/features/subscriptions/domain/errors";
import { PgSubscriptionRepository } from "../../src/features/subscriptions/infra/pg-subscription-repository";

// No database here: a recording stand-in for the postgres.js tag checks that
// every value is bound as a parameter (never concatenated into the SQL text)
// and that the unique-index violation maps to the domain error.

interface Call {
  readonly text: string;
  readonly values: readonly unknown[];
}

function fakeSql(behaviour: (call: Call) => unknown[] | Error): { sql: Sql; calls: Call[] } {
  const calls: Call[] = [];
  const tag = async (strings: TemplateStringsArray, ...values: unknown[]): Promise<unknown[]> => {
    const call = { text: strings.join("?"), values };
    calls.push(call);
    const result = behaviour(call);
    if (result instanceof Error) throw result;
    return result;
  };
  return { sql: tag as unknown as Sql, calls };
}

const SUBSCRIPTION = {
  originalTransactionId: "4000000000001'; DROP TABLE users; --",
  productId: "com.mazl.app.plus.1m",
  planType: "monthly",
  startedAt: new Date("2026-10-01T00:00:00Z"),
  expiresAt: new Date("2026-11-01T00:00:00Z"),
} as const;

describe("PgSubscriptionRepository", () => {
  test("binds every value as a parameter", async () => {
    const { sql, calls } = fakeSql(() => []);
    const repository = new PgSubscriptionRepository(sql);
    await repository.activate(7, SUBSCRIPTION);
    await repository.renew(SUBSCRIPTION);
    await repository.markStatus(SUBSCRIPTION.originalTransactionId, "revoked");
    await repository.findOwner(SUBSCRIPTION.originalTransactionId);
    await repository.findByUserId(7);
    for (const call of calls) expect(call.text).not.toContain("DROP TABLE");
    expect(calls[0]?.values).toContain(SUBSCRIPTION.originalTransactionId);
  });

  test("never writes the legacy RevenueCat column", async () => {
    const { sql, calls } = fakeSql(() => []);
    const repository = new PgSubscriptionRepository(sql);
    await repository.activate(7, SUBSCRIPTION);
    await repository.renew(SUBSCRIPTION);
    await repository.markStatus("1", "expired");
    for (const call of calls) expect(call.text.toLowerCase()).not.toContain("revenuecat");
  });

  test("maps an original-transaction unique violation to the domain error", async () => {
    const conflict = Object.assign(new Error("duplicate key"), { code: "23505", constraint_name: "idx_subscriptions_original_tx" });
    const { sql } = fakeSql(() => conflict);
    await expect(new PgSubscriptionRepository(sql).activate(7, SUBSCRIPTION)).rejects.toBeInstanceOf(TransactionOwnedByAnotherUserError);
  });

  test("lets any other database error through", async () => {
    const other = Object.assign(new Error("duplicate key"), { code: "23505", constraint_name: "something_else" });
    const { sql } = fakeSql(() => other);
    await expect(new PgSubscriptionRepository(sql).activate(7, SUBSCRIPTION)).rejects.toBe(other);
  });

  test("findOwner and findByUserId read the first row", async () => {
    const { sql } = fakeSql((call) => (call.text.includes("SELECT user_id") ? [{ user_id: 7 }] : [{ id: 1, user_id: 7 }]));
    const repository = new PgSubscriptionRepository(sql);
    expect(await repository.findOwner("x")).toBe(7);
    expect(await repository.findByUserId(7)).toEqual({ id: 1, user_id: 7 });
  });
});
