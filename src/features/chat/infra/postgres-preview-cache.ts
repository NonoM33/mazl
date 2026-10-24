import { z } from "zod";
import { sql } from "../../../db";
import type { PreviewCache, PreviewCacheData } from "../application/ports";

const dataSchema = z.object({
  title: z.string().nullable(),
  description: z.string().nullable(),
  siteName: z.string().nullable(),
  imageKey: z.string().nullable(),
  imageWidth: z.number().nullable(),
  imageHeight: z.number().nullable(),
});

function dataOf(raw: unknown): PreviewCacheData | null {
  const parsed = dataSchema.safeParse(raw);
  return parsed.success ? parsed.data : null;
}

export const postgresPreviewCache: PreviewCache = {
  async get(url, notOlderThan) {
    const rows = await sql<Array<{ data: unknown }>>`
      SELECT data FROM link_preview_cache WHERE url = ${url} AND fetched_at >= ${notOlderThan}
    `;
    const row = rows[0];
    return row === undefined ? { found: false } : { found: true, data: dataOf(row.data) };
  },

  async put(url, data, at) {
    return sql.begin(async (transaction) => {
      const tx = transaction as unknown as typeof sql;
      const previous = await tx<Array<{ data: unknown }>>`SELECT data FROM link_preview_cache WHERE url = ${url} FOR UPDATE`;
      await tx`
        INSERT INTO link_preview_cache (url, data, fetched_at) VALUES (${url}, ${data === null ? null : tx.json({ ...data })}, ${at})
        ON CONFLICT (url) DO UPDATE SET data = EXCLUDED.data, fetched_at = EXCLUDED.fetched_at
      `;
      return dataOf(previous[0]?.data)?.imageKey ?? null;
    });
  },

  async deleteExpired(olderThan) {
    const rows = await sql<Array<{ data: unknown }>>`DELETE FROM link_preview_cache WHERE fetched_at < ${olderThan} RETURNING data`;
    return rows.flatMap((row) => {
      const key = dataOf(row.data)?.imageKey;
      return key ? [key] : [];
    });
  },
};
