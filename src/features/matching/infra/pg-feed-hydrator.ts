import type { Sql } from "postgres";
import { publicPhotoUrls, withPublicPicture } from "../../media/application/photo-urls";
import { badgeColumns, primaryPhotoColumns } from "../../media/infra/sql-fragments";
import type { FeedHydrator, FeedProfile } from "../application/ports";

interface FeedRow {
  readonly user_id: number;
  readonly picture: string | null;
  readonly primary_photo_id: number | null;
  readonly primary_photo_url: string | null;
}

// The exact projection of getDiscoverProfiles (src/db.ts), which the mobile app
// reads: same columns, same photos, same public picture. The order requested by
// the caller is kept. A member who left the feed in the meantime is skipped.
export class PgFeedHydrator implements FeedHydrator {
  constructor(private readonly sql: Sql) {}

  async profilesForFeed(userIds: readonly number[]): Promise<readonly FeedProfile[]> {
    if (userIds.length === 0) return [];
    const sql = this.sql;
    const rows = await sql<FeedRow[]>`
      SELECT
        p.id,
        p.user_id,
        p.display_name,
        DATE_PART('year', AGE(p.birthdate)) as age,
        p.gender,
        p.bio,
        p.location,
        p.denomination,
        p.kashrut_level,
        p.shabbat_observance,
        ${badgeColumns(sql)},
        p.verification_level,
        u.picture,
        ${primaryPhotoColumns(sql)}
      FROM profiles p
      JOIN users u ON u.id = p.user_id
      WHERE p.user_id IN ${sql(userIds)}
    `;
    const photos = await sql<{ id: number; user_id: number; url: string }[]>`
      SELECT id, user_id, url FROM profile_photos
      WHERE user_id IN ${sql(userIds)}
      ORDER BY position ASC
    `;
    const photosByUser = new Map<number, Array<{ id: number; url: string }>>();
    for (const photo of photos) {
      const list = photosByUser.get(photo.user_id) ?? [];
      list.push({ id: photo.id, url: photo.url });
      photosByUser.set(photo.user_id, list);
    }
    const byUser = new Map(rows.map((row) => [row.user_id, row]));
    const ordered: FeedProfile[] = [];
    for (const id of userIds) {
      const raw = byUser.get(id);
      if (raw === undefined) continue;
      const profile = withPublicPicture(raw);
      const urls = publicPhotoUrls(photosByUser.get(id) ?? []);
      ordered.push({ ...profile, photos: urls.length > 0 ? urls : profile.picture ? [profile.picture] : [] });
    }
    return ordered;
  }
}
