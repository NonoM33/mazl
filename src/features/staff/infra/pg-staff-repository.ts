import type { Sql } from "postgres";
import type { StaffRole } from "../domain/roles";
import type { SecretSealer, StaffRecord, StaffRepository, TotpState } from "../application/staff-repository";
import { open, seal } from "../../../shared/crypto/secret-box";

interface StaffRow {
  readonly email: string;
  readonly role: StaffRole;
  readonly active: boolean;
  readonly mfa_enrolled_at: Date | null;
  readonly created_at: Date;
  readonly created_by: string | null;
  readonly last_seen_at: Date | null;
}

const COLUMNS = "email, role, active, mfa_enrolled_at, created_at, created_by, last_seen_at";

function toRecord(row: StaffRow): StaffRecord {
  return {
    email: row.email,
    role: row.role,
    active: row.active,
    mfaEnrolledAt: row.mfa_enrolled_at?.toISOString() ?? null,
    createdAt: row.created_at.toISOString(),
    createdBy: row.created_by,
    lastSeenAt: row.last_seen_at?.toISOString() ?? null,
  };
}

export const secretBoxSealer: SecretSealer = { seal, open };

export class PgStaffRepository implements StaffRepository {
  constructor(private readonly sql: Sql) {}

  async find(email: string): Promise<StaffRecord | null> {
    const rows = await this.sql<StaffRow[]>`SELECT ${this.sql.unsafe(COLUMNS)} FROM staff_members WHERE email = ${email}`;
    const row = rows[0];
    return row ? toRecord(row) : null;
  }

  async list(): Promise<readonly StaffRecord[]> {
    const rows = await this.sql<StaffRow[]>`SELECT ${this.sql.unsafe(COLUMNS)} FROM staff_members ORDER BY created_at, email`;
    return rows.map(toRecord);
  }

  async insert(input: { email: string; role: StaffRole; createdBy: string }): Promise<StaffRecord | null> {
    const rows = await this.sql<StaffRow[]>`
      INSERT INTO staff_members (email, role, created_by) VALUES (${input.email}, ${input.role}, ${input.createdBy})
      ON CONFLICT (email) DO NOTHING
      RETURNING ${this.sql.unsafe(COLUMNS)}
    `;
    const row = rows[0];
    return row ? toRecord(row) : null;
  }

  async update(email: string, patch: { role?: StaffRole; active?: boolean }): Promise<StaffRecord | null> {
    const rows = await this.sql<StaffRow[]>`
      UPDATE staff_members
      SET role = COALESCE(${patch.role ?? null}::text, role), active = COALESCE(${patch.active ?? null}::boolean, active)
      WHERE email = ${email}
      RETURNING ${this.sql.unsafe(COLUMNS)}
    `;
    const row = rows[0];
    return row ? toRecord(row) : null;
  }

  async ensureRow(email: string, role: StaffRole, createdBy: string): Promise<void> {
    await this.sql`INSERT INTO staff_members (email, role, created_by) VALUES (${email}, ${role}, ${createdBy}) ON CONFLICT (email) DO NOTHING`;
  }

  async totpState(email: string): Promise<TotpState | null> {
    const rows = await this.sql<{ totp_secret: Uint8Array | null; mfa_enrolled_at: Date | null }[]>`
      SELECT totp_secret, mfa_enrolled_at FROM staff_members WHERE email = ${email}
    `;
    const row = rows[0];
    return row ? { sealedSecret: row.totp_secret, enrolled: row.mfa_enrolled_at !== null } : null;
  }

  async storeUnconfirmedSecret(email: string, sealed: Uint8Array): Promise<boolean> {
    const rows = await this.sql<{ email: string }[]>`
      UPDATE staff_members SET totp_secret = ${Buffer.from(sealed)}, last_totp_step = NULL
      WHERE email = ${email} AND mfa_enrolled_at IS NULL
      RETURNING email
    `;
    return rows.length === 1;
  }

  async confirmEnrollment(email: string): Promise<void> {
    await this.sql`UPDATE staff_members SET mfa_enrolled_at = now() WHERE email = ${email} AND totp_secret IS NOT NULL`;
  }

  async claimTotpStep(email: string, step: number): Promise<boolean> {
    const rows = await this.sql<{ email: string }[]>`
      UPDATE staff_members SET last_totp_step = ${step}
      WHERE email = ${email} AND (last_totp_step IS NULL OR last_totp_step < ${step})
      RETURNING email
    `;
    return rows.length === 1;
  }

  async touch(email: string): Promise<void> {
    await this.sql`UPDATE staff_members SET last_seen_at = now() WHERE email = ${email}`;
  }
}
