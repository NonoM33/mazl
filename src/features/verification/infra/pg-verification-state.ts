import type { Sql } from "postgres";
import type { PhotoBadgeState, VerificationStateRepository } from "../application/ports";

// The main photo is the first one by the same order as ProfilePhotoStore.
const PRIMARY_FACE_MATCH = (sql: Sql, userId: number) => sql`
  COALESCE((
    SELECT face_match FROM profile_photos
    WHERE user_id = ${userId}
    ORDER BY COALESCE(is_primary, false) DESC, position ASC NULLS LAST, id ASC
    LIMIT 1
  ), false)
`;

export class PgVerificationState implements VerificationStateRepository {
  constructor(private readonly sql: Sql) {}

  async markPhotoVerified(userId: number): Promise<void> {
    await this.sql`UPDATE profiles SET photo_verified_at = NOW() WHERE user_id = ${userId}`;
    await this.refreshBadge(userId);
  }

  async clearPhotoVerified(userId: number): Promise<void> {
    await this.sql`UPDATE profiles SET photo_verified_at = NULL WHERE user_id = ${userId}`;
    await this.refreshBadge(userId);
  }

  // profiles.is_verified and verification_level are read all over the app:
  // keep them equal to "photo verified OR identity verified". A manual
  // identity review (level 'identity') is never downgraded here.
  async refreshBadge(userId: number): Promise<void> {
    await this.sql`
      UPDATE profiles p SET
        is_verified = (s.photo_ok OR s.identity_ok),
        verification_level = CASE
          WHEN s.identity_ok THEN 'identity'
          WHEN s.photo_ok THEN 'photo'
          WHEN p.verification_level = 'photo' THEN 'none'
          ELSE p.verification_level END,
        updated_at = NOW()
      FROM (
        SELECT user_id,
               (photo_verified_at IS NOT NULL AND ${PRIMARY_FACE_MATCH(this.sql, userId)}) AS photo_ok,
               (identity_verified_at IS NOT NULL OR verification_level = 'identity') AS identity_ok
        FROM profiles WHERE user_id = ${userId}
      ) s
      WHERE p.user_id = s.user_id
    `;
  }

  async read(userId: number): Promise<PhotoBadgeState> {
    const [row] = await this.sql<
      { photo_verified_at: Date | null; identity_verified_at: Date | null; primary_match: boolean }[]
    >`
      SELECT photo_verified_at AT TIME ZONE current_setting('TimeZone') AS photo_verified_at,
             identity_verified_at AT TIME ZONE current_setting('TimeZone') AS identity_verified_at,
             ${PRIMARY_FACE_MATCH(this.sql, userId)} AS primary_match
      FROM profiles WHERE user_id = ${userId}
    `;
    return {
      photoVerifiedAt: row?.photo_verified_at ?? null,
      identityVerifiedAt: row?.identity_verified_at ?? null,
      primaryPhotoMatches: row?.primary_match ?? false,
    };
  }
}
