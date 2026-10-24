import type { CreditsRepository } from "../../credits/application/ports";
import { offerById } from "../domain/offers";
import type { BillingEvent, BillingRepository, WebhookVerifier } from "./ports";
import type { SubscriptionSync } from "./subscription-sync";

export type WebhookOutcome = "processed" | "duplicate";

type CheckoutCompleted = Extract<BillingEvent, { kind: "checkout_completed" }>;
type ChargeRefunded = Extract<BillingEvent, { kind: "charge_refunded" }>;

export interface WebhookDeps {
  readonly verifier: WebhookVerifier;
  readonly repository: BillingRepository;
  readonly sync: SubscriptionSync;
  readonly credits: Pick<CreditsRepository, "recordPurchase" | "refundPurchase">;
}

export class WebhookService {
  constructor(private readonly deps: WebhookDeps) {}

  // Throws InvalidSignatureError for a forged call. A processing failure
  // throws too and leaves the event unmarked, so Stripe delivers it again.
  async handle(rawBody: string, signature: string | undefined): Promise<WebhookOutcome> {
    const event = await this.deps.verifier.verify(rawBody, signature);
    if ((await this.deps.repository.beginEvent(event.eventId, event.type)) === "duplicate") return "duplicate";
    await this.dispatch(event);
    await this.deps.repository.completeEvent(event.eventId);
    return "processed";
  }

  private async dispatch(event: BillingEvent): Promise<void> {
    switch (event.kind) {
      case "checkout_completed":
        return await this.onCheckout(event);
      case "subscription_changed":
        return await this.deps.sync.syncFromStripe(event.subscriptionId);
      case "payment_failed":
        if (event.subscriptionId !== undefined) await this.deps.sync.syncFromStripe(event.subscriptionId);
        return;
      case "charge_refunded":
        return await this.onRefund(event);
      case "ignored":
        return;
    }
  }

  private async onCheckout(event: CheckoutCompleted): Promise<void> {
    if (event.mode === "subscription" && event.subscriptionId !== undefined) {
      return await this.deps.sync.syncFromStripe(event.subscriptionId);
    }
    if (event.mode === "payment" && event.paymentStatus === "paid") await this.creditPack(event);
  }

  // The PaymentIntent id is the transaction id: replays and the App Store
  // path share the same idempotence, lock and revocation table.
  private async creditPack(event: CheckoutCompleted): Promise<void> {
    const offer = offerById(event.offerId ?? "");
    if (offer?.kind !== "credits" || event.userId === undefined || !(await this.deps.repository.userExists(event.userId))) {
      console.warn(`Stripe checkout ${event.sessionId}: no credit pack or no member to credit, ignored`);
      return;
    }
    const outcome = await this.deps.credits.recordPurchase(event.userId, {
      transactionId: event.paymentIntentId ?? event.sessionId,
      productId: offer.productId,
      kind: offer.creditKind,
      quantity: offer.quantity,
      environment: event.livemode ? "Production" : "Sandbox",
      purchasedAt: event.createdAt,
    });
    if (outcome === "owned_by_another_user") console.error(`Stripe checkout ${event.sessionId}: transaction already credited to another member`);
  }

  private async onRefund(event: ChargeRefunded): Promise<void> {
    // Partial refunds keep the credits; so do charges of subscriptions (no credit offer in metadata).
    if (!event.fullyRefunded || event.paymentIntentId === undefined) return;
    if (offerById(event.offerId ?? "")?.kind !== "credits") return;
    await this.deps.credits.refundPurchase(event.paymentIntentId);
  }
}
