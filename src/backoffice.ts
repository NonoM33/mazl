import { Hono, type Env } from "hono";
import type { Sql } from "postgres";
import { banUser, unbanUser } from "./db";
import { createAuditModule } from "./features/audit/audit.module";
import { createGoogleVerifier } from "./features/auth/google-token";
import { buildConsole } from "./features/console/console.bundle";
import { registerConsoleRoutes } from "./features/console/console.routes";
import { createMatchingModule } from "./features/matching/matching.module";
import type { StaffVariables } from "./features/staff/application/ports";
import { createStaffModule } from "./features/staff/staff.module";
import type { AccountEnforcement } from "./features/trust-safety/application/ports";
import { createTrustSafetyModule } from "./features/trust-safety/trust-safety.module";

// Composition root of the staff back-office (docs/backoffice/CADRAGE.md):
// audit journal, staff accounts and second factor, trust & safety, the
// matching engine and its tuning API, and the /console front. Every
// /api/backoffice route is guarded by a staff permission; the only public
// route is POST /api/appeals (DSA art. 20, a banned member cannot sign in).

const SYSTEM_ACTOR = "system:trust-safety";

export interface BackofficeDeps {
  readonly sql: Sql;
  readonly env: Readonly<Record<string, string | undefined>>;
  // Closes the member's open sockets once their account is disabled.
  readonly closeConnections: (userId: number) => void;
}

function accountEnforcement(sql: Sql, closeConnections: (userId: number) => void): AccountEnforcement {
  return {
    disable: async (userId) => {
      await sql`UPDATE users SET is_active = false WHERE id = ${userId}`;
    },
    ban: async (userId, reason, by) => {
      await banUser({ userId, reason, bannedBy: by, isPermanent: true });
    },
    // A lifted sanction or an expired suspension: the account comes back and
    // any ban row is closed (banUser wrote one for a ban).
    enable: async (userId) => {
      await unbanUser(userId, SYSTEM_ACTOR);
    },
    onDisabled: async (userId) => {
      closeConnections(userId);
    },
  };
}

export function createBackoffice(deps: BackofficeDeps) {
  const { sql, env } = deps;
  const development = env.NODE_ENV !== "production";
  const audit = createAuditModule({ sql });
  const google = createGoogleVerifier({ audiences: [env.GOOGLE_CLIENT_ID ?? ""] });
  const staff = createStaffModule({ sql, env, google, audit: audit.audit });
  const trustSafety = createTrustSafetyModule({
    sql,
    audit: audit.audit,
    requirePermission: staff.requirePermission,
    enforcement: accountEnforcement(sql, deps.closeConnections),
  });
  const matching = createMatchingModule({ sql, audit: audit.audit, requirePermission: staff.requirePermission });

  function register<E extends Env>(app: Hono<E>): void {
    const api = new Hono<{ Variables: StaffVariables }>();
    staff.registerRoutes(api);
    audit.registerRoutes(api, staff.requirePermission);
    trustSafety.register(api);
    matching.registerAdminRoutes(api);
    app.route("/", api);
    registerConsoleRoutes(app, { build: () => buildConsole({ development }), development });
  }

  // Order matters: trust-safety creates member_sanctions, read by the matching prefilter.
  async function ensureSchemas(): Promise<void> {
    await audit.ensureSchema();
    await staff.ensureSchema();
    await trustSafety.ensureSchema();
    await matching.ensureSchema();
  }

  return { register, ensureSchemas, feed: matching.feed, startSweeper: () => trustSafety.startSweeper() };
}
