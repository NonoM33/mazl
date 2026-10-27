// État affiché d'une campagne : calculé à partir du statut enregistré et de l'horloge. Fonctions pures.
import { formatSpan } from "./paris-time";
import type { CampaignState, CampaignStatus } from "./types";

export interface Schedulable {
  readonly status: CampaignStatus;
  readonly startsAt: string;
  readonly endsAt: string;
}

export function campaignState(campaign: Schedulable, now: Date = new Date()): CampaignState {
  if (campaign.status === "cancelled") return "cancelled";
  if (campaign.status === "draft") return "draft";
  const time = now.getTime();
  if (time < Date.parse(campaign.startsAt)) return "scheduled";
  return time < Date.parse(campaign.endsAt) ? "live" : "ended";
}

export const STATE_LABELS: Readonly<Record<CampaignState, string>> = {
  draft: "Brouillon",
  scheduled: "Programmée",
  live: "En cours",
  ended: "Terminée",
  cancelled: "Annulée",
};

export type StateTone = "neutral" | "accent" | "success" | "warning" | "error";
export const STATE_TONES: Readonly<Record<CampaignState, StateTone>> = {
  draft: "neutral",
  scheduled: "accent",
  live: "success",
  ended: "neutral",
  cancelled: "error",
};

/** Compte à rebours : « commence dans 12 j 3 h », « se termine dans 2 j », « terminée depuis 5 j » ; null pour un brouillon ou une annulation. */
export function countdown(campaign: Schedulable, now: Date = new Date()): string | null {
  const state = campaignState(campaign, now);
  const time = now.getTime();
  switch (state) {
    case "scheduled":
      return `commence dans ${formatSpan(Date.parse(campaign.startsAt) - time)}`;
    case "live":
      return `se termine dans ${formatSpan(Date.parse(campaign.endsAt) - time)}`;
    case "ended":
      return `terminée depuis ${formatSpan(time - Date.parse(campaign.endsAt))}`;
    default:
      return null;
  }
}

/**
 * Brouillon : tout se modifie. Programmée (pas commencée) : nom, textes et icône seulement, dates et produits sont verrouillés
 * (il faut annuler puis recréer). En cours : on ne peut que avancer la fin. Terminée ou annulée : rien.
 */
export type Editability = "full" | "partial" | "end-only" | "locked";
export function editability(campaign: Schedulable, now: Date = new Date()): Editability {
  const state = campaignState(campaign, now);
  if (state === "draft") return "full";
  if (state === "scheduled") return "partial";
  if (state === "live") return "end-only";
  return "locked";
}
