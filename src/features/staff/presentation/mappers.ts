import type { ResolvedStaff, StaffListing } from "../application/staff-directory";
import { ROLE_LABELS, ROLE_PERMISSIONS } from "../domain/roles";
import type { MeDto, StaffMemberDto } from "./dto";

export function toMeDto(staff: ResolvedStaff, mfa: boolean, mfaRequired: boolean): MeDto {
  return {
    email: staff.email,
    role: staff.role,
    roleLabel: ROLE_LABELS[staff.role],
    permissions: ROLE_PERMISSIONS[staff.role],
    mfa,
    mfaEnrolled: staff.mfaEnrolled,
    mfaRequired,
  };
}

export function toStaffMemberDto(member: StaffListing): StaffMemberDto {
  return {
    email: member.email,
    role: member.role,
    roleLabel: ROLE_LABELS[member.role],
    active: member.active,
    mfaEnrolled: member.mfaEnrolled,
    fromEnvironment: member.fromEnvironment,
    createdAt: member.createdAt,
    createdBy: member.createdBy,
    lastSeenAt: member.lastSeenAt,
  };
}
