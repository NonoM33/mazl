import { Hono } from "hono";
import { currentStaff, type StaffVariables } from "../../staff/application/ports";
import { createSanctionBodySchema, membersQuerySchema, revokeBodySchema } from "./schemas";
import { ok, parseId, parseJson, parseQuery, requireGrant } from "./http";
import type { RouteDeps } from "./route-deps";

// Member file, search and the sanctions a moderator decides on their own.
export function membersRoutes(deps: RouteDeps): Hono<{ Variables: StaffVariables }> {
  const router = new Hono<{ Variables: StaffVariables }>();
  const { requirePermission, audit, services } = deps;

  router.get("/members", requirePermission("members.read"), async (c) => {
    const query = parseQuery(c, membersQuerySchema);
    return ok(c, await services.members.search(query.q, query.limit, query.offset));
  });

  router.get("/members/:id", requirePermission("members.read"), async (c) => {
    const id = parseId(c.req.param("id"));
    const file = await services.members.file(id);
    await audit.record({ actor: currentStaff(c).email, action: "member.read", targetType: "member", targetId: String(id) });
    return ok(c, file);
  });

  router.post("/members/:id/sanctions", requirePermission("sanctions.apply"), async (c) => {
    const id = parseId(c.req.param("id"));
    const { note, ...input } = await parseJson(c, createSanctionBodySchema);
    if (input.kind === "ban") requireGrant(c, "sanctions.ban");
    const staff = currentStaff(c);
    const issued = await services.sanctions.issue(id, input, note, staff.email);
    await audit.record({
      actor: staff.email,
      action: "sanction.issue",
      targetType: "sanction",
      targetId: String(issued.sanction.id),
      details: { memberId: id, kind: issued.sanction.kind, ground: issued.sanction.ground, reportId: null },
    });
    return ok(c, issued, 201);
  });

  router.post("/sanctions/:id/revoke", requirePermission("sanctions.apply"), async (c) => {
    const id = parseId(c.req.param("id"));
    const { note } = await parseJson(c, revokeBodySchema);
    const staff = currentStaff(c);
    const sanction = await services.sanctions.revoke(id, note, staff.email);
    await audit.record({
      actor: staff.email,
      action: "sanction.revoke",
      targetType: "sanction",
      targetId: String(id),
      details: { memberId: sanction.memberId, kind: sanction.kind },
    });
    return ok(c, sanction);
  });

  return router;
}
