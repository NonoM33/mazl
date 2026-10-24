import { beforeEach, describe, expect, test } from "bun:test";
import { handleAppleNotification } from "../../src/features/subscriptions/application/handle-notification";
import type { ConsumableRefundOutcome, ConsumableRefunds } from "../../src/features/subscriptions/application/ports";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import { verifyApplePurchase } from "../../src/features/subscriptions/application/verify-purchase";
import { InvalidTransactionError } from "../../src/features/subscriptions/domain/errors";
import { FakeJwsVerifier, InMemorySubscriptions } from "./support/subscriptions-fakes";

// A consumable has no expiresDate: the shared decoder must accept it, while the
// subscription flow keeps demanding a live expiry. Notifications route a
// consumable to the refund port and never to the subscription repository.

const NOW = new Date("2026-10-24T12:00:00Z");
const DAY = 24 * 60 * 60 * 1000;
const BUNDLE = "com.mazl.app";
const SUBSCRIPTION_PRODUCT = "com.mazl.app.plus.1m";
const CONSUMABLE_PRODUCT = "com.mazl.app.boost.3";

function consumable(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: CONSUMABLE_PRODUCT,
    originalTransactionId: "5000000000001",
    transactionId: "5000000000001",
    purchaseDate: NOW.getTime() - DAY,
    environment: "Production",
    type: "Consumable",
    ...overrides,
  };
}

function subscription(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: SUBSCRIPTION_PRODUCT,
    originalTransactionId: "2000000000001",
    transactionId: "2000000000009",
    originalPurchaseDate: NOW.getTime() - 5 * DAY,
    expiresDate: NOW.getTime() + 25 * DAY,
    environment: "Production",
    type: "Auto-Renewable Subscription",
    ...overrides,
  };
}

class FakeRefunds implements ConsumableRefunds {
  readonly refunded: string[] = [];
  outcome: ConsumableRefundOutcome = "refunded";
  sells(productId: string): boolean {
    return productId.startsWith("com.mazl.app.boost.") || productId.startsWith("com.mazl.app.superlikes.");
  }
  async refund(transactionId: string): Promise<ConsumableRefundOutcome> {
    this.refunded.push(transactionId);
    return this.outcome;
  }
}

let jws: FakeJwsVerifier;
let repository: InMemorySubscriptions;
let transactions: TransactionVerifier;
let consumables: FakeRefunds;

beforeEach(() => {
  jws = new FakeJwsVerifier();
  repository = new InMemorySubscriptions();
  consumables = new FakeRefunds();
  transactions = new TransactionVerifier(jws, { bundleId: BUNDLE, productIds: [SUBSCRIPTION_PRODUCT] }, () => NOW);
});

function notification(type: string, signedTransactionInfo: string | undefined): Record<string, unknown> {
  return {
    notificationType: type,
    notificationUUID: "00000000-0000-4000-8000-000000000001",
    data: { environment: "Production", bundleId: BUNDLE, ...(signedTransactionInfo === undefined ? {} : { signedTransactionInfo }) },
  };
}

function deliver(type: string, tx: Record<string, unknown>): Promise<unknown> {
  const inner = jws.register(`inner-${type}`, tx);
  const outer = jws.register(`outer-${type}`, notification(type, inner));
  return handleAppleNotification({ transactions, repository, consumables }, outer);
}

async function reason(action: () => Promise<unknown> | unknown): Promise<string> {
  try {
    await action();
  } catch (error) {
    if (error instanceof InvalidTransactionError) return error.reason;
    throw error;
  }
  return "accepted";
}

describe("TransactionVerifier.verifySigned", () => {
  test("decodes a consumable that carries no expiresDate", () => {
    const decoded = transactions.verifySigned(jws.register("c", consumable()));
    expect(decoded.transactionId).toBe("5000000000001");
    expect(decoded.type).toBe("Consumable");
    expect(decoded.productId).toBe(CONSUMABLE_PRODUCT);
    expect(decoded.expiresAt).toBeUndefined();
    expect(decoded.purchaseDate).toEqual(new Date(NOW.getTime() - DAY));
  });

  test("still checks signature and bundle", async () => {
    expect(await reason(() => transactions.verifySigned("unknown"))).toBe("invalid_signature");
    expect(await reason(() => transactions.verifySigned(jws.register("b", consumable({ bundleId: "com.evil.app" }))))).toBe("wrong_bundle");
  });

  test("keeps the revocation date", () => {
    const decoded = transactions.verifySigned(jws.register("r", consumable({ revocationDate: NOW.getTime() })));
    expect(decoded.revokedAt).toEqual(NOW);
  });
});

