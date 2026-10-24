import { Hono } from "hono";
import {
  activateBoost,
  getActiveBoost,
  getBoostsUsedToday,
  createReport,
  blockUser,
  unblockUser,
  getBlockedUsers,
  findUserById,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { createRateLimiter } from "../../shared/http/rate-limit";
import { legacyReportBodySchema, parseBody, parseId, reportUserBodySchema } from "../../shared/http/validation";
import type { CreditsGateway } from "../credits/application/ports";
import { registerBoostRoutes } from "./boost.routes";

// Presentation layer for the ENGAGEMENT feature.
//
// Covers two related engagement surfaces (selfie verification moved to
// src/features/verification):
//   - Boost: /api/boost/status, /api/boost/activate
//   - Moderation (block / report): POST/DELETE /api/users/:id/block,
//     GET /api/users/blocked, POST /api/users/:id/report, POST /api/report
//
// None of these route patterns collide with each other or with the profile
// routes, so their relative registration order is behaviour-neutral.

export interface EngagementRouteDeps {
  readonly credits: CreditsGateway;
}

// One budget for both report routes: 20 reports an hour and member, so that a
// member cannot flood the moderators.
const REPORTS_PER_HOUR = 20;
const HOUR_MS = 60 * 60 * 1000;

export function registerEngagementRoutes(app: Hono<{ Variables: AppVariables }>, deps: EngagementRouteDeps): void {
  const reportLimiter = createRateLimiter({ max: REPORTS_PER_HOUR, windowMs: HOUR_MS });

  // ============ BOOST ============
  // GET /api/boost/status and POST /api/boost/activate, against the credits.
  registerBoostRoutes(app, {
    authenticate: requireAuth,
    credits: deps.credits,
    boosts: { getActive: getActiveBoost, usedToday: getBoostsUsedToday, activate: activateBoost },
  });

  // ============ MODULE 4: MODÉRATION & SIGNALEMENTS ============

  // Block a user
  app.post("/api/users/:id/block", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const blockedId = parseId(c.req.param("id"));
      if (blockedId === null) {
        return c.json({ success: false, error: "Invalid user id" }, 400);
      }
      if (blockedId === userId) {
        return c.json({ success: false, error: "Cannot block yourself" }, 400);
      }
      if ((await findUserById(blockedId)) === null) {
        return c.json({ success: false, error: "User not found" }, 404);
      }

      await blockUser(userId, blockedId);
      return c.json({ success: true });
    } catch (error) {
      console.error("Block user error:", error);
      return c.json({ success: false, error: "Failed to block user" }, 500);
    }
  });

  // Unblock a user
  app.delete("/api/users/:id/block", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const blockedId = parseId(c.req.param("id"));
      if (blockedId === null) {
        return c.json({ success: false, error: "Invalid user id" }, 400);
      }

      await unblockUser(userId, blockedId);
      return c.json({ success: true });
    } catch (error) {
      console.error("Unblock user error:", error);
      return c.json({ success: false, error: "Failed to unblock user" }, 500);
    }
  });

  // List profiles blocked by the current user
  app.get("/api/users/blocked", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const blocked = await getBlockedUsers(userId);
      return c.json({ success: true, blocked });
    } catch (error) {
      console.error("Get blocked users error:", error);
      return c.json({ success: false, error: "Failed to get blocked users" }, 500);
    }
  });

  // Report a user (mobile alias for POST /api/report, with optional block)
  app.post("/api/users/:id/report", requireAuth, reportLimiter, async (c) => {
    try {
      const userId = c.get("userId");
      const reportedUserId = parseId(c.req.param("id"));
      if (reportedUserId === null) {
        return c.json({ success: false, error: "Invalid user id" }, 400);
      }
      if (reportedUserId === userId) {
        return c.json({ success: false, error: "Cannot report yourself" }, 400);
      }

      const parsed = await parseBody(reportUserBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const { category, comment, block_user: blockUserFlag } = parsed.data;

      if ((await findUserById(reportedUserId)) === null) {
        return c.json({ success: false, error: "User not found" }, 404);
      }

      const report = await createReport({
        reporterId: userId,
        reportedUserId,
        reason: category,
        details: comment,
      });

      if (blockUserFlag === true) {
        await blockUser(userId, reportedUserId);
      }

      return c.json({ success: true, report, blocked: blockUserFlag === true });
    } catch (error) {
      console.error("Report user error:", error);
      return c.json({ success: false, error: "Failed to create report" }, 500);
    }
  });

  // Report user (legacy body)
  app.post("/api/report", requireAuth, reportLimiter, async (c) => {
    try {
      const userId = c.get("userId");

      const parsed = await parseBody(legacyReportBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const { reportedUserId, reason, details } = parsed.data;
      if (reportedUserId === userId) {
        return c.json({ success: false, error: "Cannot report yourself" }, 400);
      }
      if ((await findUserById(reportedUserId)) === null) {
        return c.json({ success: false, error: "User not found" }, 404);
      }

      const report = await createReport({
        reporterId: userId,
        reportedUserId,
        reason,
        details,
      });

      return c.json({ success: true, report });
    } catch (error: unknown) {
      console.error("Report error:", error);
      return c.json({ success: false, error: "Failed to create report" }, 500);
    }
  });
}
