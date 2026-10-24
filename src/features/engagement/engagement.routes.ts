import { Hono } from "hono";
import { z } from "zod";
import {
  activateBoost,
  getActiveBoost,
  getBoostsUsedToday,
  createReport,
  blockUser,
  unblockUser,
  getBlockedUsers,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parseBody } from "../../shared/http/validation";
import type { CreditsGateway } from "../credits/application/ports";
import { registerBoostRoutes } from "./boost.routes";

// Presentation layer for the ENGAGEMENT feature. These routes are moved
// verbatim from the monolith (src/index.ts): behaviour, payloads, status codes
// and relative ordering are identical to the original inline handlers.
//
// Covers two related engagement surfaces (selfie verification moved to
// src/features/verification):
//   - Boost: /api/boost/status, /api/boost/activate
//   - Moderation (block / report): POST/DELETE /api/users/:id/block,
//     GET /api/users/blocked, POST /api/users/:id/report, POST /api/report
//
// None of these route patterns collide with each other or with the profile
// routes, so their relative registration order is behaviour-neutral.

const reportUserBodySchema = z
  .object({
    category: z.string().optional(),
    comment: z.string().optional(),
    block_user: z.boolean().optional(),
  })
  .passthrough();

export interface EngagementRouteDeps {
  readonly credits: CreditsGateway;
}

export function registerEngagementRoutes(app: Hono<{ Variables: AppVariables }>, deps: EngagementRouteDeps): void {
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
      const blockedId = Number.parseInt(c.req.param("id"), 10);
      if (Number.isNaN(blockedId)) {
        return c.json({ success: false, error: "Invalid user id" }, 400);
      }
      if (blockedId === userId) {
        return c.json({ success: false, error: "Cannot block yourself" }, 400);
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
      const blockedId = Number.parseInt(c.req.param("id"), 10);
      if (Number.isNaN(blockedId)) {
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
  app.post("/api/users/:id/report", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const reportedUserId = Number.parseInt(c.req.param("id"), 10);
      if (Number.isNaN(reportedUserId)) {
        return c.json({ success: false, error: "Invalid user id" }, 400);
      }

      const parsed = await parseBody(reportUserBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const body = parsed.data;
      const category = body.category;
      const comment = body.comment;
      const blockUserFlag = body.block_user === true;

      if (!category) {
        return c.json({ success: false, error: "Category required" }, 400);
      }

      const report = await createReport({
        reporterId: userId,
        reportedUserId,
        reason: category,
        details: comment,
      });

      if (blockUserFlag && reportedUserId !== userId) {
        await blockUser(userId, reportedUserId);
      }

      return c.json({ success: true, report, blocked: blockUserFlag && reportedUserId !== userId });
    } catch (error) {
      console.error("Report user error:", error);
      return c.json({ success: false, error: "Failed to create report" }, 500);
    }
  });

  // Report user (from mobile app)
  app.post("/api/report", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const { reportedUserId, reason, details } = await c.req.json();

      if (!reportedUserId || !reason) {
        return c.json({ success: false, error: "Reported user ID and reason required" }, 400);
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
