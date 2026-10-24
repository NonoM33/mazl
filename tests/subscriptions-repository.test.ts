import { describe, expect, test } from "bun:test";
import { TransactionVerifier } from "../src/features/subscriptions/application/transaction-verifier";
import { verifyApplePurchase } from "../src/features/subscriptions/application/verify-purchase";
import { InvalidTransactionError } from "../src/features/subscriptions/domain/errors";
import { PgSubscriptionRepository } from "../src/features/subscriptions/infra/pg-subscription-repository";
import { db, makeUser } from "./media-helpers";
import { FakeJwsVerifier } from "./unit/support/subscriptions-fakes";

// Real Postgres (TEST_DATABASE_URL) through the real repository: the attacks
// below are about what the SQL does with rows, which a stand-in cannot show.
// Needs the running server only to create members (makeUser).

const DAY = 24 * 60 * 60 * 1000;
const BUNDLE = "com.mazl.app";
const PRODUCT = "com.mazl.app.plus.1m";
const repository = new PgSubscriptionRepository(db);

function newTransactionId(): string {
  return `9${Date.now()}${Math.floor(Math.random() * 1_000_000)}`;
}

interface StoredRow {
  status: string;
  original_transaction_id: string;
}

async function rowOf(userId: number): Promise<StoredRow> {
  const rows = await db<StoredRow[]>`SELECT status, original_transaction_id FROM subscriptions WHERE user_id = ${userId}`;
  const row = rows[0];
  if (row === undefined) throw new Error("no subscription row");
  return row;
}

function subscription(originalTransactionId: string, expiresAt: Date) {
  return {
    originalTransactionId,
    productId: PRODUCT,
    planType: "monthly",
    startedAt: new Date(Date.now() - DAY),
    expiresAt,
  } as const;
}

async function refund(originalTransactionId: string): Promise<void> {
  await db`UPDATE subscriptions SET status = 'revoked' WHERE original_transaction_id = ${originalTransactionId}`;
}

async function reasonOf(action: () => Promise<unknown>): Promise<string> {
  try {
    await action();
  } catch (error) {
    if (error instanceof InvalidTransactionError) return error.reason;
    throw error;
  }
  return "accepted";
}

describe("a refunded subscription stays refunded", () => {
  test("replaying the old JWS after the refund does not give mazl+ back", async () => {
    const member = await makeUser("sub-refund");
    const transactionId = newTransactionId();
    const jws = new FakeJwsVerifier();
    // The JWS the member kept from the purchase: no revocationDate in it.
    const signed = jws.register("kept-jws", {
      bundleId: BUNDLE,
      productId: PRODUCT,
      originalTransactionId: transactionId,
      transactionId,
      originalPurchaseDate: Date.now() - DAY,
      expiresDate: Date.now() + 29 * DAY,
      environment: "Production",
      type: "Auto-Renewable Subscription",
    });
    const transactions = new TransactionVerifier(jws, { bundleId: BUNDLE, productIds: [PRODUCT] });

    await verifyApplePurchase({ transactions, repository }, member.id, signed);
    expect((await rowOf(member.id)).status).toBe("active");

    await refund(transactionId); // Apple's REFUND notification
    expect((await rowOf(member.id)).status).toBe("revoked");

    expect(await reasonOf(() => verifyApplePurchase({ transactions, repository }, member.id, signed))).toBe("revoked");
    expect((await rowOf(member.id)).status).toBe("revoked");
  });

  test("a brand new purchase by the same member after a refund is accepted", async () => {
    const member = await makeUser("sub-rebuy");
    const first = newTransactionId();
    const second = newTransactionId();
    await repository.activate(member.id, subscription(first, new Date(Date.now() + 29 * DAY)));
    await refund(first);

    await repository.activate(member.id, subscription(second, new Date(Date.now() + 30 * DAY)));
    expect(await rowOf(member.id)).toEqual({ status: "active", original_transaction_id: second });
  });

  test("an active subscription is still refreshed by a repeated JWS (restore purchases)", async () => {
    const member = await makeUser("sub-restore");
    const transactionId = newTransactionId();
    await repository.activate(member.id, subscription(transactionId, new Date(Date.now() + 10 * DAY)));
    await repository.activate(member.id, subscription(transactionId, new Date(Date.now() + 20 * DAY)));
    expect(await rowOf(member.id)).toEqual({ status: "active", original_transaction_id: transactionId });
  });

  test("an expired subscription can be restored by a newer JWS of the same transaction", async () => {
    const member = await makeUser("sub-renewed");
    const transactionId = newTransactionId();
    await repository.activate(member.id, subscription(transactionId, new Date(Date.now() + 10 * DAY)));
    await db`UPDATE subscriptions SET status = 'expired' WHERE user_id = ${member.id}`;
    await repository.activate(member.id, subscription(transactionId, new Date(Date.now() + 40 * DAY)));
    expect((await rowOf(member.id)).status).toBe("active");
  });
});
