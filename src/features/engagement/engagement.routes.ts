import { Hono } from "hono";
import { z } from "zod";
import {
  activateBoost,
  getActiveBoost,
  getBoostsUsedToday,
  startVerification,
  submitVerification,
  getVerificationStatus,
  createReport,
  blockUser,
  unblockUser,
  getBlockedUsers,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parseBody } from "../../shared/http/validation";

// Presentation layer for the ENGAGEMENT feature. These routes are moved
// verbatim from the monolith (src/index.ts): behaviour, payloads, status codes
// and relative ordering are identical to the original inline handlers.
//
// Covers three related engagement surfaces:
//   - Selfie verification (US-TS-03): /api/verification/start|submit|status
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

// Free-tier daily boost allowance. Premium (unlimited) enforcement lives
// on the client for now; the server just reports a sensible remaining count.
const FREE_DAILY_BOOSTS = 3;

async function buildBoostStatus(userId: number) {
  const [activeBoost, boostsUsedToday] = await Promise.all([
    getActiveBoost(userId),
    getBoostsUsedToday(userId),
  ]);

  const remainingBoosts = Math.max(0, FREE_DAILY_BOOSTS - boostsUsedToday);
  const expiresAt = activeBoost ? activeBoost.expires_at.toISOString() : null;

  // Keys are snake_case to match the mobile BoostStatus.fromJson parser.
  return {
    is_active: activeBoost !== null,
    expires_at: expiresAt,
    active_until: expiresAt,
    remaining_boosts: remainingBoosts,
    boosts_used_today: boostsUsedToday,
    views_during_boost: 0,
    likes_during_boost: 0,
  };
}

export function registerEngagementRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // ============ SELFIE VERIFICATION (US-TS-03) ============
  // Distinct from the WEB email-token flow at /api/verify/* — do not conflate.
  // These literal /api/verification/* routes are registered before any
  // parameterized route that could otherwise capture them.

  // Start a selfie verification: returns a random gesture to perform.
  app.post("/api/verification/start", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const result = await startVerification(userId);
      if (!result.ok) {
        // Daily quota exhausted — enforced server-side.
        return c.json(
          {
            success: false,
            error: result.message ?? "Daily verification limit reached",
            next_attempt_time: result.nextAttemptTime,
          },
          429,
        );
      }

      return c.json({ success: true, gesture_id: result.gestureId });
    } catch (error: unknown) {
      console.error("Verification start error:", error);
      return c.json({ success: false, error: "Failed to start verification" }, 500);
    }
  });

  // Submit a selfie (base64) for the given gesture.
  app.post("/api/verification/submit", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const body = await c.req.json().catch(() => null);
      const rawGesture =
        body && typeof body.gesture_id === "string" ? body.gesture_id : "";
      const selfie =
        body && typeof body.selfie === "string" ? body.selfie : "";
      // The base64 selfie is used transiently only; it is never persisted to
      // profile_photos / profiles.photos. We just check that one was provided.
      const imageProvided = selfie.length > 0;

      const result = await submitVerification(userId, rawGesture, imageProvided);
      if (result.nextAttemptTime && !result.verified && result.attemptsRemaining === 0) {
        // Quota was already exhausted before this call — refuse.
        return c.json(
          {
            success: false,
            error: result.message,
            next_attempt_time: result.nextAttemptTime,
          },
          429,
        );
      }

      return c.json({
        success: true,
        verified: result.verified,
        message: result.message,
        attempts_remaining: result.attemptsRemaining,
      });
    } catch (error: unknown) {
      console.error("Verification submit error:", error);
      return c.json({ success: false, error: "Failed to submit verification" }, 500);
    }
  });

  // Current verification status (verified flag + daily quota).
  app.get("/api/verification/status", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const status = await getVerificationStatus(userId);
      return c.json({
        success: true,
        is_verified: status.isVerified,
        attempts_today: status.attemptsToday,
        next_attempt_time: status.nextAttemptTime ?? null,
      });
    } catch (error: unknown) {
      console.error("Verification status error:", error);
      return c.json({ success: false, error: "Failed to get verification status" }, 500);
    }
  });

  // ============ BOOST ============

  // Get current boost status
  app.get("/api/boost/status", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const status = await buildBoostStatus(userId);

      return c.json({ success: true, ...status });
    } catch (error: unknown) {
      console.error("Boost status error:", error);
      return c.json({ success: false, error: "Failed to get boost status" }, 500);
    }
  });

  // Activate a boost (30 minutes)
  app.post("/api/boost/activate", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const boost = await activateBoost(userId, 30);
      const status = await buildBoostStatus(userId);

      return c.json({ success: true, boost, status, ...status }, 201);
    } catch (error: unknown) {
      console.error("Boost activate error:", error);
      return c.json({ success: false, error: "Failed to activate boost" }, 500);
    }
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
