import type { Context, MiddlewareHandler } from "hono";
import type { Permission, StaffRole } from "../domain/roles";

// The authenticated staff member of a back-office request. Built by the staff
// guard on every request from the token AND the staff table: removing a member
// or changing their role takes effect on the next request.
export interface StaffPrincipal {
  readonly email: string;
  readonly role: StaffRole;
  // True when the token was issued after a second factor (TOTP) was checked.
  readonly mfa: boolean;
}

export type StaffVariables = {
  staff: StaffPrincipal;
};

// Builds a Hono middleware that lets the request through only when a staff
// member holding `permission` is authenticated (401 otherwise, 403 when the
// role lacks the permission, 403 `mfa_required` when the second factor is
// required and missing). It sets `c.get("staff")`.
export type RequirePermission = (permission: Permission) => MiddlewareHandler<{ Variables: StaffVariables }>;

export function currentStaff(c: Context<{ Variables: StaffVariables }>): StaffPrincipal {
  return c.get("staff");
}

export interface StaffMember {
  readonly email: string;
  readonly role: StaffRole;
  readonly active: boolean;
  readonly mfaEnrolled: boolean;
  readonly createdAt: string;
  readonly createdBy: string | null;
  readonly lastSeenAt: string | null;
}
