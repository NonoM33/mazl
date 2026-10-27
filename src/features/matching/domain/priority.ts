import type { RankedCandidate } from "./ranking";

// Likes of mazl+ members come first in the pile of the member they liked
// (docs/premium/MONETISATION.md section 6). Only the head of the pile changes:
// each group keeps the order the engine gave it, so the rest of the ranking
// is never distorted, and the exploration slots stay where they were drawn.
export function withPriorityLikes(ranked: readonly RankedCandidate[], priority: ReadonlySet<number>): RankedCandidate[] {
  if (priority.size === 0) return [...ranked];
  const first = ranked.filter((candidate) => priority.has(candidate.userId));
  const rest = ranked.filter((candidate) => !priority.has(candidate.userId));
  return [...first, ...rest].map((candidate, index) => ({ ...candidate, rank: index + 1 }));
}
