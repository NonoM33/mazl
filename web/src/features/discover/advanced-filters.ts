import type { ProfileCard } from "../../shared/api/types";
import { DENOMINATION_CHOICES, INTENTION_CHOICES, KASHRUT_CHOICES, SHABBAT_CHOICES, type Choice } from "../../shared/lib/profile-labels";
import { cardPractice, practiceLabel, PRACTICE_KINDS, type PracticeKind } from "./practice";

// mazl+ advanced filters. The API has none: they narrow the lot already
// received, client side. A filter holds the readable label it keeps.

export interface AdvancedFilters {
  readonly denomination: string | null;
  readonly kashrut: string | null;
  readonly shabbat: string | null;
  readonly intention: string | null;
  readonly verifiedOnly: boolean;
}

export const NO_FILTERS: AdvancedFilters = { denomination: null, kashrut: null, shabbat: null, intention: null, verifiedOnly: false };

const CHOICES: Readonly<Record<PracticeKind, readonly Choice[]>> = {
  denomination: DENOMINATION_CHOICES,
  kashrut: KASHRUT_CHOICES,
  shabbat: SHABBAT_CHOICES,
  intention: INTENTION_CHOICES,
};

// Answers that show as a chip on a profile, one entry per label.
export function filterOptions(kind: PracticeKind): readonly string[] {
  const labels = CHOICES[kind].map((choice) => practiceLabel(kind, choice.value)).filter((label): label is string => label !== null);
  return [...new Set(labels)];
}

export function hasActiveFilters(filters: AdvancedFilters): boolean {
  return filters.verifiedOnly || PRACTICE_KINDS.some((kind) => filters[kind] !== null);
}

export function matchesFilters(profile: ProfileCard, filters: AdvancedFilters): boolean {
  if (filters.verifiedOnly && !profile.is_verified) return false;
  const practice = cardPractice(profile);
  return PRACTICE_KINDS.every((kind) => {
    const wanted = filters[kind];
    return wanted === null || practiceLabel(kind, practice[kind]) === wanted;
  });
}

export function applyFilters(profiles: readonly ProfileCard[], filters: AdvancedFilters): readonly ProfileCard[] {
  return hasActiveFilters(filters) ? profiles.filter((profile) => matchesFilters(profile, filters)) : profiles;
}
