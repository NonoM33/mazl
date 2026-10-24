import type { OfferId } from "../domain/offers";

// What the application layer needs of the configuration, once validated.
export interface BillingSettings {
  // Only the offers whose STRIPE_PRICE_* variable is set.
  readonly prices: Readonly<Partial<Record<OfferId, string>>>;
  readonly successUrl: string;
  readonly cancelUrl: string;
  readonly returnUrl: string;
}
