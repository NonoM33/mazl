import { ApiError } from "../../shared/api/errors";
import type { BillingCatalog, BillingStatus, Offer, OfferId } from "../../shared/api/types";
import { formatDate, formatEuros } from "../../shared/lib/format";

// Pure rules of the mazl+ screen: prices, which offer is highlighted, when the
// pay button opens, and how a failed checkout is worded.

export const priceLabel = (cents: number): string => `${formatEuros(cents)} TTC`;

export function perMonthLabel(offer: Offer): string | null {
  return offer.per_month_ttc_cents === undefined ? null : `soit ${formatEuros(offer.per_month_ttc_cents)} / mois`;
}

export function durationLabel(months: number): string {
  return months === 1 ? "1 mois" : `${months} mois`;
}

export function packLabel(offer: Offer): string {
  const quantity = offer.quantity ?? 1;
  if (offer.credit_kind === "boost") return quantity === 1 ? "1 Boost" : `${quantity} Boosts`;
  return `${quantity} Super Likes`;
}

export const subscriptionOffers = (catalog: BillingCatalog): readonly Offer[] =>
  catalog.offers.filter((offer) => offer.kind === "subscription").toSorted((a, b) => (a.months ?? 0) - (b.months ?? 0));

export const packOffers = (catalog: BillingCatalog, kind: "boost" | "super_like"): readonly Offer[] =>
  catalog.offers.filter((offer) => offer.kind === "credits" && offer.credit_kind === kind).toSorted((a, b) => (a.quantity ?? 0) - (b.quantity ?? 0));

// The offer chosen when the screen opens: the highlighted one.
export function defaultOffer(catalog: BillingCatalog, canSubscribe: boolean): OfferId | null {
  if (!canSubscribe) return null;
  const subscriptions = subscriptionOffers(catalog);
  return (subscriptions.find((offer) => offer.featured) ?? subscriptions[0])?.id ?? null;
}

export interface PayState { readonly selected: OfferId | null; readonly waiver: boolean; readonly busy: boolean }

// Paying needs an offer AND the unticked-by-default withdrawal waiver (CGV 6.2).
export const canPay = ({ selected, waiver, busy }: PayState): boolean => selected !== null && waiver && !busy;

export function checkoutErrorMessage(error: unknown): string {
  if (!(error instanceof ApiError)) return "Connexion impossible. Vérifiez votre réseau, puis réessayez.";
  if (error.status === 409) return error.body.source === "apple" ? "Votre abonnement mazl+ est géré par l'App Store." : "Vous avez déjà un abonnement mazl+ actif.";
  if (error.status === 429) return "Trop de tentatives. Réessayez dans quelques minutes.";
  if (error.status === 503 || error.code === "billing_unavailable") return "Le paiement sur le site sera bientôt disponible.";
  if (error.status === 400) return "Cochez la case de renoncement pour continuer.";
  return "Le paiement n'a pas pu démarrer. Réessayez dans un instant.";
}

export type PlusView =
  | { readonly kind: "none" }
  | { readonly kind: "stripe"; readonly line: string; readonly canceling: boolean }
  | { readonly kind: "apple"; readonly line: string };

// What the status card says about an active mazl+.
export function plusView(status: BillingStatus): PlusView {
  if (!status.plus.active) return { kind: "none" };
  const until = status.plus.expires_at ? formatDate(status.plus.expires_at) : null;
  if (status.plus.source === "apple") return { kind: "apple", line: until ? `Actif jusqu'au ${until}.` : "Actif." };
  const canceling = status.stripe.subscription?.cancel_at_period_end === true;
  const end = status.stripe.subscription ? formatDate(status.stripe.subscription.current_period_end) : until;
  if (end === null) return { kind: "stripe", line: "Actif.", canceling };
  return { kind: "stripe", canceling, line: canceling ? `Résiliation prévue le ${end}. Vous gardez vos avantages jusqu'à cette date.` : `Renouvellement automatique le ${end}.` };
}

export const CHECKOUT_POLL_MS = 2000;
export const CHECKOUT_POLL_MAX = 15;
