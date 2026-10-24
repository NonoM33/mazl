// A StoreKit transaction whose signature and origin have been verified.
export interface VerifiedTransaction {
  readonly originalTransactionId: string;
  readonly productId: string;
  readonly environment: "Sandbox" | "Production";
  readonly originalPurchaseDate: Date | undefined;
  readonly expiresAt: Date;
  readonly revokedAt: Date | undefined;
}

// A StoreKit transaction whose signature and bundle are checked, before any
// product policy applies. A consumable carries no expiry date, and not every
// transaction carries a transactionId or a type, so those stay optional here:
// each policy (subscription, consumable) demands what it needs.
export interface SignedTransaction {
  readonly originalTransactionId: string;
  readonly transactionId: string | undefined;
  readonly productId: string;
  readonly type: string | undefined;
  readonly environment: "Sandbox" | "Production";
  readonly originalPurchaseDate: Date | undefined;
  readonly purchaseDate: Date | undefined;
  readonly expiresAt: Date | undefined;
  readonly revokedAt: Date | undefined;
}

// What this app sells and accepts. The bundle id and the product ids come from
// configuration (APPLE_BUNDLE_ID, APPLE_PRODUCT_IDS).
export interface ProductPolicy {
  readonly bundleId: string;
  readonly productIds: readonly string[];
}
