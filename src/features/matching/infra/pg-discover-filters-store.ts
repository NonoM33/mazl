import type { Sql } from "postgres";
import type { DiscoverFiltersStore } from "../application/ports";
import { NO_FILTERS, type DiscoverFilters } from "../domain/discover-filters";
import { TEXT_OID } from "./pg-types";

interface FiltersRow {
  readonly denominations: string[] | null;
  readonly kashrut_levels: string[] | null;
  readonly shabbat_observances: string[] | null;
  readonly only_verified: boolean;
  readonly only_with_photo: boolean;
}

function toFilters(row: FiltersRow): DiscoverFilters {
  return {
    denominations: row.denominations,
    kashrutLevels: row.kashrut_levels,
    shabbatObservances: row.shabbat_observances,
    onlyVerified: row.only_verified,
    onlyWithPhoto: row.only_with_photo,
  };
}

// One row per member in discover_filters (matching/infra/schema.ts), deleted
// with the account and cleared of religious criteria when the art. 9 consent
// is withdrawn (privacy/infra/pg-consent-repository.ts).
export class PgDiscoverFiltersStore implements DiscoverFiltersStore {
  constructor(private readonly sql: Sql) {}

  async get(userId: number): Promise<DiscoverFilters> {
    const rows = await this.sql<FiltersRow[]>`
      SELECT denominations, kashrut_levels, shabbat_observances, only_verified, only_with_photo
      FROM discover_filters WHERE user_id = ${userId}
    `;
    const row = rows[0];
    return row === undefined ? NO_FILTERS : toFilters(row);
  }

  async save(userId: number, filters: DiscoverFilters): Promise<void> {
    const { sql } = this;
    const list = (values: readonly string[] | null) => (values === null ? null : sql.array([...values], TEXT_OID));
    await sql`
      INSERT INTO discover_filters (user_id, denominations, kashrut_levels, shabbat_observances, only_verified, only_with_photo)
      VALUES (${userId}, ${list(filters.denominations)}, ${list(filters.kashrutLevels)}, ${list(filters.shabbatObservances)},
              ${filters.onlyVerified}, ${filters.onlyWithPhoto})
      ON CONFLICT (user_id) DO UPDATE SET
        denominations = EXCLUDED.denominations,
        kashrut_levels = EXCLUDED.kashrut_levels,
        shabbat_observances = EXCLUDED.shabbat_observances,
        only_verified = EXCLUDED.only_verified,
        only_with_photo = EXCLUDED.only_with_photo,
        updated_at = now()
    `;
  }
}
