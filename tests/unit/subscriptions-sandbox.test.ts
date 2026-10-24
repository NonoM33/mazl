import { beforeAll, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { CreditsService } from "../../src/features/credits/application/credits-service";
import { handleAppleNotification } from "../../src/features/subscriptions/application/handle-notification";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import { verifyApplePurchase } from "../../src/features/subscriptions/application/verify-purchase";
import { InvalidTransactionError } from "../../src/features/subscriptions/domain/errors";
import { AppleJwsVerifier } from "../../src/features/subscriptions/infra/apple-jws-verifier";
import { readProductPolicy } from "../../src/features/subscriptions/infra/config";
import { registerSubscriptionsRoutes } from "../../src/features/subscriptions/presentation/subscriptions.routes";
import type { AppVariables } from "../../src/shared/http/middleware";
import { createTestPki, signedByPki, type TestPki } from "./support/apple-test-pki";
import { FakePlusStatus, InMemoryCredits } from "./support/credits-fakes";
import { InMemorySubscriptions } from "./support/subscriptions-fakes";

// The attack: a TestFlight tester (or anyone who can buy in the Apple Sandbox
// for free) presents a genuine, Apple-signed Sandbox transaction to the
// production server and gets mazl+ or credits. APPLE_ALLOW_SANDBOX=false must
// close that door for subscriptions AND consumables; the default (true) keeps
// App Review, which buys in the Sandbox against the production server, working.
// Real (throwaway) certificate chain: the JWS, the chain and the policy run for real.

const DAY = 24 * 60 * 60 * 1000;
const BUNDLE = "com.mazl.app";
const PLUS = "com.mazl.app.plus.1m";
const BOOST = "com.mazl.app.boost.3";

let pki: TestPki;

beforeAll(async () => {
  pki = await createTestPki();
});

function subscription(environment: "Sandbox" | "Production"): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: PLUS,
    originalTransactionId: "8000000000001",
    transactionId: "8000000000002",
    type: "Auto-Renewable Subscription",
    originalPurchaseDate: Date.now() - DAY,
    expiresDate: Date.now() + 30 * DAY,
    environment,
  };
}

function consumable(environment: "Sandbox" | "Production"): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: BOOST,
    originalTransactionId: "8100000000001",
    transactionId: "8100000000001",
    type: "Consumable",
    purchaseDate: Date.now() - 1000,
    environment,
  };
}

function verifierWith(allowSandbox: boolean | undefined): TransactionVerifier {
  const policy = { bundleId: BUNDLE, productIds: [PLUS], ...(allowSandbox === undefined ? {} : { allowSandbox }) };
  return new TransactionVerifier(new AppleJwsVerifier(pki.rootDer), policy);
}

async function reasonOf(action: () => unknown): Promise<string> {
  try {
    await action();
  } catch (error) {
    if (error instanceof InvalidTransactionError) return error.reason;
    throw error;
  }
  return "accepted";
}

describe("APPLE_ALLOW_SANDBOX read from the environment", () => {
  test("is true when the variable is absent or blank (behaviour unchanged)", () => {
    expect(readProductPolicy({}).allowSandbox).toBe(true);
    expect(readProductPolicy({ APPLE_ALLOW_SANDBOX: "" }).allowSandbox).toBe(true);
    expect(readProductPolicy({ APPLE_ALLOW_SANDBOX: "  " }).allowSandbox).toBe(true);
  });

  test("reads true and false", () => {
    expect(readProductPolicy({ APPLE_ALLOW_SANDBOX: "true" }).allowSandbox).toBe(true);
    expect(readProductPolicy({ APPLE_ALLOW_SANDBOX: "false" }).allowSandbox).toBe(false);
    expect(readProductPolicy({ APPLE_ALLOW_SANDBOX: " FALSE " }).allowSandbox).toBe(false);
  });

  test("a value nobody can read fails loudly instead of silently staying open", () => {
    expect(() => readProductPolicy({ APPLE_ALLOW_SANDBOX: "flase" })).toThrow();
  });
});

