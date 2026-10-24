import { Hono } from "hono";
import type { Env } from "hono";
import { TrustSafetyError } from "../application/errors";
import { appealsRoutes, registerPublicAppealRoute } from "./appeals.routes";
import { figuresRoutes } from "./figures.routes";
import { membersRoutes } from "./members.routes";
import { reportsRoutes } from "./reports.routes";
import type { RouteDeps } from "./route-deps";
import type { StaffVariables } from "../../staff/application/ports";

export type { RouteDeps, TrustSafetyServices } from "./route-deps";

// Mounts the back-office routes under /api/backoffice and the public appeal at
// /api/appeals. Expected failures keep their code and status; anything else is
// logged (no payload) and answered 500.
export function registerTrustSafetyRoutes<E extends Env>(app: Hono<E>, deps: RouteDeps): void {
  const router = new Hono<{ Variables: StaffVariables }>();
  router.route("/", reportsRoutes(deps));
  router.route("/", membersRoutes(deps));
  router.route("/", appealsRoutes(deps));
  router.route("/", figuresRoutes(deps));
  router.onError((error, c) => {
    if (error instanceof TrustSafetyError) {
      return c.json({ success: false, error: error.code, message: error.message }, error.status);
    }
    console.error("trust-safety: unexpected failure", error.name);
    return c.json({ success: false, error: "internal_error" }, 500);
  });
  app.route("/api/backoffice", router);
  registerPublicAppealRoute(app, deps.services.appeals);
}
