import { describe, expect, test } from "bun:test";
import Stripe from "stripe";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";
import { FakeStripeClient } from "./support/fake-stripe-client";

// Needs the server (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_API_BASE and the
// STRIPE_PRICE_* of FAKE_PRICE_ENV) and the fake Stripe (run-fake-stripe.ts) running.
const fakeUrl = process.env.FAKE_STRIPE_URL ?? "http://127.0.0.1:12113";
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET ?? "";
const fake = new FakeStripeClient(fakeUrl);
const signer = new Stripe("sk_test_signer_only");
const WAIVER = { withdrawal_waiver: true, waiver_version: "2026-10-24" };
const PERIOD_END = Math.floor(Date.now() / 1000) + 90 * 86400;

const post = (user: TestUser, path: string, body: unknown) =>
  fetch(`${BASE_URL}${path}`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });
const get = (user: TestUser, path: string) => fetch(`${BASE_URL}${path}`, { headers: auth(user.token) });

async function webhook(type: string, object: Record<string, unknown>, options: { id?: string; timestamp?: number; secret?: string } = {}) {
  const payload = JSON.stringify({ id: options.id ?? `evt_${crypto.randomUUID()}`, object: "event", type, livemode: false, created: Math.floor(Date.now() / 1000), data: { object } });
  const signature = await signer.webhooks.generateTestHeaderStringAsync({
    payload, secret: options.secret ?? webhookSecret, ...(options.timestamp === undefined ? {} : { timestamp: options.timestamp }),
  });
  const response = await fetch(`${BASE_URL}/api/billing/stripe/webhook`, { method: "POST", headers: { "stripe-signature": signature, "content-type": "application/json" }, body: payload });
  return { status: response.status, body: (await response.json()) as Record<string, unknown>, payload, signature };
}

async function customerOf(user: TestUser): Promise<string> {
  const rows = await db<{ customer_id: string }[]>`SELECT customer_id FROM stripe_customers WHERE user_id = ${user.id}`;
  const id = rows[0]?.customer_id;
  if (id === undefined) throw new Error("no customer");
  return id;
}

async function memberWithCustomer(label: string): Promise<TestUser> {
  const user = await makeUser(label);
  expect((await post(user, "/api/billing/checkout", { offer: "boost_1", ...WAIVER })).status).toBe(200);
  return user;
}

async function stripeSubscription(user: TestUser, id: string, overrides: Record<string, unknown> = {}): Promise<void> {
  await fake.setSubscription({
    id, customer: await customerOf(user), price: "price_test_plus_3m", status: "active", current_period_end: PERIOD_END,
    metadata: { user_id: String(user.id), offer: "plus_3m" }, ...overrides,
  });
}

const completedSubscription = (user: TestUser, subscription: string) => ({
  id: "cs_test_sub", object: "checkout.session", mode: "subscription", payment_status: "paid", client_reference_id: String(user.id),
  metadata: { user_id: String(user.id), offer: "plus_3m" }, subscription, payment_intent: null, created: Math.floor(Date.now() / 1000),
});
const completedPack = (user: TestUser, offer: string, paymentIntent: string) => ({
  id: `cs_test_${paymentIntent}`, object: "checkout.session", mode: "payment", payment_status: "paid", client_reference_id: String(user.id),
  metadata: { user_id: String(user.id), offer }, subscription: null, payment_intent: paymentIntent, created: Math.floor(Date.now() / 1000),
});

const credits = async (user: TestUser) => ((await (await get(user, "/api/credits")).json()) as { credits: Record<string, Record<string, number>> }).credits;

