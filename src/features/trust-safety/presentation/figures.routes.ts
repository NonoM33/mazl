import { Hono } from "hono";
import { currentStaff, type StaffVariables } from "../../staff/application/ports";
import type { AuthorityInput } from "../application/ports";
import { notFound } from "../application/errors";
import { transparencyCsv } from "./csv";
import { authoritiesQuerySchema, authorityBodySchema, authorityPatchSchema, transparencyQuerySchema } from "./schemas";
import { ok, parseId, parseJson, parseQuery } from "./http";
import type { RouteDeps } from "./route-deps";

// Authority requests, dashboard, transparency report and verification queue.
export function figuresRoutes(deps: RouteDeps): Hono<{ Variables: StaffVariables }> {
  const router = new Hono<{ Variables: StaffVariables }>();
  const { requirePermission, audit, services } = deps;

  router.get("/authorities", requirePermission("authorities.manage"), async (c) => {
    const query = parseQuery(c, authoritiesQuerySchema);
    return ok(c, await services.authorities.list(query.status, query.limit, query.offset));
  });

  router.post("/authorities", requirePermission("authorities.manage"), async (c) => {
    const body = await parseJson(c, authorityBodySchema);
    const staff = currentStaff(c);
    const input: AuthorityInput = {
      kind: body.kind,
      authority: body.authority,
      reference: body.reference,
      receivedAt: body.receivedAt ?? new Date().toISOString(),
      dueAt: body.dueAt ?? null,
      memberId: body.memberId ?? null,
      scope: body.scope,
      status: body.status,
      handledBy: staff.email,
      notes: body.notes ?? null,
    };
    const created = await services.authorities.create(input);
    await audit.record({ actor: staff.email, action: "authority.create", targetType: "authority_request", targetId: String(created.id), details: { kind: created.kind } });
    return ok(c, created, 201);
  });

  router.patch("/authorities/:id", requirePermission("authorities.manage"), async (c) => {
    const id = parseId(c.req.param("id"));
    const patch = await parseJson(c, authorityPatchSchema);
    const updated = await services.authorities.update(id, patch);
    if (!updated) throw notFound("Demande");
    await audit.record({
      actor: currentStaff(c).email,
      action: "authority.update",
      targetType: "authority_request",
      targetId: String(id),
      details: { fields: Object.keys(patch) },
    });
    return ok(c, updated);
  });

  router.get("/dashboard", requirePermission("dashboard.read"), async (c) => ok(c, await services.overview.dashboard()));

  router.get("/transparency", requirePermission("dashboard.read"), async (c) => {
    const query = parseQuery(c, transparencyQuerySchema);
    const report = await services.overview.transparency(query.from, query.to);
    if (query.format === "csv") {
      return c.body(transparencyCsv(report), 200, {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="transparence-${query.from}-${query.to}.csv"`,
      });
    }
    return ok(c, report);
  });

  router.get("/verification/queue", requirePermission("verification.review"), async (c) => {
    return ok(c, { items: await services.overview.verificationQueue() });
  });

  return router;
}
