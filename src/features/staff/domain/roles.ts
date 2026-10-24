// Staff roles and permissions of the back-office (docs/backoffice/CADRAGE.md §4).
// Least privilege: every route asks for ONE permission, never for a role, and
// a role is only the list of permissions it grants. Nothing outside this file
// decides who may do what.

export const STAFF_ROLES = ["super_admin", "admin", "moderator", "verifier", "support", "analyst"] as const;
export type StaffRole = (typeof STAFF_ROLES)[number];

export const PERMISSIONS = [
  // Dashboard and aggregated figures (no personal data).
  "dashboard.read",
  // Member file: profile, status, history of reports and sanctions.
  "members.read",
  // Private conversation of a report: sensitive, justified and audited on every read.
  "conversations.read",
  // Reports queue: read, assign, decide.
  "reports.read",
  "reports.decide",
  // Sanctions on accounts. A ban is a sanction with its own permission.
  "sanctions.apply",
  "sanctions.ban",
  // Appeals against a decision (DSA art. 20): decided by someone else than the author.
  "appeals.decide",
  // Identity and selfie verification queue.
  "verification.review",
  // Requests from authorities (judicial requisitions, PHAROS, DSA art. 18).
  "authorities.manage",
  // Matching engine parameters: read, simulate, publish a version.
  "matching.read",
  "matching.tune",
  // Audit log.
  "audit.read",
  // Staff accounts and their roles.
  "staff.manage",
  // Events, campaigns, subscriptions: the historical console screens.
  "operations.manage",
] as const;
export type Permission = (typeof PERMISSIONS)[number];

const MODERATION: readonly Permission[] = [
  "dashboard.read",
  "members.read",
  "conversations.read",
  "reports.read",
  "reports.decide",
  "sanctions.apply",
];

export const ROLE_PERMISSIONS: Readonly<Record<StaffRole, readonly Permission[]>> = {
  super_admin: PERMISSIONS,
  admin: PERMISSIONS.filter((permission) => permission !== "staff.manage"),
  moderator: MODERATION,
  verifier: ["dashboard.read", "members.read", "verification.review"],
  support: ["dashboard.read", "members.read", "reports.read"],
  analyst: ["dashboard.read", "matching.read", "audit.read"],
};

export const ROLE_LABELS: Readonly<Record<StaffRole, string>> = {
  super_admin: "Super-administrateur",
  admin: "Administrateur",
  moderator: "Modérateur",
  verifier: "Vérificateur",
  support: "Support",
  analyst: "Analyste",
};

export function isStaffRole(value: unknown): value is StaffRole {
  return typeof value === "string" && (STAFF_ROLES as readonly string[]).includes(value);
}

export function roleGrants(role: StaffRole, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role].includes(permission);
}
