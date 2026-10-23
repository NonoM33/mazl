import type { Sql } from "postgres";
import type { ProfilePhotoStore, StoredPhoto } from "../application/ports";

// Reads the file behind a profile_photos.url storage key; null when it is
// missing or not a local file.
export type PhotoFileReader = (storageKey: string) => Promise<Uint8Array | null>;

export class PgProfilePhotoStore implements ProfilePhotoStore {
  constructor(
    private readonly sql: Sql,
    private readonly readFile: PhotoFileReader,
  ) {}

  async listForUser(userId: number): Promise<readonly StoredPhoto[]> {
    const rows = await this.sql<{ id: number; url: string; is_primary: boolean }[]>`
      SELECT id, url, COALESCE(is_primary, false) AS is_primary
      FROM profile_photos WHERE user_id = ${userId}
      ORDER BY COALESCE(is_primary, false) DESC, position ASC NULLS LAST, id ASC
    `;
    return rows.map((r) => ({ id: r.id, storageKey: r.url, isPrimary: r.is_primary }));
  }

  readBytes(storageKey: string): Promise<Uint8Array | null> {
    return this.readFile(storageKey);
  }

  async recordFaceMatch(photoId: number, match: boolean): Promise<void> {
    await this.sql`UPDATE profile_photos SET face_match = ${match}, face_checked_at = NOW() WHERE id = ${photoId}`;
  }

  async clearFaceMatches(userId: number): Promise<void> {
    await this.sql`UPDATE profile_photos SET face_match = NULL, face_checked_at = NULL WHERE user_id = ${userId}`;
  }
}
