import { rankCandidates } from "../domain/engine";
import { seedFrom } from "../domain/random";
import type { CandidateSource, FeedHydrator, FeedPage, FeedProfile, ParamsRepository, ParamsVersion, MatchingState } from "./ports";

// The exploration slots are drawn inside a window that does not depend on the
// page asked for: page 1 and page 2 are slices of one and the same ordering.
export const RANKING_WINDOW = 50;
export const DAILY_PICKS_COUNT = 5;

export interface FeedDeps {
  readonly params: Pick<ParamsRepository, "getState">;
  readonly candidates: CandidateSource;
  readonly hydrator: FeedHydrator;
  readonly clock?: () => Date;
}

export interface RankedFeed {
  readonly userIds: readonly number[];
  readonly versionId: number;
}

export interface Feed {
  rank(userId: number, page: FeedPage): Promise<RankedFeed>;
  discover(userId: number, page: FeedPage): Promise<readonly FeedProfile[]>;
  dailyPicks(userId: number): Promise<readonly FeedProfile[]>;
}

// A member is in the A/B test when their stable bucket falls under the share.
export function inAbTestShare(userId: number, sharePercent: number): boolean {
  return seedFrom("ab", userId) % 100 < sharePercent;
}

const parisDayFormat = new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Paris", year: "numeric", month: "2-digit", day: "2-digit" });

// YYYY-MM-DD in Paris: the feed reshuffles its exploration once a day there.
export function parisDay(date: Date): string {
  return parisDayFormat.format(date);
}

// Why a feed came back empty, in counts only (no profile data): how many
// candidates the database offered, and how many the engine set aside, by reason.
export function emptyFeedReport(
  userId: number,
  page: FeedPage,
  candidates: number,
  exclusions: readonly { readonly reason: string }[],
): string {
  const byReason = new Map<string, number>();
  for (const exclusion of exclusions) byReason.set(exclusion.reason, (byReason.get(exclusion.reason) ?? 0) + 1);
  const reasons = [...byReason.entries()].map(([reason, n]) => `${reason}=${n}`).join(" ");
  return `Empty Discover for user ${userId} (offset ${page.offset}): ${candidates} candidate(s) from the database${reasons === "" ? "" : `, set aside: ${reasons}`}`;
}

function versionFor(userId: number, state: MatchingState): ParamsVersion {
  const ab = state.abTest;
  return ab !== null && inAbTestShare(userId, ab.sharePercent) ? ab.variant : state.active;
}

export function createFeed(deps: FeedDeps): Feed {
  const clock = deps.clock ?? (() => new Date());

  async function rank(userId: number, page: FeedPage): Promise<RankedFeed> {
    const state = await deps.params.getState();
    const version = versionFor(userId, state);
    const set = await deps.candidates.load(userId);
    if (set === null) return { userIds: [], versionId: version.id };
    const now = clock();
    const seed = seedFrom(userId, parisDay(now), version.id);
    const ctx = { now: now.toISOString(), excluded: set.excluded, filters: set.filters };
    const result = rankCandidates(set.viewer, set.candidates, ctx, version.params, seed, RANKING_WINDOW);
    const userIds = result.ranked.slice(page.offset, page.offset + page.limit).map((c) => c.userId);
    if (userIds.length === 0) {
      const f = set.filters;
      const viewer = `viewer gender=${set.viewer.gender ?? "?"} looking_for=${set.viewer.lookingFor ?? "?"} age=${set.viewer.age ?? "?"} range=${set.viewer.ageMin}-${set.viewer.ageMax}`;
      const filters = `filters denominations=${f?.denominations?.length ?? "-"} kashrut=${f?.kashrutLevels?.length ?? "-"} shabbat=${f?.shabbatObservances?.length ?? "-"} verified=${f?.onlyVerified ?? false} photo=${f?.onlyWithPhoto ?? false}`;
      console.log(`${emptyFeedReport(userId, page, set.candidates.length, result.exclusions)} | ${viewer} | ${filters} | excluded ids=${set.excluded.size}`);
    }
    return { userIds, versionId: version.id };
  }

  return {
    rank,
    // Scores never leave this function: only profiles, in the ranked order.
    async discover(userId, page) {
      const { userIds } = await rank(userId, page);
      return deps.hydrator.profilesForFeed(userIds);
    },
    dailyPicks(userId) {
      return this.discover(userId, { limit: DAILY_PICKS_COUNT, offset: 0 });
    },
  };
}
