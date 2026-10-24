import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { CreditsService } from "../../src/features/credits/application/credits-service";
import { registerCreditsRoutes } from "../../src/features/credits/presentation/credits.routes";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import { AppleJwsVerifier } from "../../src/features/subscriptions/infra/apple-jws-verifier";
import { registerSubscriptionsRoutes } from "../../src/features/subscriptions/presentation/subscriptions.routes";
import type { AppVariables } from "../../src/shared/http/middleware";
import { createTestPki, signedByPki, withTamperedPayload, type TestPki } from "./support/apple-test-pki";
import { FakePlusStatus, InMemoryCredits } from "./support/credits-fakes";
import { InMemorySubscriptions } from "./support/subscriptions-fakes";

// End to end through HTTP with a real (throwaway) certificate chain: the JWS,
// the chain and the policies run for real; only the storage is in memory.

const DAY = 24 * 60 * 60 * 1000;
const BUNDLE = "com.mazl.app";
const BOOST_3 = "com.mazl.app.boost.3";
const SUBSCRIPTION = "com.mazl.app.plus.1m";

let pki: TestPki;
let untrusted: TestPki;
let repository: InMemoryCredits;
let subscriptions: InMemorySubscriptions;
let plus: FakePlusStatus;
let service: CreditsService;
let app: Hono<{ Variables: AppVariables }>;

function consumable(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: BOOST_3,
    originalTransactionId: "8000000000001",
    transactionId: "8000000000001",
    purchaseDate: Date.now() - DAY,
    environment: "Sandbox",
    type: "Consumable",
    ...overrides,
  };
}

beforeAll(async () => {
  [pki, untrusted] = await Promise.all([createTestPki(), createTestPki()]);
});

beforeEach(() => {
  repository = new InMemoryCredits();
  subscriptions = new InMemorySubscriptions();
  plus = new FakePlusStatus();
  const transactions = new TransactionVerifier(new AppleJwsVerifier(pki.rootDer), { bundleId: BUNDLE, productIds: [SUBSCRIPTION] });
  service = new CreditsService({ repository, plus, transactions });
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const id = Number(c.req.header("x-test-user"));
    if (!Number.isInteger(id)) return c.json({ success: false, error: "Invalid token" }, 401);
    c.set("userId", id);
    await next();
  });
  app = new Hono<{ Variables: AppVariables }>();
  registerCreditsRoutes(app, { authenticate, credits: service });
  registerSubscriptionsRoutes(app, { authenticate, transactions, repository: subscriptions, consumables: service });
});

async function request(method: string, path: string, body?: unknown, user?: number): Promise<Response> {
  return await app.request(path, {
    method,
    headers: { "content-type": "application/json", ...(user === undefined ? {} : { "x-test-user": String(user) }) },
    ...(body === undefined ? {} : { body: typeof body === "string" ? body : JSON.stringify(body) }),
  });
}

const verify = (signedTransaction: unknown, user?: number): Promise<Response> =>
  request("POST", "/api/credits/apple/verify", { signedTransaction }, user);

describe("GET /api/credits", () => {
  test("requires authentication", async () => {
    expect((await request("GET", "/api/credits")).status).toBe(401);
  });

  test("returns the balance of the member", async () => {
    plus.plus.add(11);
    repository.setBalance(11, "boost", 2);
    const res = await request("GET", "/api/credits", undefined, 11);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({
      success: true,
      credits: {
        super_like: { daily_allowance: 5, daily_remaining: 5, purchased_balance: 0, available: 5 },
        boost: { daily_allowance: 1, daily_remaining: 1, purchased_balance: 2, available: 3 },
        resets_at: "2026-10-25T00:00:00.000Z",
      },
    });
  });
});

describe("POST /api/credits/apple/verify", () => {
  test("requires authentication", async () => {
    expect((await verify(signedByPki(pki, consumable()))).status).toBe(401);
  });

  test("200 credited true with the new balance for a genuine consumable", async () => {
    const res = await verify(signedByPki(pki, consumable()), 11);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; credited: boolean; kind: string; quantity: number; credits: { boost: { purchased_balance: number } } };
    expect(body).toMatchObject({ success: true, credited: true, kind: "boost", quantity: 3 });
    expect(body.credits.boost.purchased_balance).toBe(3);
  });

  test("200 credited false when the same transaction comes again, balance unchanged", async () => {
    const signed = signedByPki(pki, consumable());
    await verify(signed, 11);
    const res = await verify(signed, 11);
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ success: true, credited: false, kind: "boost", quantity: 3 });
    expect(repository.balance(11, "boost")).toBe(3);
  });

  test("409 transaction_owned_by_another_user", async () => {
    const signed = signedByPki(pki, consumable());
    await verify(signed, 11);
    const res = await verify(signed, 12);
    expect(res.status).toBe(409);
    expect(await res.json()).toEqual({ success: false, error: "transaction_owned_by_another_user" });
    expect(repository.balance(12, "boost")).toBe(0);
  });

  test("400 invalid_body when the body is not the expected shape", async () => {
    for (const body of ["not json", {}, { signedTransaction: 42 }, { signedTransaction: "" }, { signedTransaction: "a".repeat(20 * 1024 + 1) }]) {
      const res = await request("POST", "/api/credits/apple/verify", body, 11);
      expect(res.status).toBe(400);
      expect(await res.json()).toEqual({ success: false, error: "invalid_body" });
    }
  });

  const unprocessable: ReadonlyArray<readonly [string, Record<string, unknown>]> = [
    ["a subscription product", { productId: SUBSCRIPTION, type: "Auto-Renewable Subscription", expiresDate: Date.now() + DAY }],
    ["the wrong bundle", { bundleId: "com.evil.app" }],
    ["a revoked transaction", { revocationDate: Date.now() - 1000 }],
    ["a non-consumable type", { type: "Non-Consumable" }],
  ];
  for (const [label, overrides] of unprocessable) {
    test(`422 invalid_transaction for ${label}`, async () => {
      const res = await verify(signedByPki(pki, consumable(overrides)), 11);
      expect(res.status).toBe(422);
      expect(await res.json()).toEqual({ success: false, error: "invalid_transaction" });
      expect(repository.purchases.size).toBe(0);
    });
  }

  test("422 for a chain that does not lead to the trusted root", async () => {
    expect((await verify(signedByPki(untrusted, consumable()), 11)).status).toBe(422);
    expect(repository.purchases.size).toBe(0);
  });

  test("422 for a tampered payload", async () => {
    const tampered = withTamperedPayload(signedByPki(pki, consumable()), consumable({ productId: "com.mazl.app.superlikes.15" }));
    expect((await verify(tampered, 11)).status).toBe(422);
    expect(repository.purchases.size).toBe(0);
  });
});

