// Ce que « Programmer » ou « Annuler » fait chez Apple, chez Stripe et dans l'app, dit en clair avant confirmation. Fonctions pures.
import { formatParis, formatLastDay } from "./paris-time";
import { productLabel, webPrice } from "./product-view";
import type { CampaignInput, ProductDto } from "./types";

export interface PublishSummary {
  readonly apple: readonly string[];
  readonly stripe: readonly string[];
  readonly app: readonly string[];
}

const byPercent = (targets: readonly { readonly productId: string; readonly discountPercent: number }[]): ReadonlyMap<number, readonly string[]> => {
  const groups = new Map<number, string[]>();
  for (const target of targets) groups.set(target.discountPercent, [...(groups.get(target.discountPercent) ?? []), target.productId]);
  return groups;
};

export function publishSummary(campaign: Pick<CampaignInput, "themeId" | "startsAt" | "endsAt" | "targets" | "changeAppIcon">, products: readonly ProductDto[]): PublishSummary {
  const find = (productId: string): ProductDto | undefined => products.find((product) => product.productId === productId);
  const found = (productId: string): ProductDto | undefined => find(productId);
  const soldOnWeb = (product: ProductDto | undefined): boolean => product !== undefined && webPrice(product) !== null;
  const label = (productId: string): string => {
    const product = found(productId);
    return product === undefined ? productId : productLabel(product);
  };
  const until = formatLastDay(campaign.endsAt);
  const apple: string[] = [];
  const stripe: string[] = [];
  for (const target of campaign.targets) {
    const product = find(target.productId);
    if (product?.kind === "subscription" || product === undefined) {
      apple.push(`${label(target.productId)} : un code d'offre à −${target.discountPercent} %, valable pour les nouveaux, anciens et actuels abonnés jusqu'au ${until}. Le prix de base ne bouge pas.`);
    } else {
      apple.push(`${label(target.productId)} : un prix temporaire à −${target.discountPercent} % dans le calendrier de prix d'Apple, jusqu'au ${until} (sans effet tant que ce produit n'est pas validé chez Apple).`);
    }
  }
  for (const [percent, ids] of byPercent(campaign.targets.filter((target) => soldOnWeb(find(target.productId))))) {
    stripe.push(`Un coupon de −${percent} % valable jusqu'au ${until}, avec son code promo, appliqué d'office au paiement sur le site pour : ${ids.map(label).join(", ")}.`);
  }
  if (campaign.targets.length === 0) apple.push("Aucune remise ciblée : rien ne sera créé chez Apple.");
  if (campaign.targets.length === 0 || stripe.length === 0) stripe.push("Rien ne sera créé chez Stripe.");
  const app = [`La vitrine de l'app (écran mazl+, textes, badges de remise) bascule d'elle-même le ${formatParis(campaign.startsAt)} et revient à la normale à la fin.`];
  app.push(
    campaign.changeAppIcon
      ? `L'icône de l'app devient « AppIcon-${campaign.themeId} » pendant la campagne. iOS montre une alerte « Vous avez modifié l'icône » à chaque changement, et le changement n'a lieu que lorsque l'app est au premier plan.`
      : "L'icône de l'app ne change pas.",
  );
  return { apple, stripe, app };
}

export const CANCEL_LINES: Readonly<{ readonly draft: readonly string[]; readonly active: readonly string[] }> = {
  draft: ["La campagne passe à « Annulée ». Rien n'avait été créé chez Apple ni chez Stripe."],
  active: [
    "Les codes d'offre Apple de la campagne et son code promo Stripe sont désactivés.",
    "L'app retrouve sa vitrine et son icône habituelles dès qu'elle repasse au premier plan.",
    "Les abonnements déjà souscrits avec un code d'offre ne sont pas modifiés.",
  ],
};
