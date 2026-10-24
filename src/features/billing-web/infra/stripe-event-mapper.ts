import type Stripe from "stripe";
import type { BillingEvent } from "../application/ports";

function idOf(value: string | { readonly id: string } | null | undefined): string | undefined {
  if (value === null || value === undefined) return undefined;
  return typeof value === "string" ? value : value.id;
}

function userIdOf(session: Stripe.Checkout.Session): number | undefined {
  const raw = session.client_reference_id ?? session.metadata?.user_id;
  const id = raw === null || raw === undefined ? NaN : Number(raw);
  return Number.isSafeInteger(id) && id > 0 ? id : undefined;
}

function fromSession(base: Pick<BillingEvent, "eventId" | "type" | "livemode">, session: Stripe.Checkout.Session): BillingEvent {
  return {
    ...base,
    kind: "checkout_completed",
    mode: session.mode,
    paymentStatus: session.payment_status,
    sessionId: session.id,
    userId: userIdOf(session),
    offerId: session.metadata?.offer,
    subscriptionId: idOf(session.subscription),
    paymentIntentId: idOf(session.payment_intent),
    createdAt: new Date(session.created * 1000),
  };
}

// Reduces a Stripe event to the few facts the application reads. Anything
// else becomes "ignored" and is acknowledged without work.
export function mapStripeEvent(event: Stripe.Event): BillingEvent {
  const base = { eventId: event.id, type: event.type, livemode: event.livemode };
  switch (event.type) {
    case "checkout.session.completed":
    case "checkout.session.async_payment_succeeded":
      return fromSession(base, event.data.object);
    case "customer.subscription.updated":
    case "customer.subscription.deleted":
      return { ...base, kind: "subscription_changed", subscriptionId: event.data.object.id };
    case "invoice.payment_failed":
      return { ...base, kind: "payment_failed", subscriptionId: idOf(event.data.object.parent?.subscription_details?.subscription) };
    case "charge.refunded": {
      const charge = event.data.object;
      return { ...base, kind: "charge_refunded", paymentIntentId: idOf(charge.payment_intent), fullyRefunded: charge.refunded };
    }
    case "charge.dispute.created":
      return { ...base, kind: "charge_disputed", paymentIntentId: idOf(event.data.object.payment_intent) };
    default:
      return { ...base, kind: "ignored" };
  }
}
