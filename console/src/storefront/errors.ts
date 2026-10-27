// Erreurs du serveur de la vitrine, dites en clair. Le message du serveur complète le code quand il en a un.
import type { ApiResult } from "../shared/api/client";

type Failure = Extract<ApiResult<never>, { readonly ok: false }>;

const KNOWN: Readonly<Record<string, string>> = {
  campaign_overlap: "Une autre campagne programmée occupe déjà une partie de ces dates. Deux campagnes programmées ne peuvent pas se chevaucher : changez les dates, ou annulez l'autre campagne.",
  store_not_configured: "Apple ou Stripe n'est pas encore relié à ce serveur (clés manquantes). Rien n'a été créé ; la campagne reste en brouillon.",
  apple_error: "Apple a refusé la demande. Rien n'a été programmé : la campagne reste en brouillon.",
  stripe_error: "Stripe a refusé la demande. La campagne reste en brouillon.",
  campaign_locked: "Cette campagne est déjà programmée ou en cours : elle ne peut plus être modifiée, seulement raccourcie ou annulée.",
  campaign_not_found: "Cette campagne n'existe plus.",
  product_not_found: "Ce produit n'existe plus dans le catalogue.",
  invalid_campaign: "Les informations de la campagne sont refusées par le serveur.",
  invalid_price: "Ce prix est refusé par le serveur.",
  price_point_not_found: "Ce palier de prix n'existe plus chez Apple.",
};

/** Message à afficher pour un échec d'API de la vitrine. Le détail renvoyé par le serveur est ajouté s'il apporte quelque chose. */
export function storefrontErrorMessage(failure: Pick<Failure, "code" | "message" | "status">): string {
  const known = KNOWN[failure.code];
  if (known === undefined) return failure.message;
  const detail = failure.message.trim();
  return detail === "" || detail === known || failure.code === "campaign_overlap" || failure.code === "store_not_configured" ? known : `${known} Détail : ${detail}`;
}
