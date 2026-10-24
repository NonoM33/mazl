import type { Env, Hono } from "hono";
import type { Sql } from "postgres";
import type { RequirePermission } from "../staff/application/ports";
import type { AuditLog } from "./application/ports";
import { PgAuditLog } from "./infra/pg-audit-log";
import { ensureAuditSchema } from "./infra/schema";
import { registerAuditRoutes } from "./presentation/audit.routes";

export interface AuditModuleOptions {
  readonly sql: Sql;
}

export interface AuditModule {
  readonly audit: AuditLog;
  ensureSchema(): Promise<void>;
  // Needs the staff guard, so it is registered once the staff module exists.
  registerRoutes<E extends Env>(app: Hono<E>, requirePermission: RequirePermission): void;
}

export function createAuditModule(options: AuditModuleOptions): AuditModule {
  const audit = new PgAuditLog(options.sql);
  return {
    audit,
    ensureSchema: () => ensureAuditSchema(options.sql),
    registerRoutes: (app, requirePermission) => registerAuditRoutes(app, { audit, requirePermission }),
  };
}
