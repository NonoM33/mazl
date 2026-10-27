// Lecture d'un produit tel que le serveur le décrit (ProductViewDto) : prix Apple et Stripe, nom affiché. Fonctions pures.
import type { ProductDto, StorePriceDto, WebPriceDto } from "./types";

/** Les prix Apple lus pour le produit (France d'abord) ; vide si Apple n'a pas répondu. */
export const applePrices = (product: Pick<ProductDto, "prices">): readonly StorePriceDto[] => (product.prices.apple.status === "ok" ? product.prices.apple.items : []);

/** Pourquoi Apple n'a pas répondu, ou null. */
export const appleError = (product: Pick<ProductDto, "prices">): string | null => (product.prices.apple.status === "unavailable" ? product.prices.apple.error : null);

/** Le prix Stripe en vigueur ; null si le produit n'est pas vendu sur le site (aucun prix) ou si Stripe n'a pas répondu. */
export const webPrice = (product: Pick<ProductDto, "prices">): WebPriceDto | null => (product.prices.web.status === "ok" ? (product.prices.web.items[0] ?? null) : null);

export const webUnavailable = (product: Pick<ProductDto, "prices">): boolean => product.prices.web.status === "unavailable";

/** Devise d'un pays pour ce produit (lue sur ses prix Apple) ; null si le pays n'a pas de prix. */
export const currencyOf = (product: Pick<ProductDto, "prices">, territory: string): string | null => applePrices(product).find((price) => price.territory === territory)?.currency ?? null;

export type CreditKind = "boost" | "superlikes";

/** Les achats à l'unité n'ont qu'un type côté serveur (« credits ») ; la nature se lit dans l'identifiant (…boost.3, …superlikes.15). */
export function creditKind(productId: string): CreditKind | null {
  if (productId.includes(".boost.")) return "boost";
  return productId.includes(".superlikes.") ? "superlikes" : null;
}

/** Nom français du produit dans la console (« mazl+ 3 mois », « 3 Boosts »). Le serveur ne fournit pas de libellé. */
export function productLabel(product: Pick<ProductDto, "productId" | "kind" | "months">): string {
  if (product.kind === "subscription") return product.months === null ? product.productId : `mazl+ ${product.months} mois`;
  const count = Number(product.productId.split(".").pop());
  const kind = creditKind(product.productId);
  if (!Number.isInteger(count) || kind === null) return product.productId;
  if (kind === "boost") return count > 1 ? `${count} Boosts` : `${count} Boost`;
  return `${count} Super Like${count > 1 ? "s" : ""}`;
}
