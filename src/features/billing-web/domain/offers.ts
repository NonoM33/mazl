import { COUPLE_PRODUCT_ID, type PlanType } from "../../subscriptions/domain/plan";
import type { CreditKind } from "../../credits/domain/catalog";

export type SubscriptionOfferId = "plus_1m" | "plus_3m" | "plus_6m" | "plus_12m" | "couple_1m";
export type CreditOfferId = "boost_1" | "boost_3" | "superlikes_5" | "superlikes_15";
export type OfferId = SubscriptionOfferId | CreditOfferId;

export interface SubscriptionOffer {
  readonly kind: "subscription";
  readonly id: SubscriptionOfferId;
  readonly months: number;
  readonly planType: PlanType;
  // Logical product id, shared with the App Store catalogue (com.mazl.app.plus.<n>m).
  readonly productId: string;
  readonly priceEnv: string;
  readonly featured: boolean;
}

export interface CreditOffer {
  readonly kind: "credits";
  readonly id: CreditOfferId;
  readonly creditKind: CreditKind;
  readonly quantity: number;
  // Same ids as CREDIT_PRODUCTS, so web and App Store purchases share one catalogue.
  readonly productId: string;
  readonly priceEnv: string;
  readonly featured: false;
}

export type Offer = SubscriptionOffer | CreditOffer;

function plus(id: SubscriptionOfferId, months: number, planType: PlanType, priceEnv: string): SubscriptionOffer {
  return { kind: "subscription", id, months, planType, productId: `com.mazl.app.plus.${months}m`, priceEnv, featured: id === "plus_3m" };
}

// MAZL Couple, 1 month: bought by one partner, shared by both (docs/couple/ESPACE-COUPLE.md section 1).
function couple(): SubscriptionOffer {
  return { kind: "subscription", id: "couple_1m", months: 1, planType: "couple_monthly", productId: COUPLE_PRODUCT_ID, priceEnv: "STRIPE_PRICE_COUPLE_1M", featured: false };
}

function credits(id: CreditOfferId, creditKind: CreditKind, quantity: number, productId: string, priceEnv: string): CreditOffer {
  return { kind: "credits", id, creditKind, quantity, productId, priceEnv, featured: false };
}

export const OFFERS: readonly Offer[] = [
  plus("plus_1m", 1, "monthly", "STRIPE_PRICE_PLUS_1M"),
  plus("plus_3m", 3, "three_month", "STRIPE_PRICE_PLUS_3M"),
  plus("plus_6m", 6, "six_month", "STRIPE_PRICE_PLUS_6M"),
  plus("plus_12m", 12, "yearly", "STRIPE_PRICE_PLUS_12M"),
  couple(),
  credits("boost_1", "boost", 1, "com.mazl.app.boost.1", "STRIPE_PRICE_BOOST_1"),
  credits("boost_3", "boost", 3, "com.mazl.app.boost.3", "STRIPE_PRICE_BOOST_3"),
  credits("superlikes_5", "super_like", 5, "com.mazl.app.superlikes.5", "STRIPE_PRICE_SUPERLIKES_5"),
  credits("superlikes_15", "super_like", 15, "com.mazl.app.superlikes.15", "STRIPE_PRICE_SUPERLIKES_15"),
];

export function offerById(id: string): Offer | undefined {
  return OFFERS.find((offer) => offer.id === id);
}

export function subscriptionOfferById(id: string): SubscriptionOffer | undefined {
  const offer = offerById(id);
  return offer?.kind === "subscription" ? offer : undefined;
}

export function stripeMode(offer: Offer): "subscription" | "payment" {
  return offer.kind === "subscription" ? "subscription" : "payment";
}
