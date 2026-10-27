import type { Env, Hono } from "hono";
import type { Sql } from "postgres";
import { createAttemptGuard } from "../../shared/http/rate-limit";
import type { AuditLog } from "../audit/application/ports";
import { ADMIN_EMAILS, secretsMatch } from "../admin/admin.auth";
import type { GoogleVerifier } from "../auth/google-token";
import type { RequirePermission, StaffVariables } from "./application/ports";
import { isMfaRequired } from "./application/mfa-policy";
import { StaffAuth } from "./application/staff-auth";
import { StaffDirectory } from "./application/staff-directory";
import { StaffMfa } from "./application/staff-mfa";
import { createTokenSigner, resolveStaffKey } from "./domain/session-token";
import { PgStaffRepository, secretBoxSealer } from "./infra/pg-staff-repository";
import { ensureStaffSchema } from "./infra/schema";
import { createAuthenticate, createRequirePermission } from "./presentation/require-permission";
import { registerStaffRoutes } from "./presentation/staff.routes";
import type { MiddlewareHandler } from "hono";

export interface StaffModuleOptions {
  readonly sql: Sql;
  // process.env, or a stand-in: ADMIN_EMAIL, ADMIN_PASSWORD, NODE_ENV,
  // STAFF_MFA_REQUIRED, STAFF_JWT_SECRET, JWT_SECRET.
  readonly env: Readonly<Record<string, string | undefined>>;
  readonly google: GoogleVerifier;
  readonly audit: AuditLog;
}

export interface StaffModule {
  readonly directory: StaffDirectory;
  readonly requirePermission: RequirePermission;
  // Authenticated staff member, no permission, no second-factor requirement.
  readonly authenticate: MiddlewareHandler<{ Variables: StaffVariables }>;
  readonly mfaRequired: boolean;
  ensureSchema(): Promise<void>;
  registerRoutes<E extends Env>(app: Hono<E>): void;
}

const FIFTEEN_MINUTES = 15 * 60_000;

// Staff accounts, roles, second factor, sessions and the permission guard of
// the back-office. Throws at creation when no signing key is configured.
export function createStaffModule(options: StaffModuleOptions): StaffModule {
  const { sql, env, google, audit } = options;
  const tokens = createTokenSigner(resolveStaffKey(env));
  const repository = new PgStaffRepository(sql);
  const directory = new StaffDirectory({ repository, audit, environmentAdmins: ADMIN_EMAILS });
  const mfa = new StaffMfa({
    repository,
    directory,
    sealer: secretBoxSealer,
    audit,
    guard: createAttemptGuard({ maxFailures: 5, windowMs: FIFTEEN_MINUTES }),
    now: () => new Date(),
  });
  const auth = new StaffAuth({
    directory,
    mfa,
    tokens,
    google,
    audit,
    adminEmail: env.ADMIN_EMAIL,
    adminPassword: env.ADMIN_PASSWORD,
    secretsMatch,
    passwordGuard: createAttemptGuard({ maxFailures: 5, windowMs: FIFTEEN_MINUTES }),
  });

  const mfaRequired = isMfaRequired(env);
  const guardDeps = {
    resolveStaff: (email: string) => directory.resolve(email),
    verifySession: tokens.verifySession,
    mfaRequired,
    touch: (email: string) => repository.touch(email),
    isProduction: env.NODE_ENV === "production",
    ...(env.ADMIN_EMAIL && env.ADMIN_PASSWORD
      ? { scriptAccess: { email: env.ADMIN_EMAIL, password: env.ADMIN_PASSWORD, secretsMatch } }
      : {}),
  };
  const requirePermission = createRequirePermission(guardDeps);
  const authenticate = createAuthenticate(guardDeps);

  return {
    directory,
    requirePermission,
    authenticate,
    mfaRequired,
    ensureSchema: () => ensureStaffSchema(sql),
    registerRoutes: (app) => registerStaffRoutes(app, { auth, mfa, directory, requirePermission, authenticate, mfaRequired }),
  };
}
