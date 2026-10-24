import { Hono } from "hono";
import { currentStaff, type StaffVariables } from "../../staff/application/ports";
import { assignBodySchema, conversationQuerySchema, decisionBodySchema, reportsQuerySchema } from "./schemas";
import { ok, parseId, parseJson, parseQuery, requireGrant } from "./http";
import type { RouteDeps } from "./route-deps";

// Reports queue: read, assign, decide, and the audited read of a conversation.
export function reportsRoutes(deps: RouteDeps): Hono<{ Variables: StaffVariables }> {
  const router = new Hono<{ Variables: StaffVariables }>();
  const { requirePermission, audit, services } = deps;

  router.get("/reports", requirePermission("reports.read"), async (c) => {
    const query = parseQuery(c, reportsQuerySchema);
    return ok(c, await services.reports.list(query, currentStaff(c).email));
  });

  router.get("/reports/:id", requirePermission("reports.read"), async (c) => {
    return ok(c, await services.reports.detail(parseId(c.req.param("id"))));
  });

  router.post("/reports/:id/assign", requirePermission("reports.decide"), async (c) => {
    const id = parseId(c.req.param("id"));
    const body = await parseJson(c, assignBodySchema);
    const staff = currentStaff(c);
    const item = await services.reports.assign(id, body.to, staff.email);
    await audit.record({ actor: staff.email, action: "report.assign", targetType: "report", targetId: String(id), details: { to: item.assignedTo } });
    return ok(c, item);
  });

  router.post("/reports/:id/decision", requirePermission("reports.decide"), async (c) => {
    const id = parseId(c.req.param("id"));
    const body = await parseJson(c, decisionBodySchema);
    const staff = currentStaff(c);
    if (body.sanction) {
      requireGrant(c, "sanctions.apply");
      if (body.sanction.kind === "ban") requireGrant(c, "sanctions.ban");
    }
    const outcome = await services.reports.decide(id, body, staff.email);
    await audit.record({
      actor: staff.email,
      action: "report.decide",
      targetType: "report",
      targetId: String(id),
      details: { outcome: body.outcome, status: outcome.status, sanctionId: outcome.sanction ? outcome.sanction.id : null },
    });
    if (outcome.sanction) {
      await audit.record({
        actor: staff.email,
        action: "sanction.issue",
        targetType: "sanction",
        targetId: String(outcome.sanction.id),
        details: { memberId: outcome.sanction.memberId, kind: outcome.sanction.kind, ground: outcome.sanction.ground, reportId: id },
      });
    }
    return ok(c, outcome);
  });

  router.get("/reports/:id/conversation", requirePermission("conversations.read"), async (c) => {
    const id = parseId(c.req.param("id"));
    const { justification } = parseQuery(c, conversationQuerySchema);
    const { conversation } = await services.reports.conversation(id);
    // The read is journalled before the content leaves: no entry, no content.
    await audit.record({
      actor: currentStaff(c).email,
      action: "conversation.read",
      targetType: "conversation",
      targetId: conversation.conversationId === null ? null : String(conversation.conversationId),
      justification,
      details: { reportId: id, messageCount: conversation.messages.length },
    });
    return ok(c, conversation);
  });

  return router;
}
