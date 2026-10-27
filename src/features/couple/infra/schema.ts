import type { Sql } from "postgres";
import { seedDefaultRitualsForAllCouples } from "./pg-rituals";

// Tables of the daily couple space (docs/couple/ESPACE-COUPLE.md). Idempotent:
// run at every boot, from initDb, after the couples tables exist.
export async function ensureCoupleSpaceSchema(sql: Sql): Promise<void> {
  await sql`ALTER TABLE couples ADD COLUMN IF NOT EXISTS rituals_seeded_at TIMESTAMP`;

  // Which bank question a daily question is (null: written by an older release).
  await sql`ALTER TABLE couple_questions ADD COLUMN IF NOT EXISTS bank_key VARCHAR(10)`;

  // The fake outings of the TestFlight phase carry a stable key: the seed finds
  // them again, the purge removes exactly these rows.
  await sql`ALTER TABLE couple_activities ADD COLUMN IF NOT EXISTS fixture_key TEXT`;
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS uniq_couple_activities_fixture ON couple_activities (fixture_key) WHERE fixture_key IS NOT NULL`;
  await sql`ALTER TABLE couple_events ADD COLUMN IF NOT EXISTS fixture_key TEXT`;
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS uniq_couple_events_fixture ON couple_events (fixture_key) WHERE fixture_key IS NOT NULL`;

  await sql`
    CREATE TABLE IF NOT EXISTS couple_rituals (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
      kind VARCHAR(10) NOT NULL CHECK (kind IN ('shabbat', 'weekly', 'custom')),
      title VARCHAR(120) NOT NULL,
      weekday SMALLINT CHECK (weekday BETWEEN 0 AND 6),
      time VARCHAR(5) CHECK (time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
      enabled BOOLEAN NOT NULL DEFAULT true,
      remind_minutes INTEGER NOT NULL DEFAULT 60 CHECK (remind_minutes BETWEEN 0 AND 10080),
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_couple_rituals_couple ON couple_rituals (couple_id)`;

  // One row per reminder ever sent: the sweep never sends the same one twice.
  await sql`
    CREATE TABLE IF NOT EXISTS couple_reminders_sent (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
      source VARCHAR(10) NOT NULL CHECK (source IN ('date', 'ritual')),
      ref_id INTEGER NOT NULL,
      occurrence VARCHAR(40) NOT NULL,
      sent_at TIMESTAMP DEFAULT NOW(),
      UNIQUE (couple_id, source, ref_id, occurrence)
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS couple_moods (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      couple_id INTEGER NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
      day DATE NOT NULL,
      mood VARCHAR(10) NOT NULL CHECK (mood IN ('great', 'good', 'meh', 'talk')),
      created_at TIMESTAMP DEFAULT NOW(),
      PRIMARY KEY (user_id, day)
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS couple_checkins (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      period CHAR(7) NOT NULL,
      talk SMALLINT NOT NULL CHECK (talk BETWEEN 1 AND 5),
      time SMALLINT NOT NULL CHECK (time BETWEEN 1 AND 5),
      close SMALLINT NOT NULL CHECK (close BETWEEN 1 AND 5),
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE (couple_id, user_id, period)
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS concierge_requests (
      id SERIAL PRIMARY KEY,
      couple_id INTEGER NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
      created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
      title VARCHAR(120) NOT NULL,
      brief TEXT NOT NULL,
      kind VARCHAR(10) NOT NULL DEFAULT 'other',
      wanted_at DATE,
      city VARCHAR(100),
      constraints JSONB NOT NULL DEFAULT '{}',
      status VARCHAR(10) NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'proposed', 'chosen', 'booked', 'closed', 'cancelled')),
      options JSONB NOT NULL DEFAULT '[]',
      chosen_index INTEGER,
      staff_note TEXT,
      assigned_to TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_concierge_requests_couple ON concierge_requests (couple_id, updated_at DESC)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_concierge_requests_status ON concierge_requests (status, updated_at DESC)`;
  await sql`
    CREATE TABLE IF NOT EXISTS concierge_messages (
      id SERIAL PRIMARY KEY,
      request_id INTEGER NOT NULL REFERENCES concierge_requests(id) ON DELETE CASCADE,
      role VARCHAR(10) NOT NULL CHECK (role IN ('member', 'assistant', 'staff')),
      author_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      text TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_concierge_messages_request ON concierge_messages (request_id, id)`;

  // Couples that already exist get their default rituals once.
  await seedDefaultRitualsForAllCouples(sql);
}
