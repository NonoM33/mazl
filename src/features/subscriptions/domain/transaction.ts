// A StoreKit transaction whose signature and origin have been verified.
export interface VerifiedTransaction {
  readonly originalTransactionId: string;
  readonly productId: string;
  readonly environment: "Sandbox" | "Production";
  readonly originalPurchaseDate: Date | undefined;
  readonly expiresAt: Date;
  readonly revokedAt: Date | undefined;
}

// What this app sells and accepts. The bundle id and the product ids come from
// configuration (APPLE_BUNDLE_ID, APPLE_PRODUCT_IDS).
export interface ProductPolicy {
  readonly bundleId: string;
  readonly productIds: readonly string[];
}
