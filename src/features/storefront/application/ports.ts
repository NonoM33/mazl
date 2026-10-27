// Ports to the stores that hold the real prices. The domain never calls Apple
// or Stripe directly; the adapters live in infra/app-store-connect and infra/stripe.

export type Territory = string; // ISO 3166-1 alpha-3, as App Store Connect ("FRA", "USA")

export interface StorePrice {
  readonly territory: Territory;
  readonly currency: string; // ISO 4217
  readonly customerPrice: string; // decimal string as Apple returns it ("44.99")
}

export interface ApplePricePoint {
  readonly id: string;
  readonly territory: Territory;
  readonly customerPrice: string;
  readonly proceeds: string;
}

export interface ApplePriceChangePlan {
  readonly productId: string;
  readonly startDate: string; // YYYY-MM-DD
  readonly preserveCurrentPrice: boolean;
  readonly changes: readonly { readonly territory: Territory; readonly from: string | null; readonly to: string; readonly pricePointId: string }[];
}

export interface AppleOfferCodeRequest {
  readonly productId: string;
  readonly name: string; // internal, ≤ 64 chars
  readonly customCode: string; // A-Z0-9, 6..64
  readonly discountPercent: number;
  readonly expiresOn: string; // YYYY-MM-DD, last day the code works
}

export interface AppleOfferCode {
  readonly productId: string;
  readonly offerCodeId: string;
  readonly customCodeId: string;
  readonly customCode: string;
}

export interface AppStorePricing {
  currentPrices(productId: string, territories: readonly Territory[]): Promise<readonly StorePrice[]>;
  pricePoints(productId: string, territory: Territory): Promise<readonly ApplePricePoint[]>;
  // Everything the change would do, country by country, without writing anything.
  planPriceChange(productId: string, basePricePointId: string, startDate: string, preserveCurrentPrice: boolean): Promise<ApplePriceChangePlan>;
  applyPriceChange(plan: ApplePriceChangePlan): Promise<void>;
  createOfferCode(request: AppleOfferCodeRequest): Promise<AppleOfferCode>;
  deactivateOfferCode(code: AppleOfferCode): Promise<void>;
}

export interface WebPrice {
  readonly priceId: string;
  readonly amountCents: number;
  readonly currency: string;
}

export interface WebPromotion {
  readonly couponId: string;
  readonly promotionCodeId: string;
}

export interface WebPricing {
  currentPrice(priceId: string): Promise<WebPrice>;
  createPrice(productId: string, amountCents: number, currency: string, recurringMonths: number | null): Promise<WebPrice>;
  createPromotion(name: string, percentOff: number, appliesToPriceIds: readonly string[], redeemBy: Date): Promise<WebPromotion>;
  deactivatePromotion(promotion: WebPromotion): Promise<void>;
}
