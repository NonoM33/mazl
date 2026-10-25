import type { MatchProfile } from "./profile";

// The advanced filters of Discover (mazl+). They describe who the member wants
// to see, not who the member is: they live in their own table, never in the
// profile (CONTRAT v1 §2).

export interface DiscoverFilters {
  // Stored answers of profiles.denomination / kashrut_level / shabbat_observance
  // the member accepts. null = no criterion.
  readonly denominations: readonly string[] | null;
  readonly kashrutLevels: readonly string[] | null;
  readonly shabbatObservances: readonly string[] | null;
  readonly onlyVerified: boolean;
  readonly onlyWithPhoto: boolean;
}

// A change to the filters: an absent field is kept, null (or an empty list) clears it.
export interface DiscoverFiltersPatch {
  readonly denominations?: readonly string[] | null;
  readonly kashrutLevels?: readonly string[] | null;
  readonly shabbatObservances?: readonly string[] | null;
  readonly onlyVerified?: boolean;
  readonly onlyWithPhoto?: boolean;
}

export const NO_FILTERS: DiscoverFilters = {
  denominations: null,
  kashrutLevels: null,
  shabbatObservances: null,
  onlyVerified: false,
  onlyWithPhoto: false,
};

// How two answers are compared: stored answers are free text written by
// different versions of the app ("Massorti", " massorti ").
export function answerKey(answer: string): string {
  return answer.trim().toLowerCase();
}

export function hasReligiousCriterion(filters: DiscoverFilters): boolean {
  return filters.denominations !== null || filters.kashrutLevels !== null || filters.shabbatObservances !== null;
}

export function hasCriterion(filters: DiscoverFilters): boolean {
  return hasReligiousCriterion(filters) || filters.onlyVerified || filters.onlyWithPhoto;
}

export function withoutReligiousCriteria(filters: DiscoverFilters): DiscoverFilters {
  return { ...filters, denominations: null, kashrutLevels: null, shabbatObservances: null };
}

export interface MemberEntitlements {
  readonly plus: boolean;
  // A valid art. 9 consent to the current wording.
  readonly religiousConsent: boolean;
}

// The criteria actually applied to the feed. The stored ones are kept as they
// are when mazl+ expires, they just stop acting.
export function applicableFilters(stored: DiscoverFilters, member: MemberEntitlements): DiscoverFilters {
  if (!member.plus) return NO_FILTERS;
  return member.religiousConsent ? stored : withoutReligiousCriteria(stored);
}

function acceptedAnswer(accepted: readonly string[] | null, answer: string | null): boolean {
  if (accepted === null) return true;
  if (answer === null) return false;
  const key = answerKey(answer);
  return key !== "" && accepted.some((wanted) => answerKey(wanted) === key);
}

export function candidateMatchesFilters(candidate: MatchProfile, filters: DiscoverFilters): boolean {
  if (filters.onlyVerified && candidate.verification === "none") return false;
  if (filters.onlyWithPhoto && candidate.photoCount < 1) return false;
  return (
    acceptedAnswer(filters.denominations, candidate.denomination) &&
    acceptedAnswer(filters.kashrutLevels, candidate.kashrut) &&
    acceptedAnswer(filters.shabbatObservances, candidate.shabbat)
  );
}

// Trimmed, without blanks or duplicates (case-insensitive); an empty list is "no criterion".
function cleanList(list: readonly string[] | null | undefined): readonly string[] | null {
  if (list === null || list === undefined) return null;
  const seen = new Set<string>();
  const kept: string[] = [];
  for (const answer of list) {
    const key = answerKey(answer);
    if (key === "" || seen.has(key)) continue;
    seen.add(key);
    kept.push(answer.trim());
  }
  return kept.length === 0 ? null : kept;
}

function listAfter(current: readonly string[] | null, patched: readonly string[] | null | undefined): readonly string[] | null {
  return patched === undefined ? current : cleanList(patched);
}

export function applyPatch(current: DiscoverFilters, patch: DiscoverFiltersPatch): DiscoverFilters {
  return {
    denominations: listAfter(current.denominations, patch.denominations),
    kashrutLevels: listAfter(current.kashrutLevels, patch.kashrutLevels),
    shabbatObservances: listAfter(current.shabbatObservances, patch.shabbatObservances),
    onlyVerified: patch.onlyVerified ?? current.onlyVerified,
    onlyWithPhoto: patch.onlyWithPhoto ?? current.onlyWithPhoto,
  };
}

export function patchAsksForReligiousCriteria(patch: DiscoverFiltersPatch): boolean {
  return (
    cleanList(patch.denominations) !== null ||
    cleanList(patch.kashrutLevels) !== null ||
    cleanList(patch.shabbatObservances) !== null
  );
}

// Every criterion is mazl+: asking for one needs the subscription, removing one never does.
export function patchAsksForAdvancedCriteria(patch: DiscoverFiltersPatch): boolean {
  return patchAsksForReligiousCriteria(patch) || patch.onlyVerified === true || patch.onlyWithPhoto === true;
}
