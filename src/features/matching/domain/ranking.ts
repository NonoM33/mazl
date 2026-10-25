import type { Criterion } from "./params";

// The explained result of the engine for one candidate. Everything a staff
// member needs to answer "why does A see B, and at this place?" is here; the
// member app only ever receives the order, never these figures.

export interface CriterionScore {
  readonly criterion: Criterion;
  // Sub-score in [0, 1].
  readonly score: number;
  // Normalised weight in [0, 1] (weights divided by their sum).
  readonly weight: number;
  // score × weight: the share of the directional score it brings.
  readonly contribution: number;
  // Short French explanation: "Massorti / Traditionaliste : même rang", "12 km".
  readonly detail: string;
}

export interface DirectionalScore {
  // Weighted sum in [0, 1].
  readonly total: number;
  readonly criteria: readonly CriterionScore[];
}

export type MultiplierKey = "freshness" | "newcomer" | "boost" | "exposure" | "safety";

export interface Multiplier {
  readonly key: MultiplierKey;
  readonly factor: number;
  readonly detail: string;
}

export interface RankedCandidate {
  readonly userId: number;
  // 1-based position in the final order.
  readonly rank: number;
  // Final score: reciprocal × multipliers.
  readonly score: number;
  // How much the viewer should like the candidate…
  readonly forward: DirectionalScore;
  // …and how much the candidate should like the viewer.
  readonly backward: DirectionalScore;
  // Fusion of both directions according to the reciprocity mode.
  readonly reciprocal: number;
  readonly multipliers: readonly Multiplier[];
  // True when the candidate was placed by the exploration slots.
  readonly explored: boolean;
}

// Why a candidate was left out: shown by the preview, never to members.
export type ExclusionReason =
  | "excluded" // blocked, already swiped, the viewer, closed account
  | "gender"
  | "age"
  | "distance"
  | "filters"; // the viewer's advanced filters (mazl+)

export interface Exclusion {
  readonly userId: number;
  readonly reason: ExclusionReason;
}

export interface RankingResult {
  readonly ranked: readonly RankedCandidate[];
  readonly exclusions: readonly Exclusion[];
}
