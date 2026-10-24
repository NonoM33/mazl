import type { Sql } from "postgres";
import { APPEAL_STATUSES, AUTHORITY_KINDS, AUTHORITY_STATUSES, SANCTION_KINDS } from "../domain/types";

const list = (values: readonly string[]): string => values.map((value) => `'${value}'`).join(", ");

// Idempotent. Runs at every boot, after initDb() (users, reports) and after
// ensureChatSchema() (reports.message_id). Values in the CHECK lists come from
// constants of the domain, never from input.
export async function ensureTrustSafetySchema(sql: Sql): Promise<void> {
  await sql`ALTER TABLE reports ADD COLUMN IF NOT EXISTS assigned_to TEXT`;
  await sql`ALTER TABLE reports ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ`;
  await sql`ALTER TABLE reports ADD COLUMN IF NOT EXISTS decision_note TEXT`;

  await sql.unsafe(`
    CREATE TABLE IF NOT EXISTS member_sanctions (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      kind TEXT NOT NULL CHECK (kind IN (${list(SANCTION_KINDS)})),
      ground TEXT NOT NULL,
      starts_at TIMESTAMPTZ NOT NULL,
      ends_at TIMESTAMPTZ,
      decided_by TEXT NOT NULL,
      report_id INTEGER REFERENCES reports(id) ON DELETE SET NULL,
      statement JSONB NOT NULL,
      appeal_code_hash TEXT NOT NULL,
      note TEXT,
      revoked_at TIMESTAMPTZ,
      revoked_by TEXT,
      revoke_note TEXT,
      expiry_processed_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await sql`CREATE INDEX IF NOT EXISTS idx_member_sanctions_user ON member_sanctions (user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_member_sanctions_kind_end ON member_sanctions (kind, ends_at)`;
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_member_sanctions_reference ON member_sanctions ((statement->>'reference'))`;

  await sql.unsafe(`
    CREATE TABLE IF NOT EXISTS sanction_appeals (
      id SERIAL PRIMARY KEY,
      sanction_id INTEGER NOT NULL UNIQUE REFERENCES member_sanctions(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      message TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (${list(APPEAL_STATUSES)})),
      decided_by TEXT,
      decided_at TIMESTAMPTZ,
      decision_note TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await sql`CREATE INDEX IF NOT EXISTS idx_sanction_appeals_status ON sanction_appeals (status, created_at)`;

  await sql.unsafe(`
    CREATE TABLE IF NOT EXISTS authority_requests (
      id SERIAL PRIMARY KEY,
      kind TEXT NOT NULL CHECK (kind IN (${list(AUTHORITY_KINDS)})),
      authority TEXT NOT NULL,
      reference TEXT NOT NULL,
      received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      due_at TIMESTAMPTZ,
      member_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      scope TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'received' CHECK (status IN (${list(AUTHORITY_STATUSES)})),
      handled_by TEXT,
      notes TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await sql`CREATE INDEX IF NOT EXISTS idx_authority_requests_status ON authority_requests (status, due_at)`;
}

// The condition to use wherever the matching engine must skip a member under a
// restriction, a suspension or a ban. Alias the table as `s` and join on
// s.user_id; or use it in an EXISTS sub-query.
export const activeRestrictionSql =
  "revoked_at IS NULL AND starts_at <= now() AND (ends_at IS NULL OR ends_at > now()) AND kind IN ('restriction','suspension','ban')";