describe("POST /api/subscriptions/apple/notifications for consumables", () => {
  function notification(type: string, tx: Record<string, unknown>, chain: TestPki = pki): { signedPayload: string } {
    return {
      signedPayload: signedByPki(chain, {
        notificationType: type,
        notificationUUID: "00000000-0000-4000-8000-000000000003",
        data: { environment: "Sandbox", bundleId: BUNDLE, signedTransactionInfo: signedByPki(chain, tx) },
      }),
    };
  }
  const notify = (type: string, tx: Record<string, unknown>, chain?: TestPki): Promise<Response> =>
    request("POST", "/api/subscriptions/apple/notifications", notification(type, tx, chain));

  test("REFUND takes the credits back once, whatever the number of replays", async () => {
    await verify(signedByPki(pki, consumable()), 11);
    for (let replay = 0; replay < 3; replay++) {
      const res = await notify("REFUND", consumable({ revocationDate: Date.now() }));
      expect(res.status).toBe(200);
      expect(await res.json()).toEqual({ success: true });
    }
    expect(repository.balance(11, "boost")).toBe(0);
    expect(repository.purchases.get("8000000000001")?.refunded).toBe(true);
  });

  test("REVOKE refunds too", async () => {
    await verify(signedByPki(pki, consumable()), 11);
    expect((await notify("REVOKE", consumable())).status).toBe(200);
    expect(repository.balance(11, "boost")).toBe(0);
  });

  test("a refund after the pack was spent leaves a negative balance, filled by the next purchase", async () => {
    await verify(signedByPki(pki, consumable({ productId: "com.mazl.app.boost.1" })), 11);
    await service.spend(11, "boost");
    await notify("REFUND", consumable({ productId: "com.mazl.app.boost.1" }));
    expect(repository.balance(11, "boost")).toBe(-1);

    await verify(signedByPki(pki, consumable({ transactionId: "8000000000002" })), 11);
    expect(repository.balance(11, "boost")).toBe(2);
  });

  test("CONSUMPTION_REQUEST answers 200 and changes nothing", async () => {
    await verify(signedByPki(pki, consumable()), 11);
    const res = await notify("CONSUMPTION_REQUEST", consumable());
    expect(res.status).toBe(200);
    expect(repository.balance(11, "boost")).toBe(3);
    expect(repository.purchases.get("8000000000001")?.refunded).toBe(false);
  });

  test("an unknown consumable answers 200 ignored, never 422", async () => {
    const res = await notify("REFUND", consumable({ transactionId: "never-seen" }));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, ignored: "unknown_transaction" });
  });

  test("a consumable without expiresDate never answers 422 for that reason", async () => {
    const res = await notify("REFUND", consumable({ expiresDate: undefined }));
    expect(res.status).toBe(200);
  });

  test("a payload signed by an untrusted chain is refused and refunds nothing", async () => {
    await verify(signedByPki(pki, consumable()), 11);
    expect((await notify("REFUND", consumable(), untrusted)).status).toBe(422);
    expect(repository.balance(11, "boost")).toBe(3);
  });

  test("a subscription notification still works next to the consumables", async () => {
    const subscription = {
      bundleId: BUNDLE,
      productId: SUBSCRIPTION,
      originalTransactionId: "3000000000001",
      transactionId: "3000000000002",
      originalPurchaseDate: Date.now() - DAY,
      expiresDate: Date.now() + 30 * DAY,
      environment: "Sandbox",
    };
    await request("POST", "/api/subscriptions/apple/verify", { signedTransaction: signedByPki(pki, subscription) }, 11);
    const res = await notify("REFUND", { ...subscription, revocationDate: Date.now() });
    expect(res.status).toBe(200);
    expect(subscriptions.rows.get(11)?.status).toBe("revoked");
  });
});
