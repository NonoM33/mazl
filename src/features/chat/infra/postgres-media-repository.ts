import { sql } from "../../../db";
import type { MediaRepository } from "../application/ports";
import { mediaColumns, mediaOf, type MediaRow } from "./row-mappers";

export const postgresMediaRepository: MediaRepository = {
  async insert(media) {
    const rows = await sql<MediaRow[]>`
      INSERT INTO message_media (conversation_id, uploader_id, kind, storage_key, width, height, duration_ms, waveform, role)
      VALUES (${media.conversationId}, ${media.uploaderId}, ${media.kind}, ${media.storageKey}, ${media.width}, ${media.height},
              ${media.durationMs}, ${media.waveform === null ? null : sql.json([...media.waveform])}, ${media.role ?? "attachment"})
      RETURNING ${mediaColumns(sql)}
    `;
    const row = rows[0];
    if (row === undefined) throw new Error("message_media insert returned no row");
    return mediaOf(row);
  },

  async find(id) {
    const rows = await sql<MediaRow[]>`SELECT ${mediaColumns(sql)} FROM message_media WHERE id = ${id}`;
    return rows[0] === undefined ? null : mediaOf(rows[0]);
  },

  async countPending(uploaderId) {
    const rows = await sql<Array<{ n: string }>>`
      SELECT COUNT(*) AS n FROM message_media WHERE uploader_id = ${uploaderId} AND message_id IS NULL AND role = 'attachment'
    `;
    return Number(rows[0]?.n ?? 0);
  },

  async listOrphans(olderThan, limit) {
    const rows = await sql<MediaRow[]>`
      SELECT ${mediaColumns(sql)} FROM message_media
      WHERE message_id IS NULL AND role = 'attachment' AND created_at < ${olderThan}
      ORDER BY created_at LIMIT ${limit}
    `;
    return rows.map(mediaOf);
  },

  async delete(ids) {
    if (ids.length === 0) return;
    await sql`DELETE FROM message_media WHERE id = ANY(${sql.array([...ids], 23)})`;
  },

  async storageKeysOfUser(userId) {
    const rows = await sql<Array<{ storage_key: string }>>`
      SELECT mm.storage_key FROM message_media mm
      JOIN conversations c ON c.id = mm.conversation_id
      WHERE c.user1_id = ${userId} OR c.user2_id = ${userId}
    `;
    return rows.map((row) => row.storage_key);
  },

  async referencedKeys(keys) {
    if (keys.length === 0) return new Set<string>();
    const media = await sql<Array<{ key: string }>>`
      SELECT storage_key AS key FROM message_media WHERE storage_key IN ${sql([...keys])}
    `;
    const cache = await sql<Array<{ key: string }>>`
      SELECT data->>'imageKey' AS key FROM link_preview_cache WHERE data->>'imageKey' IN ${sql([...keys])}
    `;
    return new Set([...media, ...cache].map((row) => row.key));
  },
};
