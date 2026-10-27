import type { Sql } from "postgres";

// city_activity: how many sessions opened Discover in a city, per weekday and
// hour (UTC) - a counter, no member in it. boost_schedules: the Boost a member
// programmed, kept until it has run (one at a time per member).
export async function ensureBoostTimingSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS city_activity (
      city_key VARCHAR(80) NOT NULL,
      dow SMALLINT NOT NULL CHECK (dow BETWEEN 0 AND 6),
      hour SMALLINT NOT NULL CHECK (hour BETWEEN 0 AND 23),
      sessions INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (city_key, dow, hour)
    )
  `;
  await sql`
    CREATE TABLE IF NOT EXISTS boost_schedules (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      run_at TIMESTAMPTZ NOT NULL,
      claimed_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_boost_schedules_due ON boost_schedules (run_at) WHERE claimed_at IS NULL`;
}
