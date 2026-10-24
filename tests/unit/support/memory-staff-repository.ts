import type { SecretSealer, StaffRecord, StaffRepository, TotpState } from "../../../src/features/staff/application/staff-repository";
import type { StaffRole } from "../../../src/features/staff/domain/roles";

type Mutable<T> = { -readonly [K in keyof T]: T[K] };

interface Row extends Mutable<StaffRecord> {
  sealedSecret: Uint8Array | null;
  lastStep: number | null;
}

export class MemoryStaffRepository implements StaffRepository {
  readonly rows = new Map<string, Row>();
  touches: string[] = [];

  private view(row: Row): StaffRecord {
    const { sealedSecret: _s, lastStep: _l, ...record } = row;
    return record;
  }

  async find(email: string) {
    const row = this.rows.get(email);
    return row ? this.view(row) : null;
  }

  async list() {
    return [...this.rows.values()].map((row) => this.view(row));
  }

  async insert(input: { email: string; role: StaffRole; createdBy: string }) {
    if (this.rows.has(input.email)) return null;
    return this.view(this.add(input.email, input.role, input.createdBy));
  }

  private add(email: string, role: StaffRole, createdBy: string): Row {
    const row: Row = {
      email,
      role,
      active: true,
      mfaEnrolledAt: null,
      createdAt: "2026-10-24T09:00:00.000Z",
      createdBy,
      lastSeenAt: null,
      sealedSecret: null,
      lastStep: null,
    };
    this.rows.set(email, row);
    return row;
  }

  async update(email: string, patch: { role?: StaffRole; active?: boolean }) {
    const row = this.rows.get(email);
    if (!row) return null;
    if (patch.role !== undefined) row.role = patch.role;
    if (patch.active !== undefined) row.active = patch.active;
    return this.view(row);
  }

  async ensureRow(email: string, role: StaffRole, createdBy: string) {
    if (!this.rows.has(email)) this.add(email, role, createdBy);
  }

  async totpState(email: string): Promise<TotpState | null> {
    const row = this.rows.get(email);
    return row ? { sealedSecret: row.sealedSecret, enrolled: row.mfaEnrolledAt !== null } : null;
  }

  async storeUnconfirmedSecret(email: string, sealed: Uint8Array) {
    const row = this.rows.get(email);
    if (!row || row.mfaEnrolledAt !== null) return false;
    row.sealedSecret = sealed;
    row.lastStep = null;
    return true;
  }

  async confirmEnrollment(email: string) {
    const row = this.rows.get(email);
    if (row?.sealedSecret) row.mfaEnrolledAt = "2026-10-24T09:30:00.000Z";
  }

  async claimTotpStep(email: string, step: number) {
    const row = this.rows.get(email);
    if (!row || (row.lastStep !== null && row.lastStep >= step)) return false;
    row.lastStep = step;
    return true;
  }

  async touch(email: string) {
    this.touches.push(email);
  }
}

// Reversible stand-in for the secret box, tagged with its context so that a
// wrong context fails like the real AES-GCM would.
export const fakeSealer: SecretSealer = {
  seal: (plaintext, context) => Buffer.concat([Buffer.from(`${context}\n`), plaintext]),
  open: (sealed, context) => {
    const buffer = Buffer.from(sealed);
    const prefix = Buffer.from(`${context}\n`);
    if (!buffer.subarray(0, prefix.length).equals(prefix)) throw new Error("wrong context");
    return buffer.subarray(prefix.length);
  },
};
