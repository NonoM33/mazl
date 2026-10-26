// Lecture d'une simulation : mouvements entre deux classements, écartés, libellés. Fonctions pures.
import type { ExclusionReason, PreviewResponse, RankedCandidate, RankingResult } from "../shared/api/contracts";

export const EXCLUSION_LABELS: Readonly<Record<ExclusionReason, string>> = {
  excluded: "bloqués, déjà vus ou fermés",
  gender: "genre recherché",
  age: "âge hors tranche",
  distance: "trop loin",
  filters: "filtres avancés",
};
export const EXCLUSION_ORDER: readonly ExclusionReason[] = ["excluded", "gender", "age", "distance", "filters"];

export function exclusionCounts(result: RankingResult): readonly { readonly reason: ExclusionReason; readonly count: number }[] {
  return EXCLUSION_ORDER.map((reason) => ({ reason, count: result.exclusions.filter((item) => item.reason === reason).length })).filter((row) => row.count > 0);
}

export type Movement =
  | { readonly kind: "same" }
  | { readonly kind: "up"; readonly places: number }
  | { readonly kind: "down"; readonly places: number }
  | { readonly kind: "new" };

/** Position d'un candidat dans `current` par rapport à `reference` (la version active). */
export function movementOf(candidate: RankedCandidate, reference: RankingResult | null): Movement {
  if (reference === null) return { kind: "same" };
  const before = reference.ranked.find((item) => item.userId === candidate.userId);
  if (before === undefined) return { kind: "new" };
  const places = before.rank - candidate.rank;
  if (places === 0) return { kind: "same" };
  return places > 0 ? { kind: "up", places } : { kind: "down", places: -places };
}

export function movementText(movement: Movement): string {
  switch (movement.kind) {
    case "same":
      return "inchangé";
    case "new":
      return "entre dans la page";
    case "up":
      return `monte de ${movement.places}`;
    case "down":
      return `descend de ${movement.places}`;
  }
}

/** Candidats de la version active qui sortent de la page avec les nouveaux réglages. */
export function droppedOut(current: RankingResult, reference: RankingResult | null, limit: number): readonly RankedCandidate[] {
  if (reference === null) return [];
  const kept = new Set(current.ranked.slice(0, limit).map((item) => item.userId));
  return reference.ranked.slice(0, limit).filter((item) => !kept.has(item.userId));
}

export function labelOf(response: PreviewResponse, userId: number): { readonly name: string; readonly city: string } {
  return response.labels[userId] ?? { name: `Profil ${userId}`, city: "—" };
}

export function sameRanking(a: RankingResult, b: RankingResult | null): boolean {
  if (b === null || a.ranked.length !== b.ranked.length) return false;
  return a.ranked.every((item, index) => item.userId === b.ranked[index]?.userId && Math.abs(item.score - (b.ranked[index]?.score ?? NaN)) < 1e-12);
}
