import { beforeEach, describe, expect, test } from "bun:test";
import { handleAppleNotification } from "../../src/features/subscriptions/application/handle-notification";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import { verifyApplePurchase } from "../../src/features/subscriptions/application/verify-purchase";
import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../../src/features/subscriptions/domain/errors";
import { FakeJwsVerifier, InMemorySubscriptions } from "./support/subscriptions-fakes";

// Payload field names follow Apple's JWSTransactionDecodedPayload and
// ResponseBodyV2DecodedPayload documentation (dates in milliseconds).

const NOW = new Date("2026-10-24T12:00:00Z");
const DAY = 24 * 60 * 60 * 1000;
const BUNDLE = "com.mazl.app";
const PRODUCT = "com.mazl.app.plus.1m";

function transaction(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: PRODUCT,
    originalTransactionId: "2000000000001",
    transactionId: "2000000000009",
    originalPurchaseDate: NOW.getTime() - 5 * DAY,
    expiresDate: NOW.getTime() + 25 * DAY,
    environment: "Production",
    type: "Auto-Renewable Subscription",
    ...overrides,
  };
}

let jws: FakeJwsVerifier;
let repository: InMemorySubscriptions;
let transactions: TransactionVerifier;

beforeEach(() => {
  jws = new FakeJwsVerifier();
  repository = new InMemorySubscriptions();
  transactions = new TransactionVerifier(jws, { bundleId: BUNDLE, productIds: [PRODUCT, "com.mazl.app.plus.12m"] }, () => NOW);
});

async function rejection(action: () => Promise<unknown>): Promise<string> {
  try {
    await action();
  } catch (error) {
    if (error instanceof InvalidTransactionError) return error.reason;
    throw error;
  }
  return "accepted";
}

describe("verifyApplePurchase", () => {
  test("accepts a valid transaction and activates the subscription for the caller", async () => {
    const signed = jws.register("tx-ok", transaction());
    const result = await verifyApplePurchase({ transactions, repository }, 7, signed);
    expect(result).toEqual({
      planType: "monthly",
      status: "active",
      expiresAt: new Date(NOW.getTime() + 25 * DAY),
      productId: PRODUCT,
    });
    expect(repository.rows.get(7)?.originalTransactionId).toBe("2000000000001");
    expect(repository.rows.get(7)?.status).toBe("active");
  });

  test("maps the plan from the product id", async () => {
    const signed = jws.register("tx-year", transaction({ productId: "com.mazl.app.plus.12m" }));
    expect((await verifyApplePurchase({ transactions, repository }, 7, signed)).planType).toBe("yearly");
  });

  test("accepts Sandbox (TestFlight) transactions", async () => {
    const signed = jws.register("tx-sbx", transaction({ environment: "Sandbox" }));
    expect((await verifyApplePurchase({ transactions, repository }, 7, signed)).status).toBe("active");
  });

  const rejected: ReadonlyArray<readonly [string, Record<string, unknown>, string]> = [
    ["wrong bundleId", { bundleId: "com.evil.app" }, "wrong_bundle"],
    ["product not allowed", { productId: "com.mazl.app.plus.3m" }, "product_not_allowed"],
    ["expired", { expiresDate: NOW.getTime() - 1 }, "expired"],
    ["expiring exactly now", { expiresDate: NOW.getTime() }, "expired"],
    ["revoked", { revocationDate: NOW.getTime() - DAY }, "revoked"],
    ["no expiry date", { expiresDate: undefined }, "invalid_payload"],
    ["no original transaction id", { originalTransactionId: undefined }, "invalid_payload"],
    ["unknown environment", { environment: "Xcode" }, "invalid_payload"],
  ];
  for (const [label, overrides, reason] of rejected) {
    test(`rejects ${label}`, async () => {
      const signed = jws.register("tx-bad", transaction(overrides));
      expect(await rejection(() => verifyApplePurchase({ transactions, repository }, 7, signed))).toBe(reason);
      expect(repository.rows.size).toBe(0);
    });
  }

  test("rejects a JWS the signature verifier refuses", async () => {
    expect(await rejection(() => verifyApplePurchase({ transactions, repository }, 7, "not-registered"))).toBe("invalid_signature");
  });

  test("refuses to bind a transaction already owned by another user", async () => {
    const signed = jws.register("tx-shared", transaction());
    await verifyApplePurchase({ transactions, repository }, 7, signed);
    await expect(verifyApplePurchase({ transactions, repository }, 8, signed)).rejects.toBeInstanceOf(TransactionOwnedByAnotherUserError);
    expect(repository.rows.has(8)).toBe(false);
  });

  test("lets the same user submit the same transaction again", async () => {
    const signed = jws.register("tx-again", transaction());
    await verifyApplePurchase({ transactions, repository }, 7, signed);
    await verifyApplePurchase({ transactions, repository }, 7, signed);
    expect(repository.rows.size).toBe(1);
  });
});

function notification(type: string, signedTransactionInfo: string | undefined, subtype?: string): Record<string, unknown> {
  return {
    notificationType: type,
    ...(subtype === undefined ? {} : { subtype }),
    notificationUUID: "00000000-0000-4000-8000-000000000001",
    signedDate: NOW.getTime(),
    data: { environment: "Production", bundleId: BUNDLE, ...(signedTransactionInfo === undefined ? {} : { signedTransactionInfo }) },
  };
}

