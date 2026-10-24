import type { StaffRole } from "../domain/roles";

export interface StaffRecord {
  readonly email: string;
  readonly role: StaffRole;
  readonly active: boolean;
  readonly mfaEnrolledAt: string | null;
  readonly createdAt: string;
  readonly createdBy: string | null;
  readonly lastSeenAt: string | null;
}

export interface TotpState {
  // The TOTP secret, sealed at rest; null until enrolment started.
  readonly sealedSecret: Uint8Array | null;
  readonly enrolled: boolean;
}

export interface StaffRepository {
  find(email: string): Promise<StaffRecord | null>;
  list(): Promise<readonly StaffRecord[]>;
  // null when the address already has a row.
  insert(input: { email: string; role: StaffRole; createdBy: string }): Promise<StaffRecord | null>;
  update(email: string, patch: { role?: StaffRole; active?: boolean }): Promise<StaffRecord | null>;
  // Creates the row of an environment super-admin (to hold their TOTP) if missing.
  ensureRow(email: string, role: StaffRole, createdBy: string): Promise<void>;
  totpState(email: string): Promise<TotpState | null>;
  // Stores a not yet confirmed secret. False when the member is already enrolled
  // (a stolen first-factor session must not replace a second factor).
  storeUnconfirmedSecret(email: string, sealed: Uint8Array): Promise<boolean>;
  confirmEnrollment(email: string): Promise<void>;
  // Anti-replay: records `step` as used and returns true only when it is
  // strictly after the last accepted step. Atomic.
  claimTotpStep(email: string, step: number): Promise<boolean>;
  touch(email: string): Promise<void>;
}

export interface SecretSealer {
  seal(plaintext: Uint8Array, context: string): Uint8Array;
  open(sealed: Uint8Array, context: string): Uint8Array;
}
