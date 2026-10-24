import type { Permission, StaffRole } from "../domain/roles";

// HTTP contract of the staff feature (/api/backoffice/auth/*, /me, /staff).
// Every back-office answer is `{ success: true, data }` or
// `{ success: false, error: <code>, message?: <French text> }`.

export type ApiSuccess<T> = { readonly success: true; readonly data: T };
export type ApiFailure = { readonly success: false; readonly error: string; readonly message?: string };
export type ApiResponse<T> = ApiSuccess<T> | ApiFailure;

// POST /api/backoffice/auth/password   { email, password }
// POST /api/backoffice/auth/google     { credential }        (Google ID token)
// POST /api/backoffice/auth/mfa        { challenge, code }   (6-digit TOTP)
export type LoginResultDto =
  | { readonly kind: "session"; readonly token: string; readonly me: MeDto }
  | { readonly kind: "mfa_challenge"; readonly challenge: string };

// GET /api/backoffice/me
export interface MeDto {
  readonly email: string;
  readonly role: StaffRole;
  readonly roleLabel: string;
  readonly permissions: readonly Permission[];
  readonly mfa: boolean;
  readonly mfaEnrolled: boolean;
  // True when the server requires a second factor (production): until enrolled,
  // only /me and /mfa/* answer.
  readonly mfaRequired: boolean;
}

// POST /api/backoffice/mfa/enroll → secret to type in an authenticator app.
export interface MfaEnrollmentDto {
  readonly secret: string;
  readonly otpauthUri: string;
}

// POST /api/backoffice/mfa/confirm { code } → a new session with mfa = true.
export interface MfaConfirmedDto {
  readonly token: string;
  readonly me: MeDto;
}

// GET /api/backoffice/staff        (staff.manage)
// POST /api/backoffice/staff       { email, role }
// PATCH /api/backoffice/staff/:email { role?, active? }
export interface StaffMemberDto {
  readonly email: string;
  readonly role: StaffRole;
  readonly roleLabel: string;
  readonly active: boolean;
  readonly mfaEnrolled: boolean;
  // Addresses of the ADMIN_EMAIL environment: super-admins that the console cannot edit.
  readonly fromEnvironment: boolean;
  readonly createdAt: string | null;
  readonly createdBy: string | null;
  readonly lastSeenAt: string | null;
}