describe("handleAppleNotification", () => {
  beforeEach(async () => {
    await verifyApplePurchase({ transactions, repository }, 7, jws.register("tx-initial", transaction()));
  });

  function deliver(type: string, txOverrides: Record<string, unknown> = {}, subtype?: string): Promise<unknown> {
    const inner = jws.register(`inner-${type}`, transaction(txOverrides));
    const outer = jws.register(`outer-${type}`, notification(type, inner, subtype));
    return handleAppleNotification({ transactions, repository }, outer);
  }

  test("DID_RENEW extends the subscription", async () => {
    const newExpiry = NOW.getTime() + 55 * DAY;
    expect(await deliver("DID_RENEW", { expiresDate: newExpiry })).toEqual({ kind: "handled" });
    expect(repository.rows.get(7)?.status).toBe("active");
    expect(repository.rows.get(7)?.expiresAt).toEqual(new Date(newExpiry));
  });

  test("an out-of-order renewal with an older expiry does not shorten the subscription", async () => {
    const before = repository.rows.get(7)?.expiresAt;
    await deliver("DID_RENEW", { expiresDate: NOW.getTime() + DAY });
    expect(repository.rows.get(7)?.expiresAt).toEqual(before);
  });

  test("EXPIRED marks the subscription expired even though the transaction is past its expiry", async () => {
    // The period that ended is the stored one: Apple's EXPIRED carries its expiry.
    const stored = repository.rows.get(7);
    if (stored !== undefined) repository.rows.set(7, { ...stored, expiresAt: new Date(NOW.getTime() - DAY) });
    expect(await deliver("EXPIRED", { expiresDate: NOW.getTime() - DAY }, "VOLUNTARY")).toEqual({ kind: "handled" });
    expect(repository.rows.get(7)?.status).toBe("expired");
  });

  test("an EXPIRED of an older period, delivered after a renewal, is acknowledged and changes nothing", async () => {
    const renewedUntil = NOW.getTime() + 55 * DAY;
    await deliver("DID_RENEW", { expiresDate: renewedUntil });
    expect(await deliver("EXPIRED", { expiresDate: NOW.getTime() + 25 * DAY })).toEqual({ kind: "handled" });
    expect(repository.rows.get(7)?.status).toBe("active");
    expect(repository.rows.get(7)?.expiresAt).toEqual(new Date(renewedUntil));
  });

  test("REFUND marks the subscription revoked even though the transaction carries a revocationDate", async () => {
    expect(await deliver("REFUND", { revocationDate: NOW.getTime() - 1000 })).toEqual({ kind: "handled" });
    expect(repository.rows.get(7)?.status).toBe("revoked");
  });

  test("DID_FAIL_TO_RENEW flags a billing issue", async () => {
    await deliver("DID_FAIL_TO_RENEW", {}, "GRACE_PERIOD");
    expect(repository.rows.get(7)?.status).toBe("billing_issue");
  });

  test("a renewal after a billing issue reactivates the subscription", async () => {
    await deliver("DID_FAIL_TO_RENEW");
    await deliver("DID_RENEW", { expiresDate: NOW.getTime() + 60 * DAY });
    expect(repository.rows.get(7)?.status).toBe("active");
  });

  test("an unknown originalTransactionId is acknowledged and ignored", async () => {
    expect(await deliver("DID_RENEW", { originalTransactionId: "9999999999" })).toEqual({ kind: "ignored", reason: "unknown_transaction" });
  });

  test("notification types we do not act on are acknowledged without a transaction", async () => {
    const outer = jws.register("outer-test", notification("TEST", undefined));
    expect(await handleAppleNotification({ transactions, repository }, outer)).toEqual({ kind: "handled" });
    expect(repository.rows.get(7)?.status).toBe("active");
  });

  test("rejects a forged outer payload", async () => {
    expect(await rejection(() => handleAppleNotification({ transactions, repository }, "forged"))).toBe("invalid_signature");
  });

  test("rejects a valid outer payload whose inner transaction is forged", async () => {
    const outer = jws.register("outer-forged-inner", notification("DID_RENEW", "forged-inner"));
    expect(await rejection(() => handleAppleNotification({ transactions, repository }, outer))).toBe("invalid_signature");
  });

  test("rejects an inner transaction for another bundle", async () => {
    expect(await rejection(() => deliver("DID_RENEW", { bundleId: "com.evil.app" }))).toBe("wrong_bundle");
  });

  test("rejects an inner transaction for a product we do not sell", async () => {
    expect(await rejection(() => deliver("DID_RENEW", { productId: "com.mazl.app.plus.3m" }))).toBe("product_not_allowed");
  });

  test("rejects a notification without its transaction when the type needs one", async () => {
    const outer = jws.register("outer-no-tx", notification("DID_RENEW", undefined));
    expect(await rejection(() => handleAppleNotification({ transactions, repository }, outer))).toBe("invalid_payload");
  });

  test("rejects a notification body that is not a notification", async () => {
    const outer = jws.register("outer-junk", { hello: "world" });
    expect(await rejection(() => handleAppleNotification({ transactions, repository }, outer))).toBe("invalid_payload");
  });
});
