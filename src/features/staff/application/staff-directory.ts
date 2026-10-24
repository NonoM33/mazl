import type { AuditLog } from "../../audit/application/ports";
import { normalizeStaffEmail } from "../domain/email";
import { roleGrants, type StaffRole } from "../domain/roles";
import type { StaffMember } from "./ports";
import type { StaffRecord, StaffRepository } from "./staff-repository";

export interface ResolvedStaff {
  readonly email: string;
  readonly role: StaffRole;
  readonly fromEnvironment: boolean;
  readonly mfaEnrolled: boolean;
}

export interface StaffListing extends Omit<StaffMember, "createdAt"> {
  // Null for an environment super-admin who never enrolled (no row yet).
  readonly createdAt: string | null;
  readonly fromEnvironment: boolean;
}

export type CreateStaffResult =
  | { readonly ok: true; readonly member: StaffListing }
  | { readonly ok: false; readonly reason: "environment_member" | "already_exists" };

export type UpdateStaffResult =
  | { readonly ok: true; readonly member: StaffListing }
  | { readonly ok: false; readonly reason: "environment_member" | "not_found" | "self_lockout" };

export interface StaffDirectoryDeps {
  readonly repository: StaffRepository;
  readonly audit: AuditLog;
  // Addresses of the environment (ADMIN_EMAILS): super-admins of right.
  readonly environmentAdmins: readonly string[];
}

const ENVIRONMENT_ROLE: StaffRole = "super_admin";

function listingOf(record: StaffRecord, fromEnvironment: boolean): StaffListing {
  return {
    email: record.email,
    role: fromEnvironment ? ENVIRONMENT_ROLE : record.role,
    active: fromEnvironment ? true : record.active,
    mfaEnrolled: record.mfaEnrolledAt !== null,
    createdAt: record.createdAt,
    createdBy: record.createdBy,
    lastSeenAt: record.lastSeenAt,
    fromEnvironment,
  };
}

export class StaffDirectory {
  private readonly environment: ReadonlySet<string>;

  constructor(private readonly deps: StaffDirectoryDeps) {
    this.environment = new Set(deps.environmentAdmins.map(normalizeStaffEmail));
  }

  isEnvironmentMember(email: string): boolean {
    return this.environment.has(normalizeStaffEmail(email));
  }

  // Who is this address right now? Null for unknown or deactivated members.
  async resolve(rawEmail: string): Promise<ResolvedStaff | null> {
    const email = normalizeStaffEmail(rawEmail);
    const record = await this.deps.repository.find(email);
    if (this.environment.has(email)) {
      return { email, role: ENVIRONMENT_ROLE, fromEnvironment: true, mfaEnrolled: record?.mfaEnrolledAt != null };
    }
    if (!record || !record.active) return null;
    return { email, role: record.role, fromEnvironment: false, mfaEnrolled: record.mfaEnrolledAt !== null };
  }

  async list(): Promise<readonly StaffListing[]> {
    const records = await this.deps.repository.list();
    const byEmail = new Map(records.map((record) => [record.email, record]));
    const environmentRows = [...this.environment].map((email): StaffListing => {
      const record = byEmail.get(email);
      return record
        ? listingOf(record, true)
        : { email, role: ENVIRONMENT_ROLE, active: true, mfaEnrolled: false, createdAt: null, createdBy: null, lastSeenAt: null, fromEnvironment: true };
    });
    const others = records.filter((record) => !this.environment.has(record.email)).map((record) => listingOf(record, false));
    return [...environmentRows, ...others];
  }

  async create(actor: string, input: { email: string; role: StaffRole }): Promise<CreateStaffResult> {
    const email = normalizeStaffEmail(input.email);
    if (this.environment.has(email)) return { ok: false, reason: "environment_member" };
    const record = await this.deps.repository.insert({ email, role: input.role, createdBy: actor });
    if (!record) return { ok: false, reason: "already_exists" };
    await this.deps.audit.record({
      actor,
      action: "staff.create",
      targetType: "staff",
      targetId: email,
      details: { role: input.role },
    });
    return { ok: true, member: listingOf(record, false) };
  }

  async update(actor: string, rawEmail: string, patch: { role?: StaffRole; active?: boolean }): Promise<UpdateStaffResult> {
    const email = normalizeStaffEmail(rawEmail);
    if (this.environment.has(email)) return { ok: false, reason: "environment_member" };
    if (email === normalizeStaffEmail(actor) && removesStaffManagement(patch)) return { ok: false, reason: "self_lockout" };
    const record = await this.deps.repository.update(email, patch);
    if (!record) return { ok: false, reason: "not_found" };
    await this.deps.audit.record({
      actor,
      action: "staff.update",
      targetType: "staff",
      targetId: email,
      details: { ...(patch.role === undefined ? {} : { role: patch.role }), ...(patch.active === undefined ? {} : { active: patch.active }) },
    });
    return { ok: true, member: listingOf(record, false) };
  }
}

function removesStaffManagement(patch: { role?: StaffRole; active?: boolean }): boolean {
  return patch.active === false || (patch.role !== undefined && !roleGrants(patch.role, "staff.manage"));
}