describe("a Sandbox subscription on a server that refuses the Sandbox", () => {
  test("does not give mazl+", async () => {
    const repository = new InMemorySubscriptions();
    const transactions = verifierWith(false);
    const signed = signedByPki(pki, subscription("Sandbox"));
    expect(await reasonOf(() => verifyApplePurchase({ transactions, repository }, 7, signed))).toBe("sandbox_not_allowed");
    expect(repository.rows.size).toBe(0);
  });

  test("a Production transaction still works", async () => {
    const repository = new InMemorySubscriptions();
    const signed = signedByPki(pki, subscription("Production"));
    const result = await verifyApplePurchase({ transactions: verifierWith(false), repository }, 7, signed);
    expect(result.status).toBe("active");
  });

  test("a Sandbox notification is refused as well (no state is touched)", async () => {
    const repository = new InMemorySubscriptions();
    const transactions = verifierWith(false);
    const signedTransactionInfo = signedByPki(pki, subscription("Sandbox"));
    const signedPayload = signedByPki(pki, { notificationType: "DID_RENEW", data: { signedTransactionInfo } });
    expect(await reasonOf(() => handleAppleNotification({ transactions, repository }, signedPayload))).toBe("sandbox_not_allowed");
  });

  test("answers 422 invalid_transaction over HTTP, like every other refusal", async () => {
    const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
      c.set("userId", 7);
      await next();
    });
    const app = new Hono<{ Variables: AppVariables }>();
    registerSubscriptionsRoutes(app, { authenticate, transactions: verifierWith(false), repository: new InMemorySubscriptions() });
    const res = await app.request("/api/subscriptions/apple/verify", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ signedTransaction: signedByPki(pki, subscription("Sandbox")) }),
    });
    expect(res.status).toBe(422);
    expect(await res.json()).toEqual({ success: false, error: "invalid_transaction" });
  });
});

describe("a Sandbox consumable on a server that refuses the Sandbox", () => {
  function creditsWith(allowSandbox: boolean | undefined): { service: CreditsService; repository: InMemoryCredits } {
    const repository = new InMemoryCredits();
    const service = new CreditsService({ repository, plus: new FakePlusStatus(), transactions: verifierWith(allowSandbox) });
    return { service, repository };
  }

  test("credits nothing", async () => {
    const { service, repository } = creditsWith(false);
    const signed = signedByPki(pki, consumable("Sandbox"));
    expect(await reasonOf(() => service.verifyPurchase(7, signed))).toBe("sandbox_not_allowed");
    expect(repository.balance(7, "boost")).toBe(0);
    expect(repository.purchases.size).toBe(0);
  });

  test("a Production consumable is credited", async () => {
    const { service, repository } = creditsWith(false);
    const result = await service.verifyPurchase(7, signedByPki(pki, consumable("Production")));
    expect(result.credited).toBe(true);
    expect(repository.balance(7, "boost")).toBe(3);
  });
});

describe("the default keeps the Sandbox open (App Review buys in the Sandbox)", () => {
  test("a Sandbox subscription gives mazl+ when allowSandbox is true or unset", async () => {
    for (const allow of [true, undefined]) {
      const repository = new InMemorySubscriptions();
      const result = await verifyApplePurchase({ transactions: verifierWith(allow), repository }, 7, signedByPki(pki, subscription("Sandbox")));
      expect(result.status).toBe("active");
    }
  });

  test("a Sandbox consumable is credited when allowSandbox is true or unset", async () => {
    for (const allow of [true, undefined]) {
      const repository = new InMemoryCredits();
      const service = new CreditsService({ repository, plus: new FakePlusStatus(), transactions: verifierWith(allow) });
      expect((await service.verifyPurchase(7, signedByPki(pki, consumable("Sandbox")))).credited).toBe(true);
    }
  });
});
