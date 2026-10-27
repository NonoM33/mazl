import { OFFERS, type Offer } from "../../billing-web/domain/offers";
import type { LocalizedText } from "./languages";

// The products the store sells: the web offers catalogue is the source of the ids.
export interface CatalogProduct {
  readonly productId: string;
  readonly kind: Offer["kind"];
  // Billing period of a subscription, null for a one-off pack.
  readonly months: number | null;
  // The environment variable that holds the Stripe price until the catalogue has its own.
  readonly priceEnv: string;
  readonly defaultFeatured: boolean;
  readonly defaultSortOrder: number;
}

export const CATALOG_PRODUCTS: readonly CatalogProduct[] = OFFERS.map((offer, index) => ({
  productId: offer.productId,
  kind: offer.kind,
  months: offer.kind === "subscription" ? offer.months : null,
  priceEnv: offer.priceEnv,
  defaultFeatured: offer.featured,
  defaultSortOrder: index,
}));

export function catalogProduct(productId: string): CatalogProduct | undefined {
  return CATALOG_PRODUCTS.find((product) => product.productId === productId);
}

export interface ProductDisplay {
  readonly productId: string;
  readonly visible: boolean;
  readonly sortOrder: number;
  readonly featured: boolean;
  readonly highlight: LocalizedText | null;
  // null: the Stripe price comes from the environment variable.
  readonly stripePriceId: string | null;
  readonly updatedAt: Date;
  readonly updatedBy: string | null;
}

// Apple's countries of reference: France and four witnesses.
export const APPLE_TERRITORIES = ["FRA", "USA", "GBR", "ISR", "CAN"] as const;
