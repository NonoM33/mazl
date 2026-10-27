// Corps des requêtes d'écriture de la vitrine, construits à un seul endroit : l'écran et le test de contrat les prennent ici.
// Ils ont la forme des schémas d'entrée du serveur (src/features/storefront/presentation/schemas.ts).
import type { ApplePriceBody, CampaignInput, CampaignPatch, ProductPatch, WebPriceBody } from "./types";
import type { Editability } from "./campaign-state";

export const applePriceRequest = (draft: { readonly pricePointId: string; readonly startDate: string; readonly preserveCurrentPrice: boolean; readonly dryRun: boolean }): ApplePriceBody => ({
  pricePointId: draft.pricePointId,
  startDate: draft.startDate,
  preserveCurrentPrice: draft.preserveCurrentPrice,
  dryRun: draft.dryRun,
});

export const webPriceRequest = (amountCents: number, currency: string): WebPriceBody => ({ amountCents, currency });

export const sortOrderRequest = (sortOrder: number): ProductPatch => ({ sortOrder });

/** Campagne en cours : seule la fin peut être avancée. */
export const endEarlierRequest = (endsAt: string): CampaignPatch => ({ endsAt });

/** Ce que l'écran envoie à l'enregistrement d'une campagne existante : tout pour un brouillon, nom, textes et icône pour une programmée. */
export function campaignUpdateRequest(editability: Extract<Editability, "full" | "partial">, input: CampaignInput): CampaignPatch {
  return editability === "partial" ? { name: input.name, texts: input.texts, changeAppIcon: input.changeAppIcon } : input;
}
