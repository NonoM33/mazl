import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import {
  getAdminStats,
  getAdminUsers,
  setUserActiveStatus,
  getAdminUserDetail,
  banUser,
  unbanUser,
  addAdminNote,
  getUserActivity,
  deleteUserCompletely,
  setUserVerificationLevel,
} from "../../db";
import { assertAdmin } from "./admin.auth";

// Admin members routes, moved verbatim from the monolith (src/index.ts). Two
// original blocks are preserved in order: the "ADMIN USERS" block (stats, users
// list, status), then (after subscriptions/dev) the "MODULE 1: GESTION MEMBRES"
// block (user detail, ban/unban, notes, activity, delete, verification level).

export function registerAdminUsersOverviewRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get admin stats
  app.get("/api/admin/stats", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const stats = await getAdminStats();
      return c.json({ success: true, stats });
    } catch (error: unknown) {
      console.error("Admin stats error:", error);
      return c.json({ success: false, error: "Failed to get stats" }, 500);
    }
  });

  // Get users (admin)
  app.get("/api/admin/users", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const search = c.req.query("search");
      const limit = parseInt(c.req.query("limit") || "50");
      const offset = parseInt(c.req.query("offset") || "0");

      const users = await getAdminUsers({
        search: search || undefined,
        limit,
        offset,
      });

      return c.json({ success: true, users });
    } catch (error: unknown) {
      console.error("Admin users error:", error);
      return c.json({ success: false, error: "Failed to get users" }, 500);
    }
  });

  // Update user status (admin)
  app.put("/api/admin/users/:id/status", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      const { isActive } = await c.req.json();

      if (typeof isActive !== "boolean") {
        return c.json({ success: false, error: "isActive boolean required" }, 400);
      }

      await setUserActiveStatus(userId, isActive);
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Update user status error:", error);
      return c.json({ success: false, error: "Failed to update user status" }, 500);
    }
  });
}

export function registerAdminMembersModuleRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get user detail (admin)
  app.get("/api/admin/users/:id", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      const user = await getAdminUserDetail(userId);

      if (!user) {
        return c.json({ success: false, error: "User not found" }, 404);
      }

      return c.json({ success: true, user });
    } catch (error: unknown) {
      console.error("Get user detail error:", error);
      return c.json({ success: false, error: "Failed to get user" }, 500);
    }
  });

  // Ban user (admin)
  app.post("/api/admin/users/:id/ban", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      const body = await c.req.json();

      if (!body.reason) {
        return c.json({ success: false, error: "Reason required" }, 400);
      }

      const ban = await banUser({
        userId,
        reason: body.reason,
        bannedBy: auth.email || "admin",
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
        isPermanent: body.isPermanent ?? false,
      });

      return c.json({ success: true, ban });
    } catch (error: unknown) {
      console.error("Ban user error:", error);
      return c.json({ success: false, error: "Failed to ban user" }, 500);
    }
  });

  // Unban user (admin)
  app.post("/api/admin/users/:id/unban", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      await unbanUser(userId, auth.email || "admin");
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Unban user error:", error);
      return c.json({ success: false, error: "Failed to unban user" }, 500);
    }
  });

  // Add note to user (admin)
  app.post("/api/admin/users/:id/notes", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      const { note } = await c.req.json();

      if (!note) {
        return c.json({ success: false, error: "Note required" }, 400);
      }

      const result = await addAdminNote({
        userId,
        adminEmail: auth.email || "admin",
        note,
      });

      return c.json({ success: true, note: result });
    } catch (error: unknown) {
      console.error("Add note error:", error);
      return c.json({ success: false, error: "Failed to add note" }, 500);
    }
  });

  // Get user activity (admin)
  app.get("/api/admin/users/:id/activity", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      const activity = await getUserActivity(userId);
      return c.json({ success: true, activity });
    } catch (error: unknown) {
      console.error("Get activity error:", error);
      return c.json({ success: false, error: "Failed to get activity" }, 500);
    }
  });

  // Delete user (admin)
  app.delete("/api/admin/users/:id", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      await deleteUserCompletely(userId, auth.email || "admin");
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete user error:", error);
      return c.json({ success: false, error: "Failed to delete user" }, 500);
    }
  });

  // Update user verification (admin)
  app.put("/api/admin/users/:id/verification", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const userId = parseInt(c.req.param("id"));
      const { level } = await c.req.json();

      if (!level) {
        return c.json({ success: false, error: "Level required" }, 400);
      }

      await setUserVerificationLevel(userId, level);
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Set verification error:", error);
      return c.json({ success: false, error: "Failed to set verification" }, 500);
    }
  });
}
