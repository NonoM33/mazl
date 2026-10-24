import type { Sql } from "postgres";
import { STAFF_ROLES } from "../domain/roles";

// Staff accounts of the back-office. Idempotent: run at every boot.
export async function ensureStaffSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS staff_members (
      email TEXT PRIMARY KEY CHECK (email = lower(btrim(email))),
      role TEXT NOT NULL,
      active BOOLEAN NOT NULL DEFAULT true,
      totp_secret BYTEA,
      mfa_enrolled_at TIMESTAMPTZ,
      last_totp_step BIGINT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      created_by TEXT,
      last_seen_at TIMESTAMPTZ
    )
  `;
  // Rebuilt at each boot so that a role added to STAFF_ROLES is accepted.
  const roles = STAFF_ROLES.map((role) => `'${role}'`).join(", ");
  await sql`ALTER TABLE staff_members DROP CONSTRAINT IF EXISTS staff_members_role_check`;
  await sql.unsafe(`ALTER TABLE staff_members ADD CONSTRAINT staff_members_role_check CHECK (role IN (${roles}))`);
}
