import Stripe from "stripe";
import type { BillingEvent, WebhookVerifier } from "../application/ports";
import { InvalidSignatureError } from "../domain/errors";
import { mapStripeEvent } from "./stripe-event-mapper";

// The official verification: HMAC over "<timestamp>.<raw body>", 300 s tolerance.
export class StripeWebhookVerifier implements WebhookVerifier {
  constructor(
    private readonly stripe: Stripe,
    private readonly secret: string,
  ) {}

  async verify(rawBody: string, signature: string | undefined): Promise<BillingEvent> {
    if (signature === undefined || signature === "") throw new InvalidSignatureError();
    try {
      return mapStripeEvent(await this.stripe.webhooks.constructEventAsync(rawBody, signature, this.secret));
    } catch (error: unknown) {
      if (error instanceof Stripe.errors.StripeSignatureVerificationError) throw new InvalidSignatureError();
      throw error;
    }
  }
}
