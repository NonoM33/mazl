// Chiffres de la page « Comprendre » : tout est calculé à partir des réglages actifs reçus de l'API.
// Les formules reprennent celles du moteur (`criteria.ts`, `multipliers.ts`, `reciprocity.ts`,
// `engine.ts`) pour illustrer ; un test les compare au moteur lui-même.
import type { Criterion, MatchingParams, MultiplierKey, OrdinalScale, ReciprocityMode } from "../shared/api/contracts";

export const CRITERION_ORDER: readonly Criterion[] = ["denomination", "kashrut", "shabbat", "intention", "age", "distance", "profile", "verification"];

export const CRITERION_LABELS: Readonly<Record<Criterion, string>> = {
  denomination: "Courant",
  kashrut: "Cashrout",
  shabbat: "Chabbat",
  intention: "Intention",
  age: "Âge",
  distance: "Distance",
  profile: "Profil complet",
  verification: "Vérification",
};

export const MULTIPLIER_ORDER: readonly MultiplierKey[] = ["freshness", "newcomer", "boost", "exposure", "safety"];
export const MULTIPLIER_LABELS: Readonly<Record<MultiplierKey, string>> = {
  freshness: "Fraîcheur",
  newcomer: "Nouveau venu",
  boost: "Boost",
  exposure: "Exposition",
  safety: "Sécurité",
};

export interface WeightShare {
  readonly criterion: Criterion;
  readonly weight: number;
  /** Part du score total, entre 0 et 1 (poids divisé par la somme des poids). */
  readonly share: number;
}

export function weightShares(weights: MatchingParams["weights"]): readonly WeightShare[] {
  const sum = CRITERION_ORDER.reduce((acc, criterion) => acc + weights[criterion], 0);
  return CRITERION_ORDER.map((criterion) => ({ criterion, weight: weights[criterion], share: sum === 0 ? 0 : weights[criterion] / sum }));
}

export function fuse(forward: number, backward: number, mode: ReciprocityMode): number {
  switch (mode) {
    case "harmonic":
      return forward + backward === 0 ? 0 : (2 * forward * backward) / (forward + backward);
    case "geometric":
      return Math.sqrt(forward * backward);
    case "min":
      return Math.min(forward, backward);
    case "forward_only":
      return forward;
  }
}

export const freshnessFactor = (idleDays: number, p: MatchingParams["freshness"]): number => Math.max(p.floor, 2 ** (-Math.max(0, idleDays) / p.halfLifeDays));

export function newcomerFactor(accountAgeDays: number, p: MatchingParams["newcomer"]): number {
  const fade = p.days === 0 ? 0 : Math.max(0, 1 - Math.max(0, accountAgeDays) / p.days);
  return 1 + p.bonus * fade;
}

export const exposureFactor = (likes7d: number, p: MatchingParams["exposure"]): number => 1 / (1 + p.strength * Math.max(0, likes7d / p.popularityCap - 1));

export const safetyFactor = (openReports: number, p: MatchingParams["safety"]): number => Math.max(p.floor, (1 - p.penaltyPerReport) ** openReports);

/** Places d'exploration sur une page (même arrondi que le moteur : partie entière). */
export const explorationSlots = (epsilon: number, pageSize: number): number => Math.floor(epsilon * pageSize);

/** Une échelle triée par rang : « 0 : laïque · 1 : libéral, libérale … ». */
export function scaleRows(scale: OrdinalScale): readonly { readonly rank: number; readonly answers: readonly string[] }[] {
  const byRank = new Map<number, string[]>();
  for (const [answer, rank] of Object.entries(scale)) byRank.set(rank, [...(byRank.get(rank) ?? []), answer.replaceAll("_", " ")]);
  return [...byRank.entries()].sort((a, b) => a[0] - b[0]).map(([rank, answers]) => ({ rank, answers }));
}
