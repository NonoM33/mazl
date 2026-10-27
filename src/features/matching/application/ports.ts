import type { MatchingParams } from "../domain/params";
import type { DiscoverFilters } from "../domain/discover-filters";
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
  // Advanced filters applied to the viewer (mazl+ and consent already checked).
  // Absent = none.
  readonly filters?: DiscoverFilters;
  // Candidates who already liked the viewer and are mazl+ members: shown first
  // (their likes are priority likes). Absent = none.
  readonly priority?: ReadonlySet<number>;
}

export interface CandidateSource {
  // null when the member has no profile.
  load(userId: number): Promise<CandidateSet | null>;
}

// Profiles in the exact shape of the member app, in the order requested.
export type FeedProfile = Readonly<Record<string, unknown>>;

export interface FeedHydrator {
  // `viewerId`: the member the profiles are shown to, for what concerns them
  // (a Super Like they received, a member travelling with a passport).
  profilesForFeed(userIds: readonly number[], viewerId?: number): Promise<readonly FeedProfile[]>;
}

export interface FeedPage {
  readonly limit: number;
  readonly offset: number;
}

// The member's advanced filters, one row per member.
export interface DiscoverFiltersStore {
  // NO_FILTERS when the member never set any.
  get(userId: number): Promise<DiscoverFilters>;
  save(userId: number, filters: DiscoverFilters): Promise<void>;
}

// What the filters depend on besides the member's own choices.
export interface FilterEntitlements {
  isPlus(userId: number): Promise<boolean>;
  // A valid GDPR art. 9 consent to the current wording.
  allowsReligiousData(userId: number): Promise<boolean>;
}

// The filters the feed must apply to a viewer (NO_FILTERS when none apply).
export interface ApplicableFilters {
  applicableFor(userId: number): Promise<DiscoverFilters>;
}
