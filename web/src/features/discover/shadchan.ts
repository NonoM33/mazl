import type { OwnProfileRow, ProfileCard } from "../../shared/api/types";
import { cardPractice, ownPractice, sharedPractice } from "./practice";

// « Le mot du Shadchan »: the daily pick that shares the most practice answers
// with the member. Nothing is invented: only agreeing answers are reported,
// and with none the first pick is simply presented.

export interface ShadchanChoice { readonly pick: ProfileCard; readonly shared: readonly string[] }

export function chooseShadchan(me: OwnProfileRow | null, picks: readonly ProfileCard[]): ShadchanChoice | null {
  const mine = ownPractice(me);
  let best: ShadchanChoice | null = null;
  for (const pick of picks) {
    const shared = sharedPractice(mine, cardPractice(pick));
    if (best === null || shared.length > best.shared.length) best = { pick, shared };
  }
  return best;
}
