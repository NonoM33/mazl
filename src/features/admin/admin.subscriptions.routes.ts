import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import { getAllSubscriptions } from "../../db";
import { assertAdmin } from "./admin.auth";

// Admin subscriptions route, moved verbatim from the monolith (src/index.ts).
// Same path, behaviour, payloads and status codes.
export function registerAdminSubscriptionsRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get all subscriptions (admin)
  app.get("/api/admin/subscriptions", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const status = c.req.query("status");
      const limit = parseInt(c.req.query("limit") || "100");
      const offset = parseInt(c.req.query("offset") || "0");

      const subscriptions = await getAllSubscriptions({
        status: status || undefined,
        limit,
        offset,
      });

      return c.json({ success: true, subscriptions });
    } catch (error: unknown) {
      console.error("Admin subscriptions error:", error);
      return c.json({ success: false, error: "Failed to get subscriptions" }, 500);
    }
  });
}
