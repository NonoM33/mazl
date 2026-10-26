import type { PendingQuery, Row, Sql } from "postgres";
import type { ApplicableFilters, CandidateSet, CandidateSource } from "../application/ports";
import { answerKey, NO_FILTERS, type DiscoverFilters } from "../domain/discover-filters";
import { displayablePhoto } from "../../media/infra/sql-fragments";
import { TEXT_OID } from "./pg-types";
import type { Gender, LookingFor, MatchProfile, VerificationLevel } from "../domain/profile";

type Fragment = PendingQuery<Row[]>;

// Hard ceiling of the SQL prefilter: the engine ranks at most this many people.
export const CANDIDATE_CEILING = 1000;

interface ProfileRow {
  readonly user_id: number;
  readonly gender: Gender | null;
  readonly looking_for: LookingFor | null;
  readonly age: number | null;
  readonly age_min: number | null;
  readonly age_max: number | null;
  readonly distance_max: number | null;
  readonly latitude: string | null;
  readonly longitude: string | null;
  readonly denomination: string | null;
  readonly kashrut_level: string | null;
  readonly shabbat_observance: string | null;
  readonly relationship_intention: string | null;
  readonly photo_count: number;
  readonly has_bio: boolean;
  readonly prompt_count: number;
  readonly verification_level: string | null;
  readonly last_login_at: Date | null;
  readonly created_at: Date;
  readonly boosted_until: Date | null;
  readonly likes_7d: number;
  readonly reports_90d: number;
}

const DEFAULT_AGE_MIN = 18;
const DEFAULT_AGE_MAX = 99;

// profiles.verification_level is written as 'none', 'photo' (selfie checked),
// 'identity' (and defaults to 'none'). 'selfie' is accepted for the same
// meaning as 'photo'; anything else counts as unverified.
export function verificationOf(level: string | null): VerificationLevel {
  if (level === "identity") return "identity";
  return level === "photo" || level === "selfie" ? "selfie" : "none";
}

function toMatchProfile(row: ProfileRow): MatchProfile {
  const located = row.latitude !== null && row.longitude !== null;
  return {
    userId: row.user_id,
    gender: row.gender,
    lookingFor: row.looking_for,
    age: row.age,
    ageMin: row.age_min ?? DEFAULT_AGE_MIN,
    ageMax: row.age_max ?? DEFAULT_AGE_MAX,
    distanceMaxKm: row.distance_max,
    location: located ? { latitude: Number(row.latitude), longitude: Number(row.longitude) } : null,
    denomination: row.denomination,
    kashrut: row.kashrut_level,
    shabbat: row.shabbat_observance,
    intention: row.relationship_intention,
    photoCount: row.photo_count,
    hasBio: row.has_bio,
    promptCount: row.prompt_count,
    verification: verificationOf(row.verification_level),
    lastActiveAt: row.last_login_at === null ? null : row.last_login_at.toISOString(),
    createdAt: row.created_at.toISOString(),
    boostedUntil: row.boosted_until === null ? null : row.boosted_until.toISOString(),
    likesReceived7d: row.likes_7d,
    openReports90d: row.reports_90d,
  };
}

export class PgCandidateSource implements CandidateSource {
  // `filters` decides which advanced filters apply to the viewer (mazl+,
  // consent); without it none do.
  constructor(
    private readonly sql: Sql,
    private readonly filters?: ApplicableFilters,
  ) {}

  async load(userId: number): Promise<CandidateSet | null> {
    const [viewerRows, filters] = await Promise.all([
      this.selectProfiles(this.sql`WHERE p.user_id = ${userId}`, 1),
      this.filters?.applicableFor(userId) ?? Promise.resolve(NO_FILTERS),
    ]);
    const viewerRow = viewerRows[0];
    if (viewerRow === undefined) return null;
    const viewer = toMatchProfile(viewerRow);
    const [candidateRows, excluded] = await Promise.all([
      this.selectProfiles(this.prefilter(viewer, filters), CANDIDATE_CEILING),
      this.excludedIds(userId),
    ]);
    return { viewer, candidates: candidateRows.map(toMatchProfile), excluded, filters };
  }

