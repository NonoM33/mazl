import type { Sql } from "postgres";
import { sql } from "../../../db";
import type { LocationUpdateLog } from "../application/ports";

export const postgresLocationLog: LocationUpdateLog = {
  // The advisory lock serialises concurrent saves of the same user so that the
  // count and the insert cannot interleave.
  async tryRecord(userId, max, windowMs) {
    return sql.begin(async (transaction) => {
      // postgres.js loses the call signature on transaction handles in its typings.
      const tx = transaction as unknown as Sql;
      await tx`SELECT pg_advisory_xact_lock(${userId})`;
      const seconds = windowMs / 1000;
      const counted = await tx<{ n: string }[]>`
        SELECT COUNT(*) AS n FROM location_updates
        WHERE user_id = ${userId} AND created_at > NOW() - make_interval(secs => ${seconds})
      `;
      if (Number(counted[0]?.n ?? 0) >= max) return false;
      await tx`INSERT INTO location_updates (user_id) VALUES (${userId})`;
      await tx`DELETE FROM location_updates WHERE user_id = ${userId} AND created_at < NOW() - INTERVAL '7 days'`;
      return true;
    });
  },

  async currentPosition(userId) {
    const rows = await sql<{ latitude: string | null; longitude: string | null }[]>`
      SELECT latitude, longitude FROM profiles WHERE user_id = ${userId}
    `;
    const row = rows[0];
    if (!row || row.latitude === null || row.longitude === null) return null;
    return { latitude: Number(row.latitude), longitude: Number(row.longitude) };
  },
};