describe("catalogue and checkout", () => {
  test("the catalogue is public, TTC amounts come from Stripe", async () => {
    const response = await fetch(`${BASE_URL}/api/billing/catalog`);
    const body = (await response.json()) as { available: boolean; offers: { id: string; amount_ttc_cents: number; featured: boolean }[]; withdrawal: { version: string } };
    expect(response.status).toBe(200);
    expect(body.available).toBe(true);
    expect(body.offers.find((o) => o.id === "plus_3m")).toMatchObject({ amount_ttc_cents: 2499, featured: true });
    expect(body.withdrawal.version).toBe("2026-10-24");
  });

  test("authentication is required", async () => {
    expect((await fetch(`${BASE_URL}/api/billing/status`)).status).toBe(401);
    expect((await fetch(`${BASE_URL}/api/billing/checkout`, { method: "POST" })).status).toBe(401);
  });

  test("a checkout without the waiver is refused and leaves no trace", async () => {
    const user = await makeUser("nowaiver");
    for (const body of [{ offer: "plus_3m" }, { offer: "plus_3m", withdrawal_waiver: false, waiver_version: "2026-10-24" }, { offer: "plus_3m", withdrawal_waiver: true, waiver_version: "old" }]) {
      const response = await post(user, "/api/billing/checkout", body);
      expect([response.status, ((await response.json()) as { error: string }).error]).toEqual([400, "withdrawal_waiver_required"]);
    }
    expect((await post(user, "/api/billing/checkout", { offer: "nope", ...WAIVER })).status).toBe(400);
    expect(await db`SELECT 1 FROM billing_withdrawal_waivers WHERE user_id = ${user.id}`).toHaveLength(0);
    expect(await db`SELECT 1 FROM stripe_customers WHERE user_id = ${user.id}`).toHaveLength(0);
  });

  test("a checkout returns the Stripe URL and stores the proof with the session", async () => {
    const user = await makeUser("checkout");
    const response = await post(user, "/api/billing/checkout", { offer: "plus_3m", ...WAIVER });
    const body = (await response.json()) as { success: boolean; url: string };
    expect(response.status).toBe(200);
    expect(body.url).toStartWith("https://checkout.stripe.test/c/pay/cs_test_fake_");
    const [waiver] = await db<{ offer: string; text_version: string; text_sha256: string; checkout_session_id: string; accepted_at: Date }[]>`
      SELECT offer, text_version, text_sha256, checkout_session_id, accepted_at FROM billing_withdrawal_waivers WHERE user_id = ${user.id}
    `;
    expect(waiver).toMatchObject({ offer: "plus_3m", text_version: "2026-10-24" });
    expect(waiver?.text_sha256).toMatch(/^[0-9a-f]{64}$/);
    expect(body.url).toEndWith(waiver?.checkout_session_id ?? "missing");
    const sent = (await fake.requests()).filter((r) => r.path === "/v1/checkout/sessions" && r.params.client_reference_id === String(user.id));
    expect(sent).toHaveLength(1);
    expect(sent[0]?.params).toMatchObject({ mode: "subscription", "line_items[0][price]": "price_test_plus_3m", "subscription_data[metadata][user_id]": String(user.id) });
    const second = await post(user, "/api/billing/checkout", { offer: "boost_3", ...WAIVER });
    expect(second.status).toBe(200);
    const customers = (await fake.requests()).filter((r) => r.path === "/v1/customers" && r.params["metadata[user_id]"] === String(user.id));
    expect(customers).toHaveLength(1);
  });

  test("the portal needs a customer", async () => {
    const user = await makeUser("portal");
    expect((await post(user, "/api/billing/portal", {})).status).toBe(404);
    await memberWithCustomerFor(user);
    const response = await post(user, "/api/billing/portal", {});
    expect(((await response.json()) as { url: string }).url).toStartWith("https://billing.stripe.test/p/session/");
  });
});

async function memberWithCustomerFor(user: TestUser): Promise<void> {
  expect((await post(user, "/api/billing/checkout", { offer: "boost_1", ...WAIVER })).status).toBe(200);
}