  // Only narrows the population, never widens it: the engine filters again.
  // The advanced filters are applied here too, before the ceiling, so that a
  // narrow filter is not starved by the 1000 most recent members.
  private prefilter(viewer: MatchProfile, filters: DiscoverFilters) {
    const sql = this.sql;
    return sql`
      WHERE p.user_id <> ${viewer.userId}
        AND u.is_active = true
        AND p.is_complete = true
        AND NOT EXISTS (SELECT 1 FROM swipes s WHERE s.user_id = ${viewer.userId} AND s.target_user_id = p.user_id)
        AND NOT EXISTS (
          SELECT 1 FROM blocked_users b
          WHERE (b.blocker_id = ${viewer.userId} AND b.blocked_id = p.user_id)
             OR (b.blocker_id = p.user_id AND b.blocked_id = ${viewer.userId})
        )
        AND NOT EXISTS (
          SELECT 1 FROM member_sanctions s
          WHERE s.user_id = p.user_id AND s.revoked_at IS NULL AND s.starts_at <= now()
            AND (s.ends_at IS NULL OR s.ends_at > now())
            AND s.kind IN ('restriction', 'suspension', 'ban')
        )
        AND (${viewer.lookingFor}::text IS NULL OR ${viewer.lookingFor}::text = 'all'
             OR ${genderOf(sql)} IS NULL OR ${genderOf(sql)} = ${viewer.lookingFor}::text)
        AND (${lookingForOf(sql)} IS NULL OR ${lookingForOf(sql)} = 'all'
             OR ${viewer.gender}::text IS NULL OR ${lookingForOf(sql)} = ${viewer.gender}::text)
        ${this.advancedFilters(filters)}
    `;
  }

  // Same rules as domain/discover-filters.ts (candidateMatchesFilters): an
  // answer is compared trimmed and lower-cased, a missing answer never passes.
  private advancedFilters(filters: DiscoverFilters) {
    const sql = this.sql;
    const answerIn = (column: Fragment, accepted: readonly string[] | null) =>
      accepted === null ? sql`` : sql`AND lower(btrim(${column})) = ANY(${sql.array(accepted.map(answerKey), TEXT_OID)})`;
    return sql`
      ${answerIn(sql`p.denomination`, filters.denominations)}
      ${answerIn(sql`p.kashrut_level`, filters.kashrutLevels)}
      ${answerIn(sql`p.shabbat_observance`, filters.shabbatObservances)}
      ${filters.onlyVerified ? sql`AND p.verification_level IN ('photo', 'selfie', 'identity')` : sql``}
      ${filters.onlyWithPhoto ? sql`AND EXISTS (SELECT 1 FROM profile_photos ph WHERE ph.user_id = p.user_id AND ${displayablePhoto(sql, sql`ph.url`)})` : sql``}
    `;
  }

  private selectProfiles(where: PendingQuery<Row[]>, limit: number) {
    const sql = this.sql;
    return sql<ProfileRow[]>`
      SELECT
        p.user_id,
        ${genderOf(sql)} AS gender,
        ${lookingForOf(sql)} AS looking_for,
        DATE_PART('year', AGE(p.birthdate))::int AS age,
        p.age_min, p.age_max, p.distance_max, p.latitude, p.longitude,
        p.denomination, p.kashrut_level, p.shabbat_observance, p.relationship_intention,
        (SELECT count(*)::int FROM profile_photos ph WHERE ph.user_id = p.user_id AND ${displayablePhoto(sql, sql`ph.url`)}) AS photo_count,
        (p.bio IS NOT NULL AND btrim(p.bio) <> '') AS has_bio,
        (SELECT count(*)::int FROM profile_prompts pr WHERE pr.user_id = p.user_id) AS prompt_count,
        p.verification_level,
        u.last_login_at,
        u.created_at,
        (SELECT max(bo.expires_at) FROM boosts bo WHERE bo.user_id = p.user_id) AS boosted_until,
        (SELECT count(*)::int FROM swipes sw
           WHERE sw.target_user_id = p.user_id AND sw.action IN ('like', 'super_like')
             AND sw.created_at > now() - interval '7 days') AS likes_7d,
        (SELECT count(*)::int FROM reports r
           WHERE r.reported_user_id = p.user_id AND COALESCE(r.status, '') <> 'dismissed'
             AND r.created_at > now() - interval '90 days') AS reports_90d
      FROM profiles p
      JOIN users u ON u.id = p.user_id
      ${where}
      ORDER BY u.last_login_at DESC NULLS LAST, p.user_id DESC
      LIMIT ${limit}
    `;
  }

  private async excludedIds(userId: number): Promise<ReadonlySet<number>> {
    const rows = await this.sql<{ id: number }[]>`
      SELECT target_user_id AS id FROM swipes WHERE user_id = ${userId}
      UNION SELECT blocked_id FROM blocked_users WHERE blocker_id = ${userId}
      UNION SELECT blocker_id FROM blocked_users WHERE blocked_id = ${userId}
    `;
    return new Set(rows.map((r) => r.id));
  }
}

const genderOf = (sql: Sql) => sql`(CASE WHEN lower(p.gender) IN ('male', 'female') THEN lower(p.gender) END)`;

const lookingForOf = (sql: Sql) => sql`(CASE
  WHEN lower(p.looking_for) IN ('male', 'female') THEN lower(p.looking_for)
  WHEN lower(p.looking_for) IN ('all', 'any', 'everyone', 'both') THEN 'all'
END)`;
