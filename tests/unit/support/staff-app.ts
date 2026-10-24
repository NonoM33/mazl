import { Hono } from "hono";
import type { Env } from "hono";
import type { RequirePermission } from "../../../src/features/staff/application/ports";
import type { Permission, StaffRole } from "../../../src/features/staff/domain/roles";
import { createMiddleware } from "hono/factory";
import type { StaffVariables } from "../../../src/features/staff/application/ports";

// A guard stub for route tests: the role comes from a header.
export const headerGuard: RequirePermission = (permission: Permission) =>
  createMiddleware<{ Variables: StaffVariables }>(async (c, next) => {
    const role = c.req.header("x-test-role");
    if (!role) return c.json({ success: false, error: "unauthorized" }, 401);
    if (role === "none") return c.json({ success: false, error: "forbidden" }, 403);
    c.set("staff", { email: "tester@example.com", role: role as StaffRole, mfa: true });
    void permission;
    await next();
  });

export function newApp(): Hono<Env> {
  return new Hono();
}
