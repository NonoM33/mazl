import { sql, addProfilePhoto, deleteProfilePhoto, ProfilePhotoLimitError } from "../../../db";
import { PhotoLimitError } from "../domain/errors";
import type { PhotoRepository, StoredPhoto } from "../application/ports";

export const postgresPhotoRepository: PhotoRepository = {
  async addPhoto({ userId, key, isPrimary }) {
    try {
      const row = await addProfilePhoto({ userId, url: key, isPrimary });
      return row as unknown as StoredPhoto;
    } catch (error: unknown) {
      if (error instanceof ProfilePhotoLimitError) throw new PhotoLimitError();
      throw error;
    }
  },

  async findKey(photoId) {
    const rows = await sql<{ url: string }[]>`SELECT url FROM profile_photos WHERE id = ${photoId}`;
    return rows[0]?.url ?? null;
  },

  async deletePhoto(photoId, userId) {
    const rows = await sql<{ url: string }[]>`
      SELECT url FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId}
    `;
    // Throws ProfilePhotoNotFoundError when the photo is not the user's.
    await deleteProfilePhoto(photoId, userId);
    return rows[0]?.url ?? null;
  },

  async listUserKeys(userId) {
    const rows = await sql<{ url: string }[]>`SELECT url FROM profile_photos WHERE user_id = ${userId}`;
    return rows.map((r) => r.url);
  },

  async findUserPicture(userId) {
    const rows = await sql<{ picture: string | null }[]>`SELECT picture FROM users WHERE id = ${userId}`;
    return rows[0]?.picture ?? null;
  },
};
