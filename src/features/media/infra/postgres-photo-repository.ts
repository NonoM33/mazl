import { sql, addProfilePhoto, deleteProfilePhoto } from "../../../db";
import type { PhotoRepository, StoredPhoto } from "../application/ports";

export const postgresPhotoRepository: PhotoRepository = {
  async addPhoto({ userId, key, isPrimary }) {
    const row = await addProfilePhoto({ userId, url: key, isPrimary });
    return row as unknown as StoredPhoto;
  },

  async findKey(photoId) {
    const rows = await sql<{ url: string }[]>`SELECT url FROM profile_photos WHERE id = ${photoId}`;
    return rows[0]?.url ?? null;
  },

  async deletePhoto(photoId, userId) {
    const rows = await sql<{ url: string }[]>`
      SELECT url FROM profile_photos WHERE id = ${photoId} AND user_id = ${userId}
    `;
    // Throws "Photo not found" when the photo is not the user's (existing behaviour).
    await deleteProfilePhoto(photoId, userId);
    return rows[0]?.url ?? null;
  },

  async findUserPicture(userId) {
    const rows = await sql<{ picture: string | null }[]>`SELECT picture FROM users WHERE id = ${userId}`;
    return rows[0]?.picture ?? null;
  },
};
