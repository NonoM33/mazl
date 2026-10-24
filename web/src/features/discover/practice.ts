import type { OwnProfileRow, ProfileCard } from "../../shared/api/types";
import { profileLabels } from "../../shared/lib/profile-labels";

// The four practice answers, compared through their readable label: the label
// table is built on answerKey(), so "Cacher à la maison" matches whether a
// profile stored « A la maison » or `kasher_a_la_maison`. A hidden answer
// (« Non », « Autre ») has no label and is never counted as shared.

export const PRACTICE_KINDS = ["denomination", "kashrut", "shabbat", "intention"] as const;
export type PracticeKind = (typeof PRACTICE_KINDS)[number];
export type PracticeAnswers = Readonly<Record<PracticeKind, string | null | undefined>>;

export function practiceLabel(kind: PracticeKind, raw: string | null | undefined): string | null {
  return profileLabels[kind](raw);
}

export function cardPractice(profile: ProfileCard): PracticeAnswers {
  return { denomination: profile.denomination, kashrut: profile.kashrut_level, shabbat: profile.shabbat_observance, intention: profile.relationship_intention };
}

export function ownPractice(profile: OwnProfileRow | null): PracticeAnswers {
  return { denomination: profile?.denomination, kashrut: profile?.kashrut_level, shabbat: profile?.shabbat_observance, intention: profile?.relationship_intention };
}

// Labels of the answers both members gave and that agree, in display order.
export function sharedPractice(mine: PracticeAnswers, theirs: PracticeAnswers): string[] {
  const shared: string[] = [];
  for (const kind of PRACTICE_KINDS) {
    const a = practiceLabel(kind, mine[kind]);
    if (a !== null && a === practiceLabel(kind, theirs[kind])) shared.push(a);
  }
  return shared;
}
