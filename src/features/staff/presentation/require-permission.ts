import type { Context, MiddlewareHandler } from "hono";
import { createMiddleware } from "hono/factory";
import { normalizeStaffEmail } from "../domain/email";
import { roleGrants, type Permission, type StaffRole } from "../domain/roles";
import type { SessionClaims } from "../domain/session-token";
import type { RequirePermission, StaffPrincipal, StaffVariables } from "../application/ports";

const TOUCH_INTERVAL_MS = 60_000;

export interface GuardDeps {
  // Current, active staff member for an address, or null (unknown, deactivated).
  readonly resolveStaff: (email: string) => Promise<{ readonly email: string; readonly role: StaffRole } | null>;
  readonly verifySession: (token: string) => SessionClaims | null;
  // True when a second factor is required: a session without it only reaches
  // the routes that do not use `requirePermission`.
  readonly mfaRequired: boolean;
  readonly touch: (email: string) => Promise<void>;
  // Outside production only, the x-admin-password header stands for a
  // super-admin session (scripts, integration tests). Ignored in production.
  readonly isProduction: boolean;
  readonly scriptAccess?: {
    readonly email: string;
    readonly password: string;
    readonly secretsMatch: (given: string, expected: string) => boolean;
  };
  readonly now?: () => number;
}

type StaffContext = Context<{ Variables: StaffVariables }>;

const unauthorized = (c: StaffContext): Response =>
  c.json({ success: false, error: "unauthorized", message: "Connexion requise." }, 401);

// Resolves the principal of a request, or null. Bearer first, then the
// non-production script header.
async function principalOf(deps: GuardDeps, c: StaffContext): Promise<StaffPrincipal | null> {
  const authorization = c.req.header("Authorization") ?? "";
  if (authorization.startsWith("Bearer ")) {
    const claims = deps.verifySession(authorization.slice("Bearer ".length));
    if (claims) {
      const staff = await deps.resolveStaff(claims.email);
      if (staff) return { email: staff.email, role: staff.role, mfa: claims.mfa };
    }
  }
  const script = deps.scriptAccess;
  const given = c.req.header("x-admin-password");
  if (!deps.isProduction && script && given && script.secretsMatch(given, script.password)) {
    const staff = await deps.resolveStaff(script.email);
    if (staff) return { email: staff.email, role: staff.role, mfa: true };
  }
  return null;
}

// last_seen_at is written at most once a minute per member.
function createToucher(deps: GuardDeps): (email: string) => Promise<void> {
  const now = deps.now ?? Date.now;
  const lastTouch = new Map<string, number>();
  return async (email) => {
    const key = normalizeStaffEmail(email);
    const at = now();
    const previous = lastTouch.get(key);
    if (previous !== undefined && at - previous < TOUCH_INTERVAL_MS) return;
    lastTouch.set(key, at);
    try {
      await deps.touch(email);
    } catch (error) {
      console.error("Staff last_seen update failed:", error instanceof Error ? error.name : "unknown");
    }
  };
}

type Guard = MiddlewareHandler<{ Variables: StaffVariables }>;

// Authenticated staff member, no permission and no second-factor requirement:
// /me and the enrolment routes.
export function createAuthenticate(deps: GuardDeps): Guard {
  const touch = createToucher(deps);
  return createMiddleware<{ Variables: StaffVariables }>(async (c, next) => {
    const principal = await principalOf(deps, c);
    if (!principal) return unauthorized(c);
    await touch(principal.email);
    c.set("staff", principal);
    await next();
  });
}

export function createRequirePermission(deps: GuardDeps): RequirePermission {
  const authenticate = createAuthenticate(deps);
  return (permission: Permission): Guard => {
    const check = createMiddleware<{ Variables: StaffVariables }>(async (c, next) => {
      const principal = c.get("staff");
      if (deps.mfaRequired && !principal.mfa) {
        return c.json({ success: false, error: "mfa_required", message: "Second facteur requis." }, 403);
      }
      if (!roleGrants(principal.role, permission)) {
        return c.json({ success: false, error: "forbidden", message: "Droits insuffisants." }, 403);
      }
      await next();
    });
    return async (c, next) => {
      let passed = false;
      const outcome = await authenticate(c, async () => {
        passed = true;
      });
      if (!passed) return outcome;
      return check(c, next);
    };
  };
}
