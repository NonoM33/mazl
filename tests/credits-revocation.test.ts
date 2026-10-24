import { describe, expect, test } from "bun:test";
import { CreditsService } from "../src/features/credits/application/credits-service";
import { PgCreditsRepository } from "../src/features/credits/infra/pg-credits-repository";
import { PgPlusStatus } from "../src/features/credits/infra/pg-plus-status";
import { handleAppleNotification } from "../src/features/subscriptions/application/handle-notification";
import { TransactionVerifier } from "../src/features/subscriptions/application/transaction-verifier";
import { InvalidTransactionError } from "../src/features/subscriptions/domain/errors";
import { db, makeUser } from "./media-helpers";
import { FakeJwsVerifier, InMemorySubscriptions } from "./unit/support/subscriptions-fakes";

// Real Postgres (TEST_DATABASE_URL) through the real credits repository.
// The attack: buy a pack, keep the JWS back, get Apple to refund the purchase
// (REFUND notification), then present the JWS. It carries no revocationDate,
// and the refund arrived for a transaction the server had never credited, so
// it was acknowledged without a trace and the pack was credited afterwards.

const BUNDLE = "com.mazl.app";
const jws = new FakeJwsVerifier();
const transactions = new TransactionVerifier(jws, { bundleId: BUNDLE, productIds: ["com.mazl.app.plus.1m"] });
const credits = new CreditsService({
  repository: new PgCreditsRepository(db),
  plus: new PgPlusStatus(db),
  transactions,
});

let counter = 0;
function newTransactionId(): string {
  counter += 1;
  return `7${Date.now()}${counter}${Math.floor(Math.random() * 100_000)}`;
}

function packOf(transactionId: string, productId = "com.mazl.app.boost.3"): string {
  return jws.register(`pack-${transactionId}`, {
    bundleId: BUNDLE,
    productId,
    originalTransactionId: transactionId,
    transactionId,
    purchaseDate: Date.now() - 1000,
    environment: "Production",
    type: "Consumable",
  });
}

async function appleSays(notificationType: "REFUND" | "REVOKE", transactionId: string) {
  const signedTransactionInfo = packOf(transactionId);
  const signedPayload = jws.register(`note-${notificationType}-${transactionId}`, {
    notificationType,
    data: { signedTransactionInfo },
  });
  return await handleAppleNotification({ transactions, repository: new InMemorySubscriptions(), consumables: credits }, signedPayload);
}

async function purchasedBalance(userId: number): Promise<number> {
  return (await credits.credits(userId)).boost.purchased_balance;
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

describe("a refund that reaches the server before the purchase does", () => {
  for (const notificationType of ["REFUND", "REVOKE"] as const) {
    test(`${notificationType} then the kept JWS: nothing is credited`, async () => {
      const member = await makeUser(`refund-first-${notificationType.toLowerCase()}`);
      const transactionId = newTransactionId();
      const kept = packOf(transactionId);

      // Apple's notification arrives first. The answer to Apple is unchanged.
      expect(await appleSays(notificationType, transactionId)).toEqual({ kind: "ignored", reason: "unknown_transaction" });

      expect(await reasonOf(() => credits.verifyPurchase(member.id, kept))).toBe("revoked");
      expect(await purchasedBalance(member.id)).toBe(0);
      const lines = await db`SELECT 1 FROM credit_purchases WHERE transaction_id = ${transactionId}`;
      expect(lines).toHaveLength(0);
    });
  }

  test("a replayed refund notification stays harmless", async () => {
    const member = await makeUser("refund-first-twice");
    const transactionId = newTransactionId();
    await appleSays("REFUND", transactionId);
    await appleSays("REFUND", transactionId);
    expect(await reasonOf(() => credits.verifyPurchase(member.id, packOf(transactionId)))).toBe("revoked");
  });

  test("the refusal does not touch other purchases of the same member", async () => {
    const member = await makeUser("refund-first-others");
    const refunded = newTransactionId();
    const honest = newTransactionId();
    await appleSays("REFUND", refunded);
    expect((await credits.verifyPurchase(member.id, packOf(honest))).credited).toBe(true);
    expect(await reasonOf(() => credits.verifyPurchase(member.id, packOf(refunded)))).toBe("revoked");
    expect(await purchasedBalance(member.id)).toBe(3);
  });
});

describe("the ordinary order of events keeps working", () => {
  test("purchase, then refund: credited once, then taken back once", async () => {
    const member = await makeUser("refund-after");
    const transactionId = newTransactionId();
    expect((await credits.verifyPurchase(member.id, packOf(transactionId))).credited).toBe(true);
    expect(await purchasedBalance(member.id)).toBe(3);

    expect(await appleSays("REFUND", transactionId)).toEqual({ kind: "handled" });
    expect(await appleSays("REFUND", transactionId)).toEqual({ kind: "handled" });
    expect(await purchasedBalance(member.id)).toBe(0);
  });

  test("the same JWS twice is still credited once", async () => {
    const member = await makeUser("twice");
    const signed = packOf(newTransactionId());
    expect((await credits.verifyPurchase(member.id, signed)).credited).toBe(true);
    expect((await credits.verifyPurchase(member.id, signed)).credited).toBe(false);
    expect(await purchasedBalance(member.id)).toBe(3);
  });
});