describe("subscriptions stay strict", () => {
  test("a consumable presented as a subscription is refused, never activated", async () => {
    const signed = jws.register("c", consumable());
    expect(await reason(() => verifyApplePurchase({ transactions, repository }, 7, signed))).toBe("product_not_allowed");
    expect(repository.rows.size).toBe(0);
  });

  test("a subscription product without expiresDate is still invalid_payload", async () => {
    const signed = jws.register("s", subscription({ expiresDate: undefined }));
    expect(await reason(() => verifyApplePurchase({ transactions, repository }, 7, signed))).toBe("invalid_payload");
  });

  test("a subscription purchase still needs a future expiry", async () => {
    const signed = jws.register("e", subscription({ expiresDate: NOW.getTime() }));
    expect(await reason(() => verifyApplePurchase({ transactions, repository }, 7, signed))).toBe("expired");
  });
});

describe("notifications carrying a consumable", () => {
  test("REFUND refunds the consumable by its transactionId and touches no subscription", async () => {
    await verifyApplePurchase({ transactions, repository }, 7, jws.register("sub", subscription()));
    expect(await deliver("REFUND", consumable({ revocationDate: NOW.getTime() }))).toEqual({ kind: "handled" });
    expect(consumables.refunded).toEqual(["5000000000001"]);
    expect(repository.rows.get(7)?.status).toBe("active");
  });

  test("REVOKE refunds too", async () => {
    expect(await deliver("REVOKE", consumable())).toEqual({ kind: "handled" });
    expect(consumables.refunded).toEqual(["5000000000001"]);
  });

  test("an unknown consumable is acknowledged and ignored, never a 422", async () => {
    consumables.outcome = "unknown";
    expect(await deliver("REFUND", consumable())).toEqual({ kind: "ignored", reason: "unknown_transaction" });
  });

  test("a replayed refund is acknowledged", async () => {
    consumables.outcome = "already_refunded";
    expect(await deliver("REFUND", consumable())).toEqual({ kind: "handled" });
  });

  test("CONSUMPTION_REQUEST changes nothing", async () => {
    expect(await deliver("CONSUMPTION_REQUEST", consumable())).toEqual({ kind: "handled" });
    expect(consumables.refunded).toEqual([]);
  });

  test("a type that is not a refund never refunds a consumable, even a subscription type", async () => {
    expect(await deliver("DID_RENEW", consumable())).toEqual({ kind: "handled" });
    expect(consumables.refunded).toEqual([]);
    expect(repository.rows.size).toBe(0);
  });

  test("a consumable notification without transactionId is invalid_payload", async () => {
    expect(await reason(() => deliver("REFUND", consumable({ transactionId: undefined })))).toBe("invalid_payload");
  });

  test("a forged consumable is refused before anything is refunded", async () => {
    const outer = jws.register("outer-forged", notification("REFUND", "forged"));
    expect(await reason(() => handleAppleNotification({ transactions, repository, consumables }, outer))).toBe("invalid_signature");
    expect(consumables.refunded).toEqual([]);
  });

  test("a subscription notification is unchanged when the consumable port is present", async () => {
    await verifyApplePurchase({ transactions, repository }, 7, jws.register("sub", subscription()));
    expect(await deliver("REFUND", subscription({ revocationDate: NOW.getTime() }))).toEqual({ kind: "handled" });
    expect(repository.rows.get(7)?.status).toBe("revoked");
    expect(consumables.refunded).toEqual([]);
  });

  test("a product we sell in neither policy is still product_not_allowed", async () => {
    expect(await reason(() => deliver("REFUND", subscription({ productId: "com.mazl.app.plus.3m" })))).toBe("product_not_allowed");
  });
});
