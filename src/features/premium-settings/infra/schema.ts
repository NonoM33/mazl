import type { Sql } from "postgres";

// One row per member who touched a mazl+ setting; gone with the account. The
// passport holds a city the member chose (a city centre, not a position of theirs).
export async function ensurePremiumSettingsSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS member_premium_settings (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      passport_city VARCHAR(80),
      passport_latitude DOUBLE PRECISION,
      passport_longitude DOUBLE PRECISION,
      incognito BOOLEAN NOT NULL DEFAULT false,
      send_read_receipts BOOLEAN NOT NULL DEFAULT true,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      CHECK ((passport_city IS NULL) = (passport_latitude IS NULL) AND (passport_city IS NULL) = (passport_longitude IS NULL))
    )
  `;
}
