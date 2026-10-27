// Erreurs du serveur de la vitrine, dites en clair. Le message du serveur complète le code quand il en a un.
import type { ApiResult } from "../shared/api/client";

type Failure = Extract<ApiResult<never>, { readonly ok: false }>;

const KNOWN: Readonly<Record<string, string>> = {
  campaign_overlap: "Une autre campagne programmée occupe déjà une partie de ces dates. Deux campagnes programmées ne peuvent pas se chevaucher : changez les dates, ou annulez l'autre campagne.",
  store_not_configured: "Apple ou Stripe n'est pas encore relié à ce serveur (clés manquantes). Rien n'a été créé ; la campagne reste en brouillon.",
  store_error: "Apple ou Stripe a refusé la demande ou n'a pas répondu. Ce qui avait déjà été créé est conservé et sera réutilisé au prochain essai.",
  campaign_not_editable: "Cette campagne est déjà programmée, en cours ou terminée : elle ne peut plus être modifiée comme ça (seulement raccourcie ou annulée).",
  campaign_wrong_state: "Cette action ne s'applique pas à l'état actuel de la campagne.",
  campaign_not_found: "Cette campagne n'existe plus.",
  product_not_found: "Ce produit n'existe plus dans le catalogue.",
  invalid_campaign: "Les informations de la campagne sont refusées par le serveur.",
  invalid_price_change: "Ce changement de prix est refusé par le serveur.",
  invalid_body: "Une valeur envoyée est refusée par le serveur.",
  invalid_query: "Un paramètre de la demande est refusé par le serveur.",
};

/** Message à afficher pour un échec d'API de la vitrine. Le détail renvoyé par le serveur est ajouté s'il apporte quelque chose. */
export function storefrontErrorMessage(failure: Pick<Failure, "code" | "message" | "status">): string {
  const known = KNOWN[failure.code];
  if (known === undefined) return failure.message;
  const detail = failure.message.trim();
  return detail === "" || detail === known || failure.code === "campaign_overlap" || failure.code === "store_not_configured" ? known : `${known} Détail : ${detail}`;
}
