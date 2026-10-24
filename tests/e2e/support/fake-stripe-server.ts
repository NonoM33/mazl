import Stripe from "stripe";
import { randomBytes } from "node:crypto";

// A stand-in for api.stripe.com in the e2e runs. It answers the real paths
// the server calls (form-encoded requests, Stripe-shaped JSON) and serves a
// test checkout page: « Payer » sends the signed webhook Stripe would send
// (signature made by the SDK's own generateTestHeaderString), then returns to
// success_url. Nothing leaves the machine.

export interface FakeStripe {
  readonly baseUrl: string;
  readonly webhookSecret: string;
  readonly priceEnv: Readonly<Record<string, string>>;
  stop(): void;
}

const PRICES: Readonly<Record<string, { amount: number; recurring: number | null }>> = {
  STRIPE_PRICE_PLUS_1M: { amount: 1999, recurring: 1 },
  STRIPE_PRICE_PLUS_3M: { amount: 4499, recurring: 3 },
  STRIPE_PRICE_PLUS_6M: { amount: 6999, recurring: 6 },
  STRIPE_PRICE_PLUS_12M: { amount: 9999, recurring: 12 },
  STRIPE_PRICE_BOOST_1: { amount: 799, recurring: null },
  STRIPE_PRICE_BOOST_3: { amount: 1999, recurring: null },
  STRIPE_PRICE_SUPERLIKES_5: { amount: 499, recurring: null },
  STRIPE_PRICE_SUPERLIKES_15: { amount: 1199, recurring: null },
};

type Form = Record<string, string>;
interface Session { id: string; mode: "payment" | "subscription"; customer: string; price: string; metadata: Form; clientReference: string; successUrl: string; cancelUrl: string; webhookUrl: string }

const id = (prefix: string) => `${prefix}_test_${randomBytes(8).toString("hex")}`;
const json = (body: unknown, status = 200) => Response.json(body, { status });

function metadataOf(form: Form, prefix: string): Form {
  const out: Form = {};
  for (const [key, value] of Object.entries(form)) {
    const match = new RegExp(`^${prefix.replace(/[[\]]/g, "\\$&")}\\[([^\\]]+)\\]$`).exec(key);
    if (match?.[1]) out[match[1]] = value;
  }
  return out;
}

function priceObject(priceId: string, priceIds: Readonly<Record<string, string>>) {
  const entry = Object.entries(priceIds).find(([, value]) => value === priceId);
  const spec = entry ? PRICES[entry[0]] : undefined;
  if (!spec) return null;
  return {
    id: priceId, object: "price", active: true, currency: "eur", unit_amount: spec.amount, tax_behavior: "inclusive", livemode: false,
    type: spec.recurring ? "recurring" : "one_time", recurring: spec.recurring ? { interval: "month", interval_count: spec.recurring } : null,
  };
}

