import type { MatchingParams } from "../domain/params";
import type { MatchProfile } from "../domain/profile";

export interface ParamsVersion {
  readonly id: number;
  readonly params: MatchingParams;
  readonly note: string;
  readonly author: string;
  readonly createdAt: string;
  readonly parentId: number | null;
}

export interface VersionListing extends ParamsVersion {
  // Last time the version became the active one, null if it never was.
  readonly activatedAt: string | null;
}

export interface AbTest {
  readonly variant: ParamsVersion;
  readonly sharePercent: number;
  readonly startedAt: string;
  readonly startedBy: string;
}

export interface MatchingState {
  readonly active: ParamsVersion;
  readonly activatedAt: string;
  readonly activatedBy: string;
  readonly abTest: AbTest | null;
}

export interface NewVersion {
  readonly params: MatchingParams;
  readonly note: string;
  readonly author: string;
  readonly parentId: number | null;
}

export interface ActivationOutcome {
  readonly previousVersionId: number;
  // True when the activated version was the running A/B variant: the test ends.
  readonly abTestEnded: boolean;
}

export interface ParamsRepository {
  createVersion(input: NewVersion): Promise<ParamsVersion>;
  listVersions(page: { readonly limit: number; readonly offset: number }): Promise<{ readonly versions: readonly VersionListing[]; readonly total: number }>;
  getVersion(id: number): Promise<ParamsVersion | null>;
  // Active version and running A/B test (cached, see PgParamsRepository).
  getState(): Promise<MatchingState>;
  activate(versionId: number, by: string, note: string): Promise<ActivationOutcome>;
  startAbTest(variantId: number, sharePercent: number, by: string): Promise<void>;
  stopAbTest(): Promise<void>;
}

// What the infrastructure hands the engine for one viewer.
export interface CandidateSet {
  readonly viewer: MatchProfile;
  readonly candidates: readonly MatchProfile[];
  // Swiped and blocked members (either way): the engine refilters them.
  readonly excluded: ReadonlySet<number>;
}

export interface CandidateSource {
  // null when the member has no profile.
  load(userId: number): Promise<CandidateSet | null>;
}

// Profiles in the exact shape of the member app, in the order requested.
export type FeedProfile = Readonly<Record<string, unknown>>;

export interface FeedHydrator {
  profilesForFeed(userIds: readonly number[]): Promise<readonly FeedProfile[]>;
}

export interface FeedPage {
  readonly limit: number;
  readonly offset: number;
}
