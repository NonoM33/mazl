import type { MatchingParams } from "./params";
import type { MatchProfile } from "./profile";
import type { Multiplier } from "./ranking";

const DAY_MS = 86_400_000;
const daysBetween = (fromIso: string, toIso: string): number => (Date.parse(toIso) - Date.parse(fromIso)) / DAY_MS;

function freshness(c: MatchProfile, p: MatchingParams, now: string): Multiplier {
  if (c.lastActiveAt === null) return { key: "freshness", factor: p.freshness.floor, detail: "Jamais actif" };
  const idle = Math.max(0, daysBetween(c.lastActiveAt, now));
  const factor = Math.max(p.freshness.floor, 2 ** (-idle / p.freshness.halfLifeDays));
  return { key: "freshness", factor, detail: `Actif il y a ${Math.floor(idle)} j` };
}

function newcomer(c: MatchingParams["newcomer"], createdAt: string, now: string): Multiplier {
  const age = Math.max(0, daysBetween(createdAt, now));
  const fade = c.days === 0 ? 0 : Math.max(0, 1 - age / c.days);
  const detail = fade > 0 ? `Compte de ${Math.floor(age)} j` : "Compte établi";
  return { key: "newcomer", factor: 1 + c.bonus * fade, detail };
}

function boost(c: MatchProfile, p: MatchingParams, now: string): Multiplier {
  const running = c.boostedUntil !== null && Date.parse(c.boostedUntil) > Date.parse(now);
  return { key: "boost", factor: running ? p.boost.factor : 1, detail: running ? "Boost en cours" : "Pas de boost" };
}

function exposure(c: MatchProfile, p: MatchingParams): Multiplier {
  const excess = Math.max(0, c.likesReceived7d / p.exposure.popularityCap - 1);
  const factor = 1 / (1 + p.exposure.strength * excess);
  return { key: "exposure", factor, detail: `${c.likesReceived7d} likes en 7 j` };
}

function safety(c: MatchProfile, p: MatchingParams): Multiplier {
  const factor = Math.max(p.safety.floor, (1 - p.safety.penaltyPerReport) ** c.openReports90d);
  return { key: "safety", factor, detail: `${c.openReports90d} signalement(s) ouvert(s)` };
}

export function multipliers(candidate: MatchProfile, params: MatchingParams, now: string): Multiplier[] {
  return [
    freshness(candidate, params, now),
    newcomer(params.newcomer, candidate.createdAt, now),
    boost(candidate, params, now),
    exposure(candidate, params),
    safety(candidate, params),
  ];
}