describe("webhook", () => {
  test("a forged signature, a wrong secret and a stale timestamp are refused", async () => {
    const forged = await fetch(`${BASE_URL}/api/billing/stripe/webhook`, { method: "POST", headers: { "stripe-signature": "t=1,v1=abcd" }, body: "{}" });
    expect([forged.status, ((await forged.json()) as { error: string }).error]).toEqual([400, "invalid_signature"]);
    expect((await webhook("customer.created", { id: "cus_x" }, { secret: "whsec_test_wrong" })).status).toBe(400);
    expect((await webhook("customer.created", { id: "cus_x" }, { timestamp: Math.floor(Date.now() / 1000) - 400 })).status).toBe(400);
    expect((await webhook("customer.created", { id: "cus_x" })).status).toBe(200);
  });

  test("a signed subscription checkout activates mazl+; the replay is a duplicate", async () => {
    const user = await memberWithCustomer("sub");
    expect((await credits(user)).super_like?.daily_allowance).toBe(1);
    await stripeSubscription(user, `sub_${user.id}`);
    const first = await webhook("checkout.session.completed", completedSubscription(user, `sub_${user.id}`));
    expect([first.status, first.body]).toEqual([200, { received: true }]);
    expect((await credits(user)).super_like?.daily_allowance).toBe(5);
    const status = (await (await get(user, "/api/billing/status")).json()) as Record<string, any>;
    expect(status.plus).toMatchObject({ active: true, source: "stripe", plan_type: "three_month" });
    expect(status.stripe.subscription).toMatchObject({ offer: "plus_3m", status: "active", cancel_at_period_end: false });
    expect(status).toMatchObject({ can_subscribe: false, blocked_reason: "stripe_active", conflict: null });
    const [row] = await db<{ store: string; original_transaction_id: string; product_id: string }[]>`SELECT store, original_transaction_id, product_id FROM subscriptions WHERE user_id = ${user.id}`;
    expect(row).toEqual({ store: "stripe", original_transaction_id: `sub_${user.id}`, product_id: "com.mazl.app.plus.3m" });
    const replay = await fetch(`${BASE_URL}/api/billing/stripe/webhook`, { method: "POST", headers: { "stripe-signature": first.signature, "content-type": "application/json" }, body: first.payload });
    expect([replay.status, await replay.json()]).toEqual([200, { received: true, duplicate: true }]);
    expect(await db`SELECT 1 FROM stripe_events WHERE event_id = ${JSON.parse(first.payload).id}`).toHaveLength(1);
    // The member cannot buy a second one.
    const again = await post(user, "/api/billing/checkout", { offer: "plus_1m", ...WAIVER });
    expect([again.status, ((await again.json()) as Record<string, string>).source]).toEqual([409, "stripe"]);
  });

  test("a cancellation event ends mazl+", async () => {
    const user = await memberWithCustomer("cancel");
    await stripeSubscription(user, `sub_c${user.id}`);
    await webhook("checkout.session.completed", completedSubscription(user, `sub_c${user.id}`));
    await stripeSubscription(user, `sub_c${user.id}`, { status: "canceled" });
    await webhook("customer.subscription.deleted", { id: `sub_c${user.id}`, object: "subscription" });
    expect((await credits(user)).super_like?.daily_allowance).toBe(1);
    const [row] = await db<{ status: string }[]>`SELECT status FROM subscriptions WHERE user_id = ${user.id}`;
    expect(row?.status).toBe("expired");
  });

  test("a pack credits once per PaymentIntent and a full refund takes it back", async () => {
    const user = await memberWithCustomer("pack");
    const pi = `pi_${crypto.randomUUID().slice(0, 20)}`;
    expect((await webhook("checkout.session.completed", completedPack(user, "superlikes_15", pi))).status).toBe(200);
    expect((await credits(user)).super_like?.purchased_balance).toBe(15);
    expect((await webhook("checkout.session.completed", completedPack(user, "superlikes_15", pi))).status).toBe(200);
    expect((await webhook("checkout.session.async_payment_succeeded", completedPack(user, "superlikes_15", pi))).status).toBe(200);
    expect((await credits(user)).super_like?.purchased_balance).toBe(15);
    await webhook("charge.refunded", { id: "ch_1", object: "charge", refunded: true, payment_intent: pi, metadata: { offer: "superlikes_15" } });
    expect((await credits(user)).super_like?.purchased_balance).toBe(0);
  });
});

describe("Apple and Stripe on one row", () => {
  const appleRow = async (user: TestUser, expires: string) => {
    await db`
      INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
      VALUES (${user.id}, 'yearly', 'active', 'apple', 'com.mazl.app.plus.12m', ${`20000${user.id}`}, NOW(), ${expires}::timestamp)
    `;
  };

  test("an Apple mazl+ in force refuses the web checkout and is never overwritten", async () => {
    const user = await memberWithCustomer("apple");
    await appleRow(user, "2099-01-01T00:00:00Z");
    const refused = await post(user, "/api/billing/checkout", { offer: "plus_1m", ...WAIVER });
    expect([refused.status, await refused.json()]).toEqual([409, { success: false, error: "already_subscribed", source: "apple" }]);
    // Paid anyway (an App Store purchase between the click and the payment):
    // the new Stripe subscription is the duplicate, cancelled and refunded.
    await stripeSubscription(user, `sub_a${user.id}`);
    await webhook("checkout.session.completed", completedSubscription(user, `sub_a${user.id}`));
    const [row] = await db<{ store: string; original_transaction_id: string }[]>`SELECT store, original_transaction_id FROM subscriptions WHERE user_id = ${user.id}`;
    expect(row).toEqual({ store: "apple", original_transaction_id: `20000${user.id}` });
    const requests = await fake.requests();
    expect(requests.filter((r) => r.method === "DELETE" && r.path === `/v1/subscriptions/sub_a${user.id}`)).toHaveLength(1);
    expect(requests.filter((r) => r.path === "/v1/refunds" && r.params.payment_intent === `pi_sub_a${user.id}`)).toHaveLength(1);
    const status = (await (await get(user, "/api/billing/status")).json()) as Record<string, any>;
    expect(status).toMatchObject({ conflict: null, blocked_reason: "apple_active" });
    expect(status.plus.source).toBe("apple");
  });

  test("an expired Apple row is replaced, and a late event of an old subscription does not undo the new one", async () => {
    const user = await memberWithCustomer("lateold");
    await appleRow(user, "2020-01-01T00:00:00Z");
    await stripeSubscription(user, `sub_new${user.id}`);
    await webhook("checkout.session.completed", completedSubscription(user, `sub_new${user.id}`));
    await stripeSubscription(user, `sub_old${user.id}`, { status: "canceled" });
    await webhook("customer.subscription.deleted", { id: `sub_old${user.id}`, object: "subscription" });
    const [row] = await db<{ store: string; status: string; original_transaction_id: string }[]>`SELECT store, status, original_transaction_id FROM subscriptions WHERE user_id = ${user.id}`;
    expect(row).toEqual({ store: "stripe", status: "active", original_transaction_id: `sub_new${user.id}` });
  });
});

