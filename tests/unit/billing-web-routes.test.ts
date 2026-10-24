import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import Stripe from "stripe";
import { CatalogService } from "../../src/features/billing-web/application/catalog-service";
import { CheckoutService, PortalService } from "../../src/features/billing-web/application/checkout-service";
import { StatusService } from "../../src/features/billing-web/application/status-service";
import { SubscriptionSync } from "../../src/features/billing-web/application/subscription-sync";
import { WebhookService } from "../../src/features/billing-web/application/webhook-service";
import { createBillingWeb, registerBillingWeb } from "../../src/features/billing-web/billing-web.module";
import { StripeWebhookVerifier } from "../../src/features/billing-web/infra/stripe-webhook-verifier";
import type { AppVariables } from "../../src/shared/http/middleware";
import { InMemoryCredits } from "./support/credits-fakes";
import { FakeGateway, InMemoryBilling, SETTINGS, subscriptionView } from "./support/billing-fakes";

const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
  const token = c.req.header("authorization");
  if (token === undefined) return c.json({ success: false, error: "No token provided" }, 401);
  c.set("userId", Number(token.replace("Bearer ", "")));
  await next();
});
const as = (userId: number): Record<string, string> => ({ authorization: `Bearer ${userId}`, "content-type": "application/json" });

const secret = "whsec_test_routes";
const stripe = new Stripe("sk_test_routes");

function build() {
  const gateway = new FakeGateway();
  const repository = new InMemoryBilling();
  const credits = new InMemoryCredits();
  for (const id of Object.values(SETTINGS.prices)) gateway.prices.set(id, { id, unitAmount: 1000, currency: "eur", taxBehavior: "inclusive" });
  const sync = new SubscriptionSync({ gateway, repository, settings: SETTINGS });
  const app = new Hono<{ Variables: AppVariables }>();
  registerBillingWeb(app, {
    authenticate,
    cancelSubscriptions: async () => undefined,
    services: {
      catalog: new CatalogService(gateway, SETTINGS, () => new Date()),
      checkout: new CheckoutService(gateway, repository, SETTINGS),
      portal: new PortalService(gateway, repository, SETTINGS),
      status: new StatusService(repository, sync, () => repository.now),
      webhook: new WebhookService({ verifier: new StripeWebhookVerifier(stripe, secret), repository, sync, credits }),
    },
  });
  return { app, gateway, repository };
}

const post = (app: Hono<{ Variables: AppVariables }>, path: string, body: unknown, headers = as(1)) =>
  app.request(path, { method: "POST", headers, body: typeof body === "string" ? body : JSON.stringify(body) });

describe("billing routes", () => {
  test("catalogue is public and carries the withdrawal text", async () => {
    const response = await build().app.request("/api/billing/catalog");
    const body = (await response.json()) as { success: boolean; available: boolean; offers: unknown[]; withdrawal: { version: string } };
    expect(response.status).toBe(200);
    expect(body).toMatchObject({ success: true, available: true, withdrawal: { version: "2026-10-24" } });
    expect(body.offers).toHaveLength(8);
  });

  test("the authenticated routes refuse an anonymous call", async () => {
    const { app } = build();
    expect((await app.request("/api/billing/status")).status).toBe(401);
    expect((await post(app, "/api/billing/checkout", {}, {})).status).toBe(401);
    expect((await post(app, "/api/billing/portal", {}, {})).status).toBe(401);
  });

  test("checkout: invalid body, missing waiver, then success", async () => {
    const { app } = build();
    expect((await post(app, "/api/billing/checkout", "{not json")).status).toBe(400);
    const unknown = await post(app, "/api/billing/checkout", { offer: "plus_2m", withdrawal_waiver: true, waiver_version: "2026-10-24" });
    expect(await unknown.json()).toEqual({ success: false, error: "invalid_body" });
    const wrongType = await post(app, "/api/billing/checkout", { offer: "plus_3m", withdrawal_waiver: "yes" });
    expect(wrongType.status).toBe(400);
    const missing = await post(app, "/api/billing/checkout", { offer: "plus_3m" });
    expect([missing.status, await missing.json()]).toEqual([400, { success: false, error: "withdrawal_waiver_required" }]);
    const staleVersion = await post(app, "/api/billing/checkout", { offer: "plus_3m", withdrawal_waiver: true, waiver_version: "2020-01-01" });
    expect(((await staleVersion.json()) as { error: string }).error).toBe("withdrawal_waiver_required");
    const ok = await post(app, "/api/billing/checkout", { offer: "plus_3m", withdrawal_waiver: true, waiver_version: "2026-10-24" });
    expect([ok.status, await ok.json()]).toEqual([200, { success: true, url: "https://checkout.stripe.test/cs_1" }]);
  });

  test("checkout: 409 already_subscribed with the source", async () => {
    const { app, repository } = build();
    repository.setApple(1, new Date("2027-01-01T00:00:00Z"));
    const response = await post(app, "/api/billing/checkout", { offer: "plus_1m", withdrawal_waiver: true, waiver_version: "2026-10-24" });
    expect([response.status, await response.json()]).toEqual([409, { success: false, error: "already_subscribed", source: "apple" }]);
  });

  test("checkout is limited to 10 per hour and per member", async () => {
    const { app } = build();
    const body = { offer: "boost_1", withdrawal_waiver: true, waiver_version: "2026-10-24" };
    for (let i = 0; i < 10; i++) expect((await post(app, "/api/billing/checkout", body)).status).toBe(200);
    expect((await post(app, "/api/billing/checkout", body)).status).toBe(429);
    expect((await post(app, "/api/billing/checkout", body, as(2))).status).toBe(200);
  });

  test("portal: 404 no_customer, then the portal URL", async () => {
    const { app, repository } = build();
    const none = await post(app, "/api/billing/portal", {});
    expect([none.status, await none.json()]).toEqual([404, { success: false, error: "no_customer" }]);
    await repository.saveCustomer(1, "cus_1");
    expect(await (await post(app, "/api/billing/portal", {})).json()).toEqual({ success: true, url: "https://billing.stripe.test/portal" });
  });

  test("status is served to the member", async () => {
    const { app } = build();
    const response = await app.request("/api/billing/status", { headers: as(1) });
    expect(await response.json()).toMatchObject({ success: true, plus: { active: false }, can_subscribe: true });
  });

  test("an upstream Stripe failure is a 502 that leaks nothing", async () => {
    const { app, gateway } = build();
    gateway.prices.clear();
    const response = await app.request("/api/billing/catalog");
    expect([response.status, await response.json()]).toEqual([502, { success: false, error: "billing_upstream_error" }]);
  });
});

