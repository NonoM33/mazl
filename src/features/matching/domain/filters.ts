import { candidateMatchesFilters } from "./discover-filters";
import { distanceKm } from "./geo";
import type { MatchingParams } from "./params";
import type { LookingFor, MatchProfile, ViewerContext } from "./profile";
import type { ExclusionReason } from "./ranking";

function wants(lookingFor: LookingFor | null, gender: MatchProfile["gender"]): boolean {
  return lookingFor === null || lookingFor === "all" || gender === null || lookingFor === gender;
}

function ageFits(age: number | null, min: number, max: number): boolean {
  return age === null || (age >= min && age <= max);
}

function ageAllowed(viewer: MatchProfile, candidate: MatchProfile, params: MatchingParams): boolean {
  if (!ageFits(candidate.age, viewer.ageMin, viewer.ageMax)) return false;
  return !params.filters.mutualAge || ageFits(viewer.age, candidate.ageMin, candidate.ageMax);
}

function distanceAllowed(viewer: MatchProfile, candidate: MatchProfile, params: MatchingParams): boolean {
  if (viewer.location === null || candidate.location === null) return true;
  const km = distanceKm(viewer.location, candidate.location);
  if (viewer.distanceMaxKm !== null && km > viewer.distanceMaxKm) return false;
  if (!params.filters.mutualDistance || candidate.distanceMaxKm === null) return true;
  return km <= candidate.distanceMaxKm;
}

export function exclusionReason(
  viewer: MatchProfile,
  candidate: MatchProfile,
  ctx: ViewerContext,
  params: MatchingParams,
): ExclusionReason | null {
  if (candidate.userId === viewer.userId || ctx.excluded.has(candidate.userId)) return "excluded";
  if (!wants(viewer.lookingFor, candidate.gender) || !wants(candidate.lookingFor, viewer.gender)) return "gender";
  if (!ageAllowed(viewer, candidate, params)) return "age";
  if (!distanceAllowed(viewer, candidate, params)) return "distance";
  if (ctx.filters !== undefined && !candidateMatchesFilters(candidate, ctx.filters)) return "filters";
  return null;
}
