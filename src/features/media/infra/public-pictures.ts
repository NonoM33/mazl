import type { Sql } from "postgres";
import { withPublicPicture } from "../application/photo-urls";
import { primaryPhotoColumns } from "./sql-fragments";

// What may be shown as "the picture" of each given member: the primary uploaded
// photo as a signed URL, else a Google avatar, else null. For queries that
// pair two members in one row (couples, match events). `sql` is a parameter to
// stay free of an import cycle with db.ts.
export async function publicPicturesFor(
  sql: Sql,
  userIds: readonly number[],
): Promise<Map<number, string | null>> {
  const pictures = new Map<number, string | null>();
  if (userIds.length === 0) return pictures;
  const rows = await sql`
    SELECT u.id, u.picture, ${primaryPhotoColumns(sql)}
    FROM users u
    WHERE u.id IN ${sql([...userIds])}
  `;
  for (const row of rows) {
    const shown = withPublicPicture(row as unknown as Parameters<typeof withPublicPicture>[0]);
    pictures.set(Number(row.id), shown.picture);
  }
  return pictures;
}
