import type { Context, Env, Hono } from "hono";
import { Hono as HonoApp } from "hono";
import type { AuditLog } from "../../audit/application/ports";
import { currentStaff, type RequirePermission, type StaffVariables } from "../../staff/application/ports";
import { ConciergeNotFoundError, ConciergeRuleError, type ConciergeService } from "../application/concierge-service";
import { REQUEST_STATUSES, type RequestStatus } from "../domain/concierge";
import { conciergeListItem, staffMessageDto, staffRequestDto } from "./dto";
import { fail, ok, readBody, routeId } from "./http";
import { buildOpenApi } from "./openapi";
import { honoPath, OPERATIONS, type OperationSpec } from "./operations";
import { staffMessageBody, staffPatchBody } from "./schemas";

type Ctx = Context<{ Variables: StaffVariables }>;

export interface StaffConciergeDeps {
  readonly requirePermission: RequirePermission;
  readonly concierge: ConciergeService;
  readonly audit: AuditLog;
  // Active staff members holding concierge.manage.
  readonly assignableStaff: () => Promise<{ email: string; name: string }[]>;
  // False in production: the document of the staff routes is not distributed there.
  readonly exposeOpenApi: boolean;
}

export function registerStaffConciergeRoutes<E extends Env>(app: Hono<E>, deps: StaffConciergeDeps): void {
  const router = new HonoApp<{ Variables: StaffVariables }>();
  const { concierge, audit } = deps;

  const staffDetail = (view: Awaited<ReturnType<ConciergeService["staffView"]>>) => ({
    request: staffRequestDto(view.request),
    couple: { firstNames: view.couple.firstNames, months: view.couple.months },
    messages: view.messages.map(staffMessageDto),
  });

  function failure(c: Ctx, error: unknown): Response {
    if (error instanceof ConciergeNotFoundError) return fail(c, 404, "concierge_not_found");
    if (error instanceof ConciergeRuleError) return fail(c, 409, error.code);
    console.error("Staff concierge failed:", error instanceof Error ? error.name : "unknown");
    return fail(c, 500, "internal_error");
  }

  const handlers: Record<string, (c: Ctx) => Promise<Response> | Response> = {
    staffConciergeList: async (c) => {
      const raw = c.req.query("status");
      if (raw !== undefined && raw !== "" && !(REQUEST_STATUSES as readonly string[]).includes(raw)) return fail(c, 400, "invalid_query", "status: valeur inconnue");
      const requests = await concierge.listForStaff(raw === undefined || raw === "" ? undefined : (raw as RequestStatus));
      const summaries = new Map<number, { firstNames: readonly string[]; months: number }>();
      for (const coupleId of new Set(requests.map((request) => request.coupleId))) {
        const summary = await concierge.coupleSummary(coupleId);
        summaries.set(coupleId, summary === null ? { firstNames: [], months: 0 } : { firstNames: summary.firstNames, months: summary.months });
      }
      return ok(c, { requests: requests.map((request) => ({ ...conciergeListItem(request), assignedTo: request.assignedTo, couple: summaries.get(request.coupleId) ?? { firstNames: [], months: 0 } })) });
    },

    staffConciergeGet: async (c) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      return ok(c, staffDetail(await concierge.staffView(id)));
    },

    staffConciergePatch: async (c) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      const body = await readBody(c, staffPatchBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      const patch = { ...body.data, ...(typeof body.data.assignedTo === "string" ? { assignedTo: body.data.assignedTo.trim().toLowerCase() } : {}) };
      if (typeof patch.assignedTo === "string") {
        const assignee = patch.assignedTo;
        if (!(await deps.assignableStaff()).some((member) => member.email === assignee)) return fail(c, 400, "invalid_body", "assignedTo: staff inconnu");
      }
      const view = await concierge.staffPatch(id, patch);
      await audit.record({
        actor: currentStaff(c).email,
        action: "concierge.update",
        targetType: "concierge_request",
        targetId: String(id),
        details: { ...(patch.status === undefined ? {} : { status: patch.status }), noteChanged: patch.staffNote !== undefined, ...(patch.assignedTo === undefined ? {} : { assigned: patch.assignedTo !== null }) },
      });
      return ok(c, staffDetail(view));
    },

    staffConciergeMessage: async (c) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      const body = await readBody(c, staffMessageBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      const view = await concierge.staffMessage(id, null, body.data.text);
      await audit.record({ actor: currentStaff(c).email, action: "concierge.reply", targetType: "concierge_request", targetId: String(id), details: { length: body.data.text.length } });
      return ok(c, staffDetail(view), 201);
    },

    staffConciergeStaff: async (c) => ok(c, { staff: await deps.assignableStaff() }),

    coupleOpenApi: (c) => (deps.exposeOpenApi ? c.json(buildOpenApi()) : fail(c, 404, "not_found")),
  };

  const wrap = (operation: OperationSpec) => async (c: Ctx): Promise<Response> => {
    const handler = handlers[operation.operationId];
    if (handler === undefined) throw new Error(`no handler for ${operation.operationId}`);
    try {
      return await handler(c);
    } catch (error: unknown) {
      return failure(c, error);
    }
  };

  for (const operation of OPERATIONS.filter((candidate) => candidate.audience === "staff")) {
    if (operation.permission === null) throw new Error(`${operation.operationId} has no permission`);
    const guard = deps.requirePermission(operation.permission);
    const path = honoPath(operation.path);
    if (operation.method === "get") router.get(path, guard, wrap(operation));
    else if (operation.method === "post") router.post(path, guard, wrap(operation));
    else router.patch(path, guard, wrap(operation));
  }
  app.route("/", router as unknown as Hono<E>);
}