describe("webhook route", () => {
  const event = JSON.stringify({ id: "evt_r1", object: "event", type: "customer.subscription.updated", livemode: false, created: 1_790_000_000, data: { object: { id: "sub_1", object: "subscription" } } });
  const signed = async (body: string): Promise<Record<string, string>> => ({
    "stripe-signature": await stripe.webhooks.generateTestHeaderStringAsync({ payload: body, secret }),
    "content-type": "application/json",
  });

  test("bad signature: 400 invalid_signature; no header: 400", async () => {
    const { app } = build();
    const forged = await post(app, "/api/billing/stripe/webhook", event, { "stripe-signature": "t=1,v1=00", "content-type": "application/json" });
    expect([forged.status, await forged.json()]).toEqual([400, { success: false, error: "invalid_signature" }]);
    expect((await post(app, "/api/billing/stripe/webhook", event, {})).status).toBe(400);
  });

  test("the raw body is what is verified: a re-serialised body does not pass", async () => {
    const { app } = build();
    const headers = await signed(event);
    const spaced = JSON.stringify(JSON.parse(event), null, 2);
    expect((await post(app, "/api/billing/stripe/webhook", spaced, headers)).status).toBe(400);
  });

  test("processed, then duplicate; a processing error is a 500 that is retried", async () => {
    const { app, gateway, repository } = build();
    const headers = await signed(event);
    const failing = await post(app, "/api/billing/stripe/webhook", event, headers);
    expect(failing.status).toBe(500);
    expect(repository.events.get("evt_r1")).toBe(false);
    gateway.subscriptions.set("sub_1", subscriptionView());
    const first = await post(app, "/api/billing/stripe/webhook", event, headers);
    expect([first.status, await first.json()]).toEqual([200, { received: true }]);
    const again = await post(app, "/api/billing/stripe/webhook", event, headers);
    expect([again.status, await again.json()]).toEqual([200, { received: true, duplicate: true }]);
    expect(repository.entitlements.get(1)?.live).toBe(true);
  });

  test("a body over 256 KB is refused before any parsing", async () => {
    const { app } = build();
    const big = JSON.stringify({ pad: "x".repeat(300 * 1024) });
    const response = await post(app, "/api/billing/stripe/webhook", big, { "content-type": "application/json", "content-length": String(big.length) });
    expect(response.status).toBe(413);
  });
});

describe("module without a Stripe key", () => {
  const app = new Hono<{ Variables: AppVariables }>();
  registerBillingWeb(app, createBillingWeb({ sql: {} as never, authenticate, env: {} }));

  test("the catalogue answers 200 available:false, the others 503 billing_unavailable", async () => {
    const catalog = await app.request("/api/billing/catalog");
    expect([catalog.status, await catalog.json()]).toMatchObject([200, { success: true, available: false, offers: [] }]);
    for (const [method, path] of [["GET", "/api/billing/status"], ["POST", "/api/billing/checkout"], ["POST", "/api/billing/portal"]] as const) {
      const response = await app.request(path, { method, headers: as(1), body: method === "POST" ? "{}" : undefined });
      expect([response.status, await response.json()]).toEqual([503, { success: false, error: "billing_unavailable" }]);
    }
    const hook = await app.request("/api/billing/stripe/webhook", { method: "POST", body: "{}" });
    expect(hook.status).toBe(503);
  });

  test("account erasure still works without a key", async () => {
    const billing = createBillingWeb({ sql: {} as never, authenticate, env: {} });
    await billing.cancelSubscriptions(1);
  });
});

