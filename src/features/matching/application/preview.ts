import { rankCandidates } from "../domain/engine";
import type { MatchingParams } from "../domain/params";
import type { MatchProfile } from "../domain/profile";
import type { RankingResult } from "../domain/ranking";
import { syntheticNow, syntheticPopulation, type SyntheticLabel } from "../domain/synthetic";
import { validateParams } from "../domain/validate-params";
import { InvalidParamsError, InvalidPreviewError } from "./errors";

export const PREVIEW_DEFAULT_SIZE = 120;
export const PREVIEW_MIN_SIZE = 20;
export const PREVIEW_MAX_SIZE = 400;
// The preview shows the exploration slots of a page of this size.
export const PREVIEW_WINDOW = 30;

export interface PreviewInput {
  // Untrusted: checked by validateParams.
  readonly params: unknown;
  readonly compareWith?: unknown;
  readonly seed: number;
  readonly viewer: number | MatchProfile;
  readonly size?: number;
}

export interface PreviewOutput {
  readonly viewer: MatchProfile;
  readonly population: readonly MatchProfile[];
  readonly labels: Readonly<Record<number, SyntheticLabel>>;
  readonly result: RankingResult;
  readonly compare: RankingResult | null;
}

function checked(label: string, input: unknown): MatchingParams {
  const validation = validateParams(input);
  if (!validation.ok) throw new InvalidParamsError(validation.errors.map((e) => (label === "" ? e : `${label} : ${e}`)));
  return validation.params;
}

// Pure function of its input: synthetic people only, never the member base.
export function previewRanking(input: PreviewInput): PreviewOutput {
  const params = checked("", input.params);
  const compareParams = input.compareWith === undefined ? null : checked("compareWith", input.compareWith);
  const size = input.size ?? PREVIEW_DEFAULT_SIZE;
  if (!Number.isInteger(size) || size < PREVIEW_MIN_SIZE || size > PREVIEW_MAX_SIZE) {
    throw new InvalidPreviewError(`size : entre ${PREVIEW_MIN_SIZE} et ${PREVIEW_MAX_SIZE} attendu`);
  }
  const { profiles, labels } = syntheticPopulation(input.seed, size);
  const viewer = resolveViewer(input.viewer, profiles);
  const ctx = { now: syntheticNow(input.seed), excluded: new Set<number>() };
  const rank = (p: MatchingParams): RankingResult => rankCandidates(viewer, profiles, ctx, p, input.seed, PREVIEW_WINDOW);
  return { viewer, population: profiles, labels, result: rank(params), compare: compareParams === null ? null : rank(compareParams) };
}

// A custom viewer is moved to id 0 so that it cannot collide with a synthetic person.
function resolveViewer(viewer: number | MatchProfile, population: readonly MatchProfile[]): MatchProfile {
  if (typeof viewer !== "number") return { ...viewer, userId: 0 };
  const chosen = population[viewer];
  if (chosen === undefined) throw new InvalidPreviewError(`viewer : index entre 0 et ${population.length - 1} attendu`);
  return chosen;
}
