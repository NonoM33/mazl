import type { Offer, OfferId } from "../domain/offers";
import type { EntitlementProjection, StripeSubscriptionState, StripeSubscriptionStatus } from "../domain/projection";

export interface PriceView {
  readonly id: string;
  readonly unitAmount: number | null;
  readonly currency: string;
  readonly taxBehavior: string | null;
}

// A Stripe subscription as the provider reports it. Ids that MAZL wrote into
// the metadata at checkout are carried as read, they are validated later.
export interface SubscriptionView {
  readonly id: string;
  readonly customerId: string;
  readonly metadataUserId: number | undefined;
  readonly metadataOffer: string | undefined;
  readonly priceId: string | undefined;
  readonly status: StripeSubscriptionStatus;
  // Stripe puts the period end on the subscription items, not on the subscription.
  readonly currentPeriodEnd: Date | undefined;
  readonly cancelAtPeriodEnd: boolean;
  readonly startedAt: Date;
}

export interface CheckoutSessionInput {
  readonly customerId: string;
  readonly userId: number;
  readonly offer: Offer;
  readonly priceId: string;
  readonly waiverId: number;
  readonly successUrl: string;
  readonly cancelUrl: string;
}

export interface StripeGateway {
  createCustomer(input: { readonly userId: number; readonly email: string | undefined }): Promise<{ readonly id: string }>;
  createCheckoutSession(input: CheckoutSessionInput): Promise<{ readonly id: string; readonly url: string }>;
  createPortalSession(input: { readonly customerId: string; readonly returnUrl: string }): Promise<{ readonly url: string }>;
  retrieveSubscription(subscriptionId: string): Promise<SubscriptionView>;
  // Cancelling a subscription Stripe no longer knows is a success.
  cancelSubscription(subscriptionId: string): Promise<void>;
  // Expires the customer's open Checkout sessions in subscription mode.
  expireOpenSubscriptionCheckouts(customerId: string): Promise<void>;
  // Refunds in full the payment of the subscription's latest invoice, if any.
  refundLatestPayment(subscriptionId: string): Promise<void>;
  retrievePrice(priceId: string): Promise<PriceView>;
}

interface EventBase {
  readonly eventId: string;
  readonly type: string;
  readonly livemode: boolean;
}

export type BillingEvent = EventBase &
  (
    | {
        readonly kind: "checkout_completed";
        readonly mode: string;
        readonly paymentStatus: string;
        readonly sessionId: string;
        readonly userId: number | undefined;
        readonly offerId: string | undefined;
        readonly subscriptionId: string | undefined;
        readonly paymentIntentId: string | undefined;
        readonly createdAt: Date;
      }
    | { readonly kind: "subscription_changed"; readonly subscriptionId: string }
    | { readonly kind: "payment_failed"; readonly subscriptionId: string | undefined }
    | { readonly kind: "charge_refunded"; readonly paymentIntentId: string | undefined; readonly fullyRefunded: boolean }
    | { readonly kind: "charge_disputed"; readonly paymentIntentId: string | undefined }
    | { readonly kind: "ignored" }
  );

export interface WebhookVerifier {
  // Throws InvalidSignatureError when the signature does not match the raw body.
  verify(rawBody: string, signature: string | undefined): Promise<BillingEvent>;
}

export interface EntitlementRow {
  readonly store: string | null;
  readonly status: string | null;
  readonly planType: string | null;
  readonly originalTransactionId: string | null;
  readonly expiresAt: Date | null;
  // active and not expired, decided by the database clock like PgPlusStatus.
  readonly live: boolean;
}

export interface NewWaiver {
  readonly userId: number;
  readonly offer: OfferId;
  readonly textVersion: string;
  readonly textSha256: string;
}

export interface BillingRepository {
  memberEmail(userId: number): Promise<string | undefined>;
  userExists(userId: number): Promise<boolean>;
  customerIdOf(userId: number): Promise<string | undefined>;
  // Keeps the first customer saved for the member and returns it.
  saveCustomer(userId: number, customerId: string): Promise<string>;
  userOfCustomer(customerId: string): Promise<number | undefined>;
  recordWaiver(waiver: NewWaiver): Promise<number>;
  attachCheckoutSession(waiverId: number, sessionId: string): Promise<void>;
  beginEvent(eventId: string, type: string): Promise<"new" | "duplicate">;
  completeEvent(eventId: string): Promise<void>;
  saveSubscription(state: StripeSubscriptionState): Promise<void>;
  subscriptionsOf(userId: number): Promise<readonly StripeSubscriptionState[]>;
  ownerOfSubscription(subscriptionId: string): Promise<number | undefined>;
  // One conditional upsert: "kept" when the live entitlement of another source
  // (or another Stripe subscription) was protected.
  project(projection: EntitlementProjection): Promise<"written" | "kept">;
  entitlementOf(userId: number): Promise<EntitlementRow | undefined>;
}
