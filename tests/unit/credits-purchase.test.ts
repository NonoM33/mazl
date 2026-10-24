import { beforeEach, describe, expect, test } from "bun:test";
import { CreditsService } from "../../src/features/credits/application/credits-service";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../../src/features/subscriptions/domain/errors";
import { FakePlusStatus, InMemoryCredits } from "./support/credits-fakes";
import { FakeJwsVerifier } from "./support/subscriptions-fakes";

const NOW = new Date("2026-10-24T12:00:00Z");
const BUNDLE = "com.mazl.app";
const USER = 7;

function consumable(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: "com.mazl.app.boost.3",
    originalTransactionId: "6000000000001",
    transactionId: "6000000000001",
    purchaseDate: NOW.getTime() - 1000,
    environment: "Production",
    type: "Consumable",
    ...overrides,
  };
}

let jws: FakeJwsVerifier;
let repository: InMemoryCredits;
let service: CreditsService;

beforeEach(() => {
  jws = new FakeJwsVerifier();
  repository = new InMemoryCredits();
  const transactions = new TransactionVerifier(jws, { bundleId: BUNDLE, productIds: ["com.mazl.app.plus.1m"] }, () => NOW);
  service = new CreditsService({ repository, plus: new FakePlusStatus(), transactions, clock: () => NOW });
});

async function reason(action: () => Promise<unknown>): Promise<string> {
  try {
    await action();
  } catch (error) {
    if (error instanceof InvalidTransactionError) return error.reason;
    if (error instanceof TransactionOwnedByAnotherUserError) return "owned_by_another_user";
    throw error;
  }
  return "accepted";
}

describe("a refund announced before the purchase is presented", () => {
  test("the purchase is refused as revoked and credits nothing", async () => {
    expect(await service.refund("6000000000001")).toBe("unknown");
    expect(await reason(() => service.verifyPurchase(USER, jws.register("late", consumable())))).toBe("revoked");
    expect(repository.balance(USER, "boost")).toBe(0);
    expect(repository.purchases.size).toBe(0);
  });
});

describe("verifyPurchase", () => {
  test("credits a genuine consumable and returns the new balance", async () => {
    const result = await service.verifyPurchase(USER, jws.register("ok", consumable()));
    expect(result.credited).toBe(true);
    expect(result.kind).toBe("boost");
    expect(result.quantity).toBe(3);
    expect(result.credits.boost.purchased_balance).toBe(3);
    expect(repository.balance(USER, "boost")).toBe(3);
  });

  test("credits each of the four products with its kind and quantity", async () => {
    const expected: ReadonlyArray<readonly [string, string, number]> = [
      ["com.mazl.app.boost.1", "boost", 1],
      ["com.mazl.app.boost.3", "boost", 3],
      ["com.mazl.app.superlikes.5", "super_like", 5],
      ["com.mazl.app.superlikes.15", "super_like", 15],
    ];
    for (const [productId, kind, quantity] of expected) {
      const result = await service.verifyPurchase(USER, jws.register(productId, consumable({ productId, transactionId: `tx-${productId}`, originalTransactionId: `tx-${productId}` })));
      expect(`${result.kind}:${result.quantity}`).toBe(`${kind}:${quantity}`);
    }
    expect(repository.balance(USER, "boost")).toBe(4);
    expect(repository.balance(USER, "super_like")).toBe(20);
  });

  test("the same transactionId is credited once: the second call says credited false", async () => {
    const signed = jws.register("twice", consumable());
    expect((await service.verifyPurchase(USER, signed)).credited).toBe(true);
    const again = await service.verifyPurchase(USER, signed);
    expect(again.credited).toBe(false);
    expect(again.credits.boost.purchased_balance).toBe(3);
    expect(repository.balance(USER, "boost")).toBe(3);
  });

  test("two purchases of the same product count separately: the key is the transactionId", async () => {
    await service.verifyPurchase(USER, jws.register("a", consumable({ transactionId: "t-a" })));
    await service.verifyPurchase(USER, jws.register("b", consumable({ transactionId: "t-b" })));
    expect(repository.balance(USER, "boost")).toBe(6);
  });

  test("a transaction held by another member is refused and credits nothing", async () => {
    const signed = jws.register("shared", consumable());
    await service.verifyPurchase(USER, signed);
    expect(await reason(() => service.verifyPurchase(8, signed))).toBe("owned_by_another_user");
    expect(repository.balance(8, "boost")).toBe(0);
  });

  const rejected: ReadonlyArray<readonly [string, Record<string, unknown>, string]> = [
    ["a subscription product shown as a consumable", { productId: "com.mazl.app.plus.1m", type: "Auto-Renewable Subscription" }, "product_not_allowed"],
    ["an unknown product", { productId: "com.mazl.app.coins.99" }, "product_not_allowed"],
    ["the wrong bundle", { bundleId: "com.evil.app" }, "wrong_bundle"],
    ["a non-consumable type", { type: "Non-Consumable" }, "not_consumable"],
    ["a missing type", { type: undefined }, "not_consumable"],
    ["a revoked transaction", { revocationDate: NOW.getTime() - 1 }, "revoked"],
    ["a missing transactionId", { transactionId: undefined }, "invalid_payload"],
  ];
  for (const [label, overrides, expectedReason] of rejected) {
    test(`rejects ${label}`, async () => {
      expect(await reason(() => service.verifyPurchase(USER, jws.register("bad", consumable(overrides))))).toBe(expectedReason);
      expect(repository.balance(USER, "boost")).toBe(0);
      expect(repository.purchases.size).toBe(0);
    });
  }

  test("rejects a signature the verifier does not trust", async () => {
    expect(await reason(() => service.verifyPurchase(USER, "forged"))).toBe("invalid_signature");
  });
});

describe("refund", () => {
  test("takes the quantity back, once, even when Apple replays the notification", async () => {
    await service.verifyPurchase(USER, jws.register("p", consumable()));
    expect(await service.refund("6000000000001")).toBe("refunded");
    expect(repository.balance(USER, "boost")).toBe(0);
    expect(await service.refund("6000000000001")).toBe("already_refunded");
    expect(repository.balance(USER, "boost")).toBe(0);
  });

  test("an unknown transaction is reported unknown and changes nothing", async () => {
    expect(await service.refund("nope")).toBe("unknown");
  });

  test("a pack that was already spent leaves a debt, which the next purchase fills first", async () => {
    await service.verifyPurchase(USER, jws.register("p", consumable({ productId: "com.mazl.app.boost.1", transactionId: "t1" })));
    await service.spend(USER, "boost");
    expect(repository.balance(USER, "boost")).toBe(0);

    expect(await service.refund("t1")).toBe("refunded");
    expect(repository.balance(USER, "boost")).toBe(-1);
    expect((await service.credits(USER)).boost.available).toBe(0);

    await service.verifyPurchase(USER, jws.register("p3", consumable({ productId: "com.mazl.app.boost.3", transactionId: "t3" })));
    expect(repository.balance(USER, "boost")).toBe(2);
    expect((await service.credits(USER)).boost.available).toBe(2);
  });

  test("a refunded transaction presented again is not credited again", async () => {
    const signed = jws.register("p", consumable());
    await service.verifyPurchase(USER, signed);
    await service.refund("6000000000001");
    expect((await service.verifyPurchase(USER, signed)).credited).toBe(false);
    expect(repository.balance(USER, "boost")).toBe(0);
  });

  test("sells only the four products", () => {
    expect(service.sells("com.mazl.app.superlikes.15")).toBe(true);
    expect(service.sells("com.mazl.app.plus.1m")).toBe(false);
  });
});
