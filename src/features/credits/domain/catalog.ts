export type CreditKind = "super_like" | "boost";

export const CREDIT_KINDS: readonly CreditKind[] = ["super_like", "boost"];

export interface CreditProduct {
  readonly productId: string;
  readonly kind: CreditKind;
  readonly quantity: number;
}

// The consumables sold on the App Store (docs/premium/CREDITS.md, "Produits").
export const CREDIT_PRODUCTS: readonly CreditProduct[] = [
  { productId: "com.mazl.app.boost.1", kind: "boost", quantity: 1 },
  { productId: "com.mazl.app.boost.3", kind: "boost", quantity: 3 },
  { productId: "com.mazl.app.superlikes.5", kind: "super_like", quantity: 5 },
  { productId: "com.mazl.app.superlikes.15", kind: "super_like", quantity: 15 },
];

export function creditProductFor(productId: string): CreditProduct | undefined {
  return CREDIT_PRODUCTS.find((product) => product.productId === productId);
}
