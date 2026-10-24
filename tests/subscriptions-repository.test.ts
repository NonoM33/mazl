import { describe, expect, test } from "bun:test";
import { handleAppleNotification } from "../src/features/subscriptions/application/handle-notification";
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

// Apple does not promise to deliver notifications in order, nor once.
describe("notifications delivered out of order", () => {
  const T1 = Math.floor(Date.now() / 1000) * 1000 + 10 * DAY; // end of the first period
  const T2 = T1 + 30 * DAY; // end of the renewed period

  async function memberWithPlusUntilT1(label: string) {
    const member = await makeUser(label);
    const transactionId = newTransactionId();
    await repository.activate(member.id, subscription(transactionId, new Date(T1)));
    return { member, transactionId };
  }

  let counter = 0;
  async function deliver(transactionId: string, notificationType: string, expiresDate: number): Promise<void> {
    const jws = new FakeJwsVerifier();
    const info = jws.register(`info-${counter}`, {
      bundleId: BUNDLE,
      productId: PRODUCT,
      originalTransactionId: transactionId,
      transactionId: `${transactionId}-${expiresDate}`,
      originalPurchaseDate: Date.now() - DAY,
      expiresDate,
      environment: "Production",
      type: "Auto-Renewable Subscription",
    });
    const payload = jws.register(`payload-${counter}`, { notificationType, data: { signedTransactionInfo: info } });
    counter += 1;
    const transactions = new TransactionVerifier(jws, { bundleId: BUNDLE, productIds: [PRODUCT] });
    await handleAppleNotification({ transactions, repository }, payload);
  }

  async function stateOf(userId: number): Promise<{ status: string }> {
    return { status: (await rowOf(userId)).status };
  }

  test("an EXPIRED of the first period, received after the DID_RENEW, does not cut mazl+", async () => {
    const { member, transactionId } = await memberWithPlusUntilT1("order-expired");
    await deliver(transactionId, "DID_RENEW", T2);
    expect((await stateOf(member.id)).status).toBe("active");

    await deliver(transactionId, "EXPIRED", T1); // late: it speaks of the period already left behind
    expect((await stateOf(member.id)).status).toBe("active");
  });

  test("a late billing issue of the first period does not undo the renewal either", async () => {
    const { member, transactionId } = await memberWithPlusUntilT1("order-billing");
    await deliver(transactionId, "DID_RENEW", T2);
    await deliver(transactionId, "DID_FAIL_TO_RENEW", T1);
    expect((await stateOf(member.id)).status).toBe("active");
  });

  test("the EXPIRED of the current period still ends mazl+", async () => {
    const { member, transactionId } = await memberWithPlusUntilT1("order-current");
    await deliver(transactionId, "EXPIRED", T1);
    expect((await stateOf(member.id)).status).toBe("expired");
  });

  test("a refund of the current period still revokes, and a replayed old renewal does not undo it", async () => {
    const { member, transactionId } = await memberWithPlusUntilT1("order-refund");
    await deliver(transactionId, "DID_RENEW", T2);
    await deliver(transactionId, "REFUND", T2);
    expect((await stateOf(member.id)).status).toBe("revoked");
    await deliver(transactionId, "DID_RENEW", T1);
    expect((await stateOf(member.id)).status).toBe("revoked");
  });

  test("the same notification delivered twice changes nothing more", async () => {
    const { member, transactionId } = await memberWithPlusUntilT1("order-twice");
    await deliver(transactionId, "EXPIRED", T1);
    await deliver(transactionId, "EXPIRED", T1);
    expect((await stateOf(member.id)).status).toBe("expired");
  });
});
