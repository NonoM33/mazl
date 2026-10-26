import type { PendingQuery, Row, Sql } from "postgres";
import { DEMO_PHOTO_SQL_PATTERN } from "../domain/stored-photo";

// SQL fragments shared by the monolith's profile-shaped queries. They assume
// the aliases `p` (profiles, possibly NULL after a LEFT JOIN) and `u` (users).
// Taking `sql` as a parameter keeps this module free of an import cycle with
// db.ts.

// CONTRAT.md §3 "Badge": photo_verified needs the timestamp AND a primary photo
// whose face matched; is_verified = photo_verified OR identity_verified.
export function badgeColumns(sql: Sql) {
  return sql`
    (p.photo_verified_at IS NOT NULL AND EXISTS (
      SELECT 1 FROM profile_photos vp
      WHERE vp.user_id = u.id AND vp.is_primary = true AND vp.face_match = true
    )) AS photo_verified,
    (p.identity_verified_at IS NOT NULL) AS identity_verified,
    ((p.photo_verified_at IS NOT NULL AND EXISTS (
      SELECT 1 FROM profile_photos vp
      WHERE vp.user_id = u.id AND vp.is_primary = true AND vp.face_match = true
    )) OR p.identity_verified_at IS NOT NULL) AS is_verified
  `;
}

// A photo row the API may expose: an uploaded file (a storage key) or a stock
// photo of a test profile. Other http(s) rows are legacy and never exposed.
export function displayablePhoto(sql: Sql, url: PendingQuery<Row[]>) {
  return sql`(${url} NOT ILIKE 'http%' OR ${url} ~ ${DEMO_PHOTO_SQL_PATTERN})`;
}

// First displayable uploaded photo (primary first). External legacy rows are
// skipped: they are never exposed.
export function primaryPhotoColumns(sql: Sql) {
  return sql`
    (SELECT pp.id FROM profile_photos pp
       WHERE pp.user_id = u.id AND ${displayablePhoto(sql, sql`pp.url`)}
       ORDER BY pp.is_primary DESC, pp.position ASC, pp.id ASC LIMIT 1) AS primary_photo_id,
    (SELECT pp.url FROM profile_photos pp
       WHERE pp.user_id = u.id AND ${displayablePhoto(sql, sql`pp.url`)}
       ORDER BY pp.is_primary DESC, pp.position ASC, pp.id ASC LIMIT 1) AS primary_photo_url
  `;
}
