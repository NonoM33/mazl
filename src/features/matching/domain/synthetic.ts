import { DEFAULT_PARAMS, SCALES, type ScaleName } from "./params";
import type { Gender, LookingFor, MatchProfile, VerificationLevel } from "./profile";
import { mulberry32, seedFrom } from "./random";
import { CITIES, FEMALE_NAMES, FREE_ANSWERS, MALE_NAMES, type City } from "./synthetic-data";

export interface SyntheticLabel {
  readonly name: string;
  readonly city: string;
}

export interface SyntheticPopulation {
  readonly profiles: MatchProfile[];
  readonly labels: Record<number, SyntheticLabel>;
}

const DAY_MS = 86_400_000;
type Random = () => number;

// A fixed reference date derived from the seed: never the clock.
export function syntheticNow(seed: number): string {
  return new Date(Date.UTC(2026, 0, 1) + (seedFrom("now", seed) % 365) * DAY_MS).toISOString();
}

const pick = <T>(r: Random, items: readonly T[]): T => items[Math.floor(r() * items.length)] as T;
const between = (r: Random, min: number, max: number): number => min + Math.floor(r() * (max - min + 1));
const chance = (r: Random, p: number): boolean => r() < p;
const isoDaysBefore = (now: string, days: number): string => new Date(Date.parse(now) - days * DAY_MS).toISOString();

function pickCity(r: Random): City {
  let ticket = r() * CITIES.reduce((sum, c) => sum + c.weight, 0);
  for (const city of CITIES) {
    ticket -= city.weight;
    if (ticket < 0) return city;
  }
  return CITIES[0] as City;
}

function rawAnswer(r: Random, scale: ScaleName): string | null {
  if (chance(r, 0.08)) return null;
  if (scale === "denomination" && chance(r, 0.04)) return "Séfarade";
  if (chance(r, 0.03)) return pick(r, FREE_ANSWERS);
  const key = pick(r, Object.keys(DEFAULT_PARAMS.scales[scale]));
  const spaced = key.replaceAll("_", " ");
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

function pickLookingFor(r: Random, gender: Gender): LookingFor {
  const roll = r();
  if (roll < 0.9) return gender === "male" ? "female" : "male";
  return roll < 0.96 ? gender : "all";
}

function pickVerification(r: Random): VerificationLevel {
  const roll = r();
  if (roll < 0.35) return "none";
  return roll < 0.7 ? "selfie" : "identity";
}

function popularity(r: Random): number {
  return Math.floor(Math.min(400, 3 * (1 / Math.max(0.01, 1 - r()) - 1)));
}

function buildProfile(r: Random, userId: number, now: string, city: City): MatchProfile {
  const gender: Gender = chance(r, 0.5) ? "male" : "female";
  const age = between(r, 22, 45);
  const located = !chance(r, 0.03);
  const answers = Object.fromEntries(SCALES.map((s) => [s, rawAnswer(r, s)])) as Record<ScaleName, string | null>;
  return {
    userId,
    gender,
    lookingFor: pickLookingFor(r, gender),
    age,
    ageMin: Math.max(18, age - between(r, 3, 8)),
    ageMax: age + between(r, 3, 10),
    distanceMaxKm: pick(r, [10, 25, 50, 100, null]),
    location: located ? { latitude: city.latitude + (r() - 0.5) * 0.1, longitude: city.longitude + (r() - 0.5) * 0.1 } : null,
    ...answers,
    photoCount: between(r, 0, 6),
    hasBio: chance(r, 0.7),
    promptCount: between(r, 0, 4),
    verification: pickVerification(r),
    lastActiveAt: isoDaysBefore(now, r() * 60),
    createdAt: isoDaysBefore(now, chance(r, 0.15) ? r() * 14 : 14 + r() * 700),
    boostedUntil: chance(r, 0.05) ? new Date(Date.parse(now) + between(r, 1, 48) * 3_600_000).toISOString() : null,
    likesReceived7d: popularity(r),
    openReports90d: chance(r, 0.06) ? between(r, 1, 3) : 0,
  };
}

export function syntheticPopulation(seed: number, size: number): SyntheticPopulation {
  const r = mulberry32(seedFrom("population", seed));
  const now = syntheticNow(seed);
  const profiles: MatchProfile[] = [];
  const labels: Record<number, SyntheticLabel> = {};
  for (let userId = 1; userId <= size; userId++) {
    const city = pickCity(r);
    const profile = buildProfile(r, userId, now, city);
    profiles.push(profile);
    labels[userId] = { name: pick(r, profile.gender === "male" ? MALE_NAMES : FEMALE_NAMES), city: city.name };
  }
  return { profiles, labels };
}
