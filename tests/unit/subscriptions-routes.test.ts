import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";
import { AppleJwsVerifier } from "../../src/features/subscriptions/infra/apple-jws-verifier";
import { registerSubscriptionsRoutes } from "../../src/features/subscriptions/presentation/subscriptions.routes";
import type { AppVariables } from "../../src/shared/http/middleware";
import { InMemorySubscriptions } from "./support/subscriptions-fakes";
import { createTestPki, signedByPki, withTamperedPayload, type TestPki } from "./support/apple-test-pki";

// End to end through HTTP with a real (throwaway) certificate chain, so the
// JWS, the chain and the policy checks all run for real.

const DAY = 24 * 60 * 60 * 1000;
const BUNDLE = "com.mazl.app";
const PRODUCT = "com.mazl.app.plus.1m";

let pki: TestPki;
let untrusted: TestPki;
let repository: InMemorySubscriptions;
let app: Hono<{ Variables: AppVariables }>;

function transaction(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    bundleId: BUNDLE,
    productId: PRODUCT,
    originalTransactionId: "3000000000001",
    transactionId: "3000000000002",
    originalPurchaseDate: Date.now() - DAY,
    expiresDate: Date.now() + 30 * DAY,
    environment: "Sandbox",
    ...overrides,
  };
}

beforeAll(async () => {
  [pki, untrusted] = await Promise.all([createTestPki(), createTestPki()]);
});

beforeEach(() => {
  repository = new InMemorySubscriptions();
  const transactions = new TransactionVerifier(new AppleJwsVerifier(pki.rootDer), { bundleId: BUNDLE, productIds: [PRODUCT] });
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const id = Number(c.req.header("x-test-user"));
    if (!Number.isInteger(id)) return c.json({ success: false, error: "Invalid token" }, 401);
    c.set("userId", id);
    await next();
  });
  app = new Hono<{ Variables: AppVariables }>();
  registerSubscriptionsRoutes(app, { authenticate, transactions, repository });
});

async function post(path: string, body: unknown, user?: number): Promise<Response> {
  return await app.request(path, {
    method: "POST",
    headers: { "content-type": "application/json", ...(user === undefined ? {} : { "x-test-user": String(user) }) },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

describe("POST /api/subscriptions/apple/verify", () => {
  test("requires authentication", async () => {
    const res = await post("/api/subscriptions/apple/verify", { signedTransaction: signedByPki(pki, transaction()) });
    expect(res.status).toBe(401);
  });

  test("200 with the subscription for a genuine transaction", async () => {
    const expiresDate = Date.now() + 30 * DAY;
    const res = await post("/api/subscriptions/apple/verify", { signedTransaction: signedByPki(pki, transaction({ expiresDate })) }, 11);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({
      success: true,
      subscription: { plan_type: "monthly", status: "active", expires_at: new Date(expiresDate).toISOString(), product_id: PRODUCT },
    });
    expect(repository.rows.get(11)?.originalTransactionId).toBe("3000000000001");
  });

  test("400 invalid_body when the body is not the expected shape", async () => {
    for (const body of ["not json", {}, { signedTransaction: 42 }, { signedTransaction: "" }, { signedTransaction: "a".repeat(20 * 1024 + 1) }]) {
      const res = await post("/api/subscriptions/apple/verify", body, 11);
      expect(res.status).toBe(400);
      expect(await res.json()).toEqual({ success: false, error: "invalid_body" });
    }
  });

  test("422 invalid_transaction for a chain that does not lead to the trusted root", async () => {
    const res = await post("/api/subscriptions/apple/verify", { signedTransaction: signedByPki(untrusted, transaction()) }, 11);
    expect(res.status).toBe(422);
    expect(await res.json()).toEqual({ success: false, error: "invalid_transaction" });
    expect(repository.rows.size).toBe(0);
  });

  test("422 invalid_transaction for a tampered payload", async () => {
    const signed = withTamperedPayload(signedByPki(pki, transaction()), transaction({ expiresDate: Date.now() + 900 * DAY }));
    const res = await post("/api/subscriptions/apple/verify", { signedTransaction: signed }, 11);
    expect(res.status).toBe(422);
    expect(await res.json()).toEqual({ success: false, error: "invalid_transaction" });
  });

  test("422 invalid_transaction for an expired or revoked transaction", async () => {
    for (const overrides of [{ expiresDate: Date.now() - DAY }, { revocationDate: Date.now() - DAY }]) {
      const res = await post("/api/subscriptions/apple/verify", { signedTransaction: signedByPki(pki, transaction(overrides)) }, 11);
      expect(res.status).toBe(422);
    }
  });

  test("409 transaction_owned_by_another_user when another account already holds it", async () => {
    const body = { signedTransaction: signedByPki(pki, transaction()) };
    expect((await post("/api/subscriptions/apple/verify", body, 11)).status).toBe(200);
    const res = await post("/api/subscriptions/apple/verify", body, 12);
    expect(res.status).toBe(409);
    expect(await res.json()).toEqual({ success: false, error: "transaction_owned_by_another_user" });
  });
});

describe("POST /api/subscriptions/apple/notifications", () => {
  async function subscribe(overrides: Record<string, unknown> = {}): Promise<void> {
    await post("/api/subscriptions/apple/verify", { signedTransaction: signedByPki(pki, transaction(overrides)) }, 11);
  }

  function notificationBody(type: string, tx: Record<string, unknown>, chain: TestPki = pki): { signedPayload: string } {
    return {
      signedPayload: signedByPki(chain, {
        notificationType: type,
        notificationUUID: "00000000-0000-4000-8000-000000000002",
        data: { environment: "Sandbox", bundleId: BUNDLE, signedTransactionInfo: signedByPki(chain, tx) },
      }),
    };
  }

  test("is public (no authentication) and applies a refund", async () => {
    await subscribe();
    const res = await post("/api/subscriptions/apple/notifications", notificationBody("REFUND", transaction({ revocationDate: Date.now() })));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true });
    expect(repository.rows.get(11)?.status).toBe("revoked");
  });

  test("applies an expiry", async () => {
    // Apple's EXPIRED carries the expiry of the period that ended: the stored one.
    const periodEnd = Date.now() + 30 * DAY;
    await subscribe({ expiresDate: periodEnd });
    const res = await post("/api/subscriptions/apple/notifications", notificationBody("EXPIRED", transaction({ expiresDate: periodEnd })));
    expect(res.status).toBe(200);
    expect(repository.rows.get(11)?.status).toBe("expired");
  });

  test("acknowledges an unknown transaction", async () => {
    const res = await post("/api/subscriptions/apple/notifications", notificationBody("DID_RENEW", transaction({ originalTransactionId: "404" })));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, ignored: "unknown_transaction" });
  });

  test("422 for a payload signed by an untrusted chain, and nothing changes", async () => {
    await subscribe();
    const res = await post("/api/subscriptions/apple/notifications", notificationBody("REFUND", transaction(), untrusted));
    expect(res.status).toBe(422);
    expect(await res.json()).toEqual({ success: false, error: "invalid_transaction" });
    expect(repository.rows.get(11)?.status).toBe("active");
  });

  test("400 invalid_body without a signedPayload", async () => {
    const res = await post("/api/subscriptions/apple/notifications", { nope: true });
    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({ success: false, error: "invalid_body" });
  });
});