export async function startFakeStripe(serverWebhookUrl = `${process.env.TEST_API_URL ?? `http://localhost:${process.env.E2E_PORT ?? 3480}`}/api/billing/stripe/webhook`): Promise<FakeStripe> {
  const webhookSecret = `whsec_test_${randomBytes(16).toString("hex")}`;
  const priceIds = Object.fromEntries(Object.keys(PRICES).map((name) => [name, `price_test_${name.toLowerCase().replace("stripe_price_", "")}`]));
  const sessions = new Map<string, Session>();
  const subscriptions = new Map<string, Record<string, unknown>>();
  const stripe = new Stripe("sk_test_fake");

  const subscriptionObject = (subscriptionId: string, session: Session, status = "active") => {
    const now = Math.floor(Date.now() / 1000);
    const months = PRICES[Object.entries(priceIds).find(([, v]) => v === session.price)?.[0] ?? ""]?.recurring ?? 1;
    const end = now + months * 30 * 86_400;
    return {
      id: subscriptionId, object: "subscription", start_date: now, status, customer: session.customer, livemode: false, cancel_at_period_end: false, metadata: session.metadata,
      items: { object: "list", data: [{ id: id("si"), object: "subscription_item", price: priceObject(session.price, priceIds), current_period_start: now, current_period_end: end, quantity: 1 }] },
    };
  };

  async function sendWebhook(type: string, object: Record<string, unknown>, url: string): Promise<void> {
    const payload = JSON.stringify({ id: id("evt"), object: "event", api_version: "2026-09-30.endive", created: Math.floor(Date.now() / 1000), livemode: false, type, data: { object } });
    const signature = await stripe.webhooks.generateTestHeaderStringAsync({ payload, secret: webhookSecret });
    await fetch(url, { method: "POST", headers: { "Content-Type": "application/json", "Stripe-Signature": signature }, body: payload });
  }

  async function pay(session: Session): Promise<void> {
    const base = { id: session.id, object: "checkout.session", created: Math.floor(Date.now() / 1000), mode: session.mode, customer: session.customer, client_reference_id: session.clientReference, metadata: session.metadata, livemode: false, status: "complete", payment_status: "paid" };
    if (session.mode === "subscription") {
      const subscriptionId = id("sub");
      subscriptions.set(subscriptionId, subscriptionObject(subscriptionId, session));
      await sendWebhook("checkout.session.completed", { ...base, subscription: subscriptionId, payment_intent: null }, session.webhookUrl);
    } else {
      await sendWebhook("checkout.session.completed", { ...base, subscription: null, payment_intent: id("pi") }, session.webhookUrl);
    }
  }

  const server = Bun.serve({
    port: 0,
    async fetch(req) {
      const url = new URL(req.url);
      const form: Form = req.method === "POST" ? Object.fromEntries(new URLSearchParams(await req.text())) : {};
      if (req.method === "POST" && url.pathname === "/v1/customers") return json({ id: id("cus"), object: "customer", email: form.email ?? null, metadata: metadataOf(form, "metadata"), livemode: false });
      if (req.method === "POST" && url.pathname === "/v1/checkout/sessions") {
        const session: Session = {
          id: id("cs"), mode: form.mode === "subscription" ? "subscription" : "payment", customer: form.customer ?? id("cus"), price: form["line_items[0][price]"] ?? "",
          metadata: metadataOf(form, "metadata"), clientReference: form.client_reference_id ?? "", successUrl: form.success_url ?? "", cancelUrl: form.cancel_url ?? "", webhookUrl: serverWebhookUrl,
        };
        sessions.set(session.id, session);
        return json({ id: session.id, object: "checkout.session", mode: session.mode, url: `${url.origin}/pay/${session.id}`, status: "open", livemode: false, metadata: session.metadata });
      }
      if (req.method === "POST" && url.pathname === "/v1/billing_portal/sessions") return json({ id: id("bps"), object: "billing_portal.session", url: `${url.origin}/portal`, customer: form.customer, return_url: form.return_url ?? null, livemode: false });
      const price = /^\/v1\/prices\/([^/]+)$/.exec(url.pathname);
      if (req.method === "GET" && price?.[1]) return priceObject(price[1], priceIds) ? json(priceObject(price[1], priceIds)) : json({ error: { type: "invalid_request_error", message: "No such price" } }, 404);
      const sub = /^\/v1\/subscriptions\/([^/]+)$/.exec(url.pathname);
      if (sub?.[1]) {
        const found = subscriptions.get(sub[1]);
        if (!found) return json({ error: { type: "invalid_request_error", message: "No such subscription" } }, 404);
        if (req.method === "DELETE") { const canceled = { ...found, status: "canceled" }; subscriptions.set(sub[1], canceled); return json(canceled); }
        return json(found);
      }
      const pay_ = /^\/pay\/([^/]+)$/.exec(url.pathname);
      if (pay_?.[1]) {
        const session = sessions.get(pay_[1]);
        if (!session) return new Response("Session inconnue", { status: 404 });
        if (req.method === "POST") { await pay(session); return Response.redirect(session.successUrl, 303); }
        return new Response(`<!doctype html><html lang="fr"><meta charset="utf-8"><title>Paiement de test</title><body style="font-family:system-ui;max-width:420px;margin:80px auto">
          <h1>Paiement de test (faux Stripe)</h1><p>Mode ${session.mode}. Aucun argent réel.</p>
          <form method="post"><button id="pay" style="font-size:18px;padding:12px 24px">Payer</button></form>
          <p><a href="${session.cancelUrl}">Annuler</a></p></body></html>`, { headers: { "Content-Type": "text/html; charset=utf-8" } });
      }
      return json({ error: { type: "invalid_request_error", message: `Unrecognized request URL (${req.method}: ${url.pathname})` } }, 404);
    },
  });
  return { baseUrl: `http://127.0.0.1:${server.port}`, webhookSecret, priceEnv: priceIds, stop: () => void server.stop(true) };
}
