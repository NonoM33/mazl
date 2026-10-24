// What the matching engine knows about a member. Pure data, read from the
// profile, the swipes and the reports by the infrastructure; the engine never
// reaches for anything else. Free-text answers stay raw here: the engine
// normalises them through the scales of the active parameters.

export type Gender = "male" | "female";
export type LookingFor = Gender | "all";
export type VerificationLevel = "none" | "selfie" | "identity";

export interface GeoPoint {
  readonly latitude: number;
  readonly longitude: number;
}

export interface MatchProfile {
  readonly userId: number;
  readonly gender: Gender | null;
  readonly lookingFor: LookingFor | null;
  // Whole years, null when the birthdate is unknown.
  readonly age: number | null;
  readonly ageMin: number;
  readonly ageMax: number;
  // Kilometres, null for "no limit".
  readonly distanceMaxKm: number | null;
  readonly location: GeoPoint | null;
  readonly denomination: string | null;
  readonly kashrut: string | null;
  readonly shabbat: string | null;
  readonly intention: string | null;
  readonly photoCount: number;
  readonly hasBio: boolean;
  readonly promptCount: number;
  readonly verification: VerificationLevel;
  // ISO timestamps.
  readonly lastActiveAt: string | null;
  readonly createdAt: string;
  readonly boostedUntil: string | null;
  // Popularity: likes and super likes received over the last 7 days.
  readonly likesReceived7d: number;
  // Reports against the member over the last 90 days that were not dismissed.
  readonly openReports90d: number;
}

// Relations between the viewer and the rest of the population. A candidate in
// `excluded` (blocked either way, already swiped, the viewer themself, closed
// account) is NEVER returned, whatever the parameters.
export interface ViewerContext {
  readonly now: string;
  readonly excluded: ReadonlySet<number>;
}
