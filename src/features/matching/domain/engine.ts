import { directional } from "./criteria";
import { exclusionReason } from "./filters";
import { distanceKm } from "./geo";
import { multipliers } from "./multipliers";
import type { MatchingParams } from "./params";
import type { MatchProfile, ViewerContext } from "./profile";
import { mulberry32, seedFrom } from "./random";
import type { Exclusion, RankedCandidate, RankingResult } from "./ranking";
import { fuse } from "./reciprocity";

function evaluate(viewer: MatchProfile, candidate: MatchProfile, ctx: ViewerContext, p: MatchingParams): RankedCandidate {
  const km = viewer.location && candidate.location ? distanceKm(viewer.location, candidate.location) : null;
  const forward = directional(viewer, candidate, p, km);
  const backward = directional(candidate, viewer, p, km);
  const reciprocal = fuse(forward.total, backward.total, p.reciprocity.mode);
  const factors = multipliers(candidate, p, ctx.now);
  const score = factors.reduce((acc, m) => acc * m.factor, reciprocal);
  return { userId: candidate.userId, rank: 0, score, forward, backward, reciprocal, multipliers: factors, explored: false };
}

const byScoreThenId = (a: RankedCandidate, b: RankedCandidate): number => b.score - a.score || a.userId - b.userId;

// Partial Fisher-Yates: `count` distinct picks, in the order drawn.
function draw<T>(pool: readonly T[], count: number, random: () => number): T[] {
  const copy = [...pool];
  const picks: T[] = [];
  for (let i = 0; i < count && copy.length > 0; i++) {
    const [pick] = copy.splice(Math.floor(random() * copy.length), 1);
    if (pick !== undefined) picks.push(pick);
  }
  return picks;
}

function withExploration(sorted: readonly RankedCandidate[], p: MatchingParams, seed: number, limit: number | undefined, viewerId: number): RankedCandidate[] {
  const pageSize = Math.min(limit ?? sorted.length, sorted.length);
  const slots = Math.floor(p.exploration.epsilon * pageSize);
  const beyond = sorted.slice(pageSize);
  const plausible = beyond.filter((c) => c.reciprocal >= p.exploration.minScore);
  const picks = draw(plausible, slots, mulberry32(seedFrom("exploration", seed, viewerId))).map((c) => ({ ...c, explored: true }));
  const taken = new Set(picks.map((c) => c.userId));
  const kept = pageSize - picks.length;
  const displaced = sorted.slice(kept).filter((c) => !taken.has(c.userId));
  return [...sorted.slice(0, kept), ...picks, ...displaced];
}

export function rankCandidates(
  viewer: MatchProfile,
  candidates: readonly MatchProfile[],
  ctx: ViewerContext,
  params: MatchingParams,
  seed: number,
  limit?: number,
): RankingResult {
  const exclusions: Exclusion[] = [];
  const ranked: RankedCandidate[] = [];
  const seen = new Set<number>();
  for (const candidate of candidates) {
    if (seen.has(candidate.userId)) continue;
    seen.add(candidate.userId);
    const reason = exclusionReason(viewer, candidate, ctx, params);
    if (reason === null) ranked.push(evaluate(viewer, candidate, ctx, params));
    else exclusions.push({ userId: candidate.userId, reason });
  }
  ranked.sort(byScoreThenId);
  const final = withExploration(ranked, params, seed, limit, viewer.userId);
  return { ranked: final.map((c, i) => ({ ...c, rank: i + 1 })), exclusions };
}
