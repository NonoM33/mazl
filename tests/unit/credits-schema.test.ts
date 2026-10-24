import { describe, expect, test } from "bun:test";
import type { Sql } from "postgres";
import { createCreditTables, eraseCredits } from "../../src/features/credits/infra/schema";

// Schema of docs/premium/CREDITS.md, "Données", checked on the SQL text.

function recorder(): { sql: Sql; texts: string[]; values: unknown[][] } {
  const texts: string[] = [];
  const values: unknown[][] = [];
  const tag = async (strings: TemplateStringsArray, ...bound: unknown[]): Promise<unknown[]> => {
    texts.push(strings.join("?").replace(/\s+/g, " ").trim());
    values.push(bound);
    return [];
  };
  return { sql: tag as unknown as Sql, texts, values };
}

describe("createCreditTables", () => {
  test("creates the three tables idempotently, each owned by a user with ON DELETE CASCADE", async () => {
    const { sql, texts } = recorder();
    await createCreditTables(sql);
    for (const table of ["credit_balances", "credit_purchases", "credit_spends"]) {
      const statement = texts.find((text) => text.startsWith(`CREATE TABLE IF NOT EXISTS ${table} `));
      expect(statement).toBeDefined();
      expect(statement).toContain("user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE");
    }
  });

  test("balances: primary key (user_id, kind), balance INT that may go negative", async () => {
    const { sql, texts } = recorder();
    await createCreditTables(sql);
    const statement = texts.find((text) => text.includes("credit_balances (")) ?? "";
    expect(statement).toContain("PRIMARY KEY (user_id, kind)");
    expect(statement).toContain("balance INTEGER NOT NULL DEFAULT 0");
    expect(statement).not.toContain("CHECK");
  });

  test("purchases: the transactionId is the primary key and refunded_at is nullable", async () => {
    const { sql, texts } = recorder();
    await createCreditTables(sql);
    const statement = texts.find((text) => text.includes("credit_purchases (")) ?? "";
    expect(statement).toContain("transaction_id VARCHAR(64) PRIMARY KEY");
    expect(statement).toContain("refunded_at TIMESTAMP,");
    for (const column of ["product_id", "kind", "quantity", "environment", "purchased_at", "created_at"]) expect(statement).toContain(column);
  });

  test("spends: source is daily or purchased and the target is optional", async () => {
    const { sql, texts } = recorder();
    await createCreditTables(sql);
    const statement = texts.find((text) => text.includes("credit_spends (")) ?? "";
    expect(statement).toContain("source VARCHAR(10) NOT NULL CHECK (source IN ('daily', 'purchased'))");
    expect(statement).toContain("target_user_id INTEGER");
    expect(statement).not.toContain("target_user_id INTEGER NOT NULL");
  });

  test("indexes the daily count", async () => {
    const { sql, texts } = recorder();
    await createCreditTables(sql);
    expect(texts.some((text) => text.startsWith("CREATE INDEX IF NOT EXISTS") && text.includes("credit_spends (user_id, kind, created_at)"))).toBe(true);
  });
});

describe("eraseCredits", () => {
  test("deletes the three tables of the member, binding the id", async () => {
    const { sql, texts, values } = recorder();
    await eraseCredits(sql, 7);
    expect(texts.map((text) => text.split(" WHERE")[0])).toEqual([
      "DELETE FROM credit_spends",
      "DELETE FROM credit_purchases",
      "DELETE FROM credit_balances",
    ]);
    expect(values).toEqual([[7], [7], [7]]);
  });
});
