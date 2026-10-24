import { rankOf } from "./normalize";
import { CRITERIA, type Criterion, type MatchingParams, type ScaleName } from "./params";
import type { MatchProfile } from "./profile";
import type { CriterionScore, DirectionalScore } from "./ranking";

interface Raw {
  readonly score: number;
  readonly detail: string;
}

const NOT_PROVIDED = "Non renseigné";
const TOLERANCE: Readonly<Record<ScaleName, keyof MatchingParams["religion"]>> = {
  denomination: "denominationTolerance",
  kashrut: "kashrutTolerance",
  shabbat: "shabbatTolerance",
  intention: "intentionTolerance",
};
const clamp01 = (x: number): number => Math.min(1, Math.max(0, x));

function ordinal(name: ScaleName, from: MatchProfile, to: MatchProfile, p: MatchingParams): Raw {
  const scale = p.scales[name];
  const rankFrom = rankOf(scale, from[name]);
  const rankTo = rankOf(scale, to[name]);
  if (rankFrom === null || rankTo === null) return { score: p.religion.unknownScore, detail: NOT_PROVIDED };
  const gap = Math.abs(rankFrom - rankTo);
  const score = Math.max(0, 1 - gap / p.religion[TOLERANCE[name]]);
  const label = `${from[name] ?? ""} · ${to[name] ?? ""}`;
  return { score, detail: gap === 0 ? `${label} : même rang` : `${label} : écart de ${gap}` };
}

function age(from: MatchProfile, to: MatchProfile, p: MatchingParams): Raw {
  if (to.age === null) return { score: p.religion.unknownScore, detail: NOT_PROVIDED };
  const detail = `Âge ${to.age} dans ${from.ageMin}–${from.ageMax}`;
  if (to.age < from.ageMin || to.age > from.ageMax) return { score: 0, detail: `Âge ${to.age} hors ${from.ageMin}–${from.ageMax}` };
  const half = (from.ageMax - from.ageMin) / 2;
  if (half === 0) return { score: 1, detail };
  const offCentre = Math.abs(to.age - (from.ageMin + from.ageMax) / 2) / half;
  return { score: 1 - (1 - p.age.edgeScore) * offCentre, detail };
}

function distance(km: number | null, p: MatchingParams): Raw {
  if (km === null) return { score: p.religion.unknownScore, detail: NOT_PROVIDED };
  return { score: 1 / (1 + km / p.distance.halfScoreKm), detail: `${Math.round(km)} km` };
}

function completeness(to: MatchProfile): Raw {
  const score = (Math.min(to.photoCount, 4) / 4 + (to.hasBio ? 1 : 0) + Math.min(to.promptCount, 3) / 3) / 3;
  return { score, detail: `${to.photoCount} photo(s), ${to.hasBio ? "bio" : "sans bio"}, ${to.promptCount} question(s)` };
}

const VERIFICATION = {
  none: { score: 0, detail: "Non vérifié" },
  selfie: { score: 0.7, detail: "Selfie vérifié" },
  identity: { score: 1, detail: "Identité vérifiée" },
} as const;

function rawScore(c: Criterion, from: MatchProfile, to: MatchProfile, p: MatchingParams, km: number | null): Raw {
  switch (c) {
    case "denomination":
    case "kashrut":
    case "shabbat":
    case "intention":
      return ordinal(c, from, to, p);
    case "age":
      return age(from, to, p);
    case "distance":
      return distance(km, p);
    case "profile":
      return completeness(to);
    case "verification":
      return VERIFICATION[to.verification];
  }
}

export function criterionScores(from: MatchProfile, to: MatchProfile, params: MatchingParams, km: number | null): CriterionScore[] {
  const sum = CRITERIA.reduce((acc, c) => acc + params.weights[c], 0);
  return CRITERIA.map((criterion) => {
    const raw = rawScore(criterion, from, to, params, km);
    const weight = sum === 0 ? 0 : params.weights[criterion] / sum;
    return { criterion, score: raw.score, weight, contribution: raw.score * weight, detail: raw.detail };
  });
}

export function directional(from: MatchProfile, to: MatchProfile, params: MatchingParams, km: number | null): DirectionalScore {
  const criteria = criterionScores(from, to, params, km);
  return { total: clamp01(criteria.reduce((acc, s) => acc + s.contribution, 0)), criteria };
}
