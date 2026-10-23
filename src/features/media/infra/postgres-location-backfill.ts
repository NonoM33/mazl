import type { Sql } from "postgres";
import type { LocationBackfillRepository } from "../application/ports";

export function createPostgresLocationBackfill(sql: Sql): LocationBackfillRepository {
  return {
    async listUnfuzzed(limit) {
      const rows = await sql<{ user_id: number; latitude: string; longitude: string }[]>`
        SELECT user_id, latitude, longitude FROM profiles
        WHERE location_fuzzed = false AND latitude IS NOT NULL AND longitude IS NOT NULL
        ORDER BY user_id
        LIMIT ${limit}
      `;
      return rows.map((r) => ({ userId: r.user_id, latitude: Number(r.latitude), longitude: Number(r.longitude) }));
    },

    // The flag in the WHERE clause makes a concurrent second boot harmless.
    async markFuzzed(userId, fuzzed) {
      const rows = await sql`
        UPDATE profiles
        SET latitude = ${fuzzed.latitude}, longitude = ${fuzzed.longitude}, location_fuzzed = true
        WHERE user_id = ${userId} AND location_fuzzed = false
        RETURNING user_id
      `;
      return rows.length > 0;
    },
  };
}
