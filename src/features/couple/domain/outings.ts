import { addDays, dayKey, localParts } from "./local-time";

// Outings of the couple (section 4): the activities and the couple events in one
// list, filtered for the screen.

export const OUTING_FILTERS = ["tonight", "week", "kosher", "cheap", "mazl"] as const;
export type OutingFilter = (typeof OUTING_FILTERS)[number];

export interface Outing {
  readonly id: number;
  readonly kind: "activity" | "event";
  readonly title: string;
  readonly subtitle: string;
  readonly imageUrl: string | null;
  readonly city: string | null;
  readonly startsAt: string | null;
  readonly priceCents: number | null;
  readonly kosher: boolean;
  readonly saved: boolean;
}

// What the filters need beyond the public shape.
export interface OutingCandidate extends Outing {
  readonly partner: boolean;
  readonly featured: boolean;
}

// Up to this price (inclusive, in cents) an outing is "cheap".
export const CHEAP_MAX_CENTS = 4000;
const WEEK_DAYS = 7;

export function matchesFilter(outing: OutingCandidate, filter: OutingFilter | undefined, now: Date, timeZone: string): boolean {
  if (filter === undefined) return true;
  if (filter === "kosher") return outing.kosher;
  if (filter === "cheap") return outing.priceCents !== null && outing.priceCents <= CHEAP_MAX_CENTS;
  // MAZL: what MAZL partners offer and what MAZL features.
  if (filter === "mazl") return outing.partner || outing.featured;
  if (outing.startsAt === null) return false;
  const local = localParts(now, timeZone);
  const today = { year: local.year, month: local.month, day: local.day };
  const startsOn = (() => {
    const p = localParts(new Date(outing.startsAt), timeZone);
    return dayKey({ year: p.year, month: p.month, day: p.day });
  })();
  if (filter === "tonight") return startsOn === dayKey(today);
  return startsOn >= dayKey(today) && startsOn <= dayKey(addDays(today, WEEK_DAYS));
}

export function publicOuting(candidate: OutingCandidate): Outing {
  const { partner: _partner, featured: _featured, ...outing } = candidate;
  return outing;
}

// The featured outing: a featured event first, then a partner activity, then
// whatever comes first. Null when the list is empty.
export function pickFeatured(candidates: readonly OutingCandidate[]): OutingCandidate | null {
  return (
    candidates.find((candidate) => candidate.kind === "event" && candidate.featured) ??
    candidates.find((candidate) => candidate.partner) ??
    candidates[0] ??
    null
  );
}

// One outing a day for the Today screen, the same all day for a given couple.
export function pickOfTheDay(candidates: readonly OutingCandidate[], coupleId: number, dayNumber: number): OutingCandidate | null {
  if (candidates.length === 0) return null;
  return candidates[(dayNumber + coupleId) % candidates.length] ?? null;
}
