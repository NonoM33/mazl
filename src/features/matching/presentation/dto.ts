import type { MatchingParams, NumericParamSpec } from "../domain/params";
import type { MatchProfile } from "../domain/profile";
import type { RankingResult } from "../domain/ranking";

// HTTP contract of the matching tuning screen, under /api/backoffice/matching.
// Envelope: { success: true, data } | { success: false, error, message? }.

export interface ParamsVersionDto {
  readonly id: number;
  readonly params: MatchingParams;
  readonly note: string;
  readonly author: string;
  readonly createdAt: string;
  readonly parentId: number | null;
}

// GET /matching   (matching.read)
export interface MatchingStateDto {
  readonly active: ParamsVersionDto;
  // Running A/B test: members whose id hashes under `share` percent get `variant`.
  readonly abTest: { readonly variant: ParamsVersionDto; readonly sharePercent: number; readonly startedAt: string; readonly startedBy: string } | null;
  readonly specs: readonly NumericParamSpec[];
  readonly defaults: MatchingParams;
}

// GET /matching/versions?limit&offset   (matching.read)
export interface VersionPageDto {
  readonly versions: readonly (ParamsVersionDto & { readonly activatedAt: string | null })[];
  readonly total: number;
}

// POST /matching/versions { params, note, activate }   (matching.tune) → ParamsVersionDto
//   400 invalid_params with `message` listing every out-of-bounds value.
// POST /matching/versions/:id/activate { note }       (matching.tune) — also used to roll back.
// POST /matching/ab-test { variantId, sharePercent (1..50) } | DELETE /matching/ab-test   (matching.tune)

// POST /matching/preview   (matching.read) — runs the engine on SYNTHETIC profiles only.
export interface PreviewRequest {
  readonly params: MatchingParams;
  // A second parameter set to compare (A/B), optional.
  readonly compareWith?: MatchingParams;
  // Seed of the synthetic population (same seed, same people).
  readonly seed: number;
  // Index of the viewer in the population, or a custom viewer.
  readonly viewer: number | MatchProfile;
  readonly size?: number; // population size, 20..400, default 120
}

export interface PreviewResponse {
  readonly viewer: MatchProfile;
  readonly population: readonly MatchProfile[];
  // Fictitious first names and cities of the synthetic people, by userId.
  readonly labels: Readonly<Record<number, { readonly name: string; readonly city: string }>>;
  readonly result: RankingResult;
  readonly compare: RankingResult | null;
}
