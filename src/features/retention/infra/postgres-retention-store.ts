import type { Sql } from "postgres";
import type { RetentionStore } from "../application/ports";

export function createPostgresRetentionStore(sql: Sql): RetentionStore {
  return {
    async purge(rule) {
      // Table and column come from the closed unions of RetentionRule, never from input;
      // the age is a bound parameter cast to an interval.
      const age = `${rule.amount} ${rule.unit}`;
      const stillLive = rule.keepWhileUnexpired ? sql`AND expires_at <= now()` : sql``;
      const deleted = await sql`
        DELETE FROM ${sql(rule.table)}
        WHERE ${sql(rule.column)} < now() - ${age}::interval ${stillLive}
        RETURNING 1
      `;
      return deleted.length;
    },
  };
}
