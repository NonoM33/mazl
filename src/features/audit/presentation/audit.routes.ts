import type { Env, Hono } from "hono";
import { Hono as HonoApp } from "hono";
import type { RequirePermission, StaffVariables } from "../../staff/application/ports";
import type { AuditEntry, AuditFilter, AuditLog } from "../application/ports";
import { auditQuerySchema } from "./audit.query";
import type { AuditEntryDto, AuditPageDto, AuditVerificationDto } from "./dto";

export interface AuditRouteDeps {
  readonly audit: AuditLog;
  readonly requirePermission: RequirePermission;
}

function toDto(entry: AuditEntry): AuditEntryDto {
  return {
    id: entry.id,
    createdAt: entry.createdAt,
    actor: entry.actor,
    action: entry.action,
    targetType: entry.targetType,
    targetId: entry.targetId,
    justification: entry.justification ?? null,
    details: entry.details ?? null,
    hash: entry.hash,
  };
}

// GET /api/backoffice/audit and /audit/verify, both behind "audit.read".
export function registerAuditRoutes<E extends Env>(app: Hono<E>, deps: AuditRouteDeps): void {
  const router = new HonoApp<{ Variables: StaffVariables }>();
  const guard = deps.requirePermission("audit.read");

  router.get("/api/backoffice/audit", guard, async (c) => {
    const parsed = auditQuerySchema.safeParse(c.req.query());
    if (!parsed.success) {
      return c.json({ success: false, error: "invalid_request", message: "Filtres du journal invalides." }, 400);
    }
    const filter: AuditFilter = parsed.data;
    const page = await deps.audit.list(filter);
    const data: AuditPageDto = { entries: page.entries.map(toDto), total: page.total };
    return c.json({ success: true, data });
  });

  router.get("/api/backoffice/audit/verify", guard, async (c) => {
    const data: AuditVerificationDto = await deps.audit.verify();
    return c.json({ success: true, data });
  });

  app.route("/", router);
}