describe("account deletion", () => {
  test("the Stripe subscription is cancelled at Stripe and the waiver proof outlives the member", async () => {
    const user = await memberWithCustomer("erase");
    await stripeSubscription(user, `sub_e${user.id}`);
    await webhook("checkout.session.completed", completedSubscription(user, `sub_e${user.id}`));
    const proofs = (await db<{ id: number }[]>`SELECT id FROM billing_withdrawal_waivers WHERE user_id = ${user.id}`).map((r) => r.id);
    expect(proofs.length).toBeGreaterThan(0);
    const response = await fetch(`${BASE_URL}/api/users/me`, { method: "DELETE", headers: json(user.token), body: JSON.stringify({}) });
    expect(response.status).toBe(200);
    const deletes = (await fake.requests()).filter((r) => r.method === "DELETE" && r.path === `/v1/subscriptions/sub_e${user.id}`);
    expect(deletes).toHaveLength(1);
    expect(await db`SELECT 1 FROM users WHERE id = ${user.id}`).toHaveLength(0);
    expect(await db`SELECT 1 FROM stripe_subscriptions WHERE subscription_id = ${`sub_e${user.id}`}`).toHaveLength(0);
    const kept = await db<{ user_id: number | null; text_sha256: string }[]>`
      SELECT user_id, text_sha256 FROM billing_withdrawal_waivers WHERE id IN ${db(proofs)}
    `;
    expect(kept).toHaveLength(proofs.length);
    for (const proof of kept) expect(proof.user_id).toBeNull();
  });
});

describe("no double mazl+ from the web (security review M2)", () => {
  test("a second subscription checkout expires the first one, still open in another tab", async () => {
    const user = await makeUser("two-tabs");
    const first = (await (await post(user, "/api/billing/checkout", { offer: "plus_1m", ...WAIVER })).json()) as { url: string };
    const second = await post(user, "/api/billing/checkout", { offer: "plus_12m", ...WAIVER });
    expect(second.status).toBe(200);
    const firstId = first.url.split("/").at(-1) ?? "";
    const expired = (await fake.requests()).filter((r) => r.method === "POST" && r.path === `/v1/checkout/sessions/${firstId}/expire`);
    expect(expired).toHaveLength(1);
  });

  test("a second paid subscription of the same member is cancelled and refunded; the first one stays", async () => {
    const user = await memberWithCustomer("double-paid");
    const first = `sub_first_${user.id}`;
    const second = `sub_second_${user.id}`;
    await stripeSubscription(user, first, { start_date: Math.floor(Date.now() / 1000) - 60 });
    await stripeSubscription(user, second, { start_date: Math.floor(Date.now() / 1000) });
    expect((await webhook("checkout.session.completed", completedSubscription(user, first))).status).toBe(200);
    expect((await webhook("checkout.session.completed", completedSubscription(user, second))).status).toBe(200);
    const requests = await fake.requests();
    expect(requests.filter((r) => r.method === "DELETE" && r.path === `/v1/subscriptions/${second}`)).toHaveLength(1);
    expect(requests.filter((r) => r.method === "DELETE" && r.path === `/v1/subscriptions/${first}`)).toHaveLength(0);
    expect(requests.filter((r) => r.path === "/v1/refunds" && r.params.payment_intent === `pi_${second}`)).toHaveLength(1);
    const [row] = await db<{ original_transaction_id: string }[]>`SELECT original_transaction_id FROM subscriptions WHERE user_id = ${user.id}`;
    expect(row?.original_transaction_id).toBe(first);
  });
});
