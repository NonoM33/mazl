import { Hono } from "hono";
import type { Env } from "hono";
import { createIpRateLimiter } from "../../../shared/http/rate-limit";
import { currentStaff, type StaffVariables } from "../../staff/application/ports";
import type { AppealsService } from "../application/appeals-service";
import { appealDecisionBodySchema, appealsQuerySchema, publicAppealBodySchema } from "./schemas";
import { ok, parseId, parseJson, parseQuery } from "./http";
import type { RouteDeps } from "./route-deps";

export function appealsRoutes(deps: RouteDeps): Hono<{ Variables: StaffVariables }> {
  const router = new Hono<{ Variables: StaffVariables }>();
  const { requirePermission, audit, services } = deps;

  router.get("/appeals", requirePermission("appeals.decide"), async (c) => {
    const query = parseQuery(c, appealsQuerySchema);
    return ok(c, await services.appeals.list(query.status, query.limit, query.offset));
  });

  router.post("/appeals/:id/decision", requirePermission("appeals.decide"), async (c) => {
    const id = parseId(c.req.param("id"));
    const body = await parseJson(c, appealDecisionBodySchema);
    const staff = currentStaff(c);
    const appeal = await services.appeals.decide(id, body.outcome, body.note, staff.email);
    await audit.record({
      actor: staff.email,
      action: "appeal.decide",
      targetType: "appeal",
      targetId: String(id),
      details: { outcome: body.outcome, sanctionId: appeal.sanctionId },
    });
    return ok(c, appeal);
  });

  return router;
}

// POST /api/appeals: public, because a banned member cannot sign in. Limited
// per address, and the answer is the same whatever the reference and code.
export function registerPublicAppealRoute<E extends Env>(app: Hono<E>, appeals: AppealsService): void {
  const limiter = createIpRateLimiter({ max: 5, windowMs: 60 * 60_000 });
  app.post("/api/appeals", limiter, async (c) => {
    const parsed = publicAppealBodySchema.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) return c.json({ success: false, error: "invalid_request" }, 400);
    const result = await appeals.submit(parsed.data);
    if (result === "expired") return c.json({ success: false, error: "appeal_window_closed" }, 409);
    if (result === "duplicate") return c.json({ success: false, error: "appeal_already_filed" }, 409);
    return c.json({ success: true }, 202);
  });
}
