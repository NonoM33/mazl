import { Hono } from "hono";
import {
  createCouple,
  getCouple,
  checkAndRecordMilestones,
  getCoupleMilestones,
  createCoupleRequest,
  respondToCoupleRequest,
  cancelCoupleRequest,
  getCoupleRequestsForUser,
  getCoupleStatusWith,
  archiveConversationsExceptPartner,
  updateRelationshipStatus,
  deleteCouple,
  getDailyQuestion,
  answerDailyQuestion,
  getCoupleQuestionHistory,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parseBody } from "../../shared/http/validation";
import {
  assertCoupleMembership,
  coupleRequestBodySchema,
  coupleRespondBodySchema,
  type CoupleRow,
} from "./couple.shared";

// COUPLE feature — core endpoints: couple creation/retrieval, couple requests
// (send / respond / cancel / list / check / archive), and the
// membership-gated status / question / milestones routes. Moved verbatim from
// src/index.ts, preserving behaviour, payloads, status codes and — critically —
// the relative declaration order: the literal `request(s)` / `check` /
// `archive-conversations` routes stay registered BEFORE the parameterised
// `/api/couple/:coupleId*` routes so the `:coupleId` param never captures them.
export function registerCoupleCoreRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // ============ COUPLE MODE ENDPOINTS ============

  // Create or activate couple mode
  app.post("/api/couple", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const body = await c.req.json();
      const { partnerId, relationshipStatus, startedAt } = body;

      if (!partnerId) {
        return c.json({ success: false, error: "Partner ID required" }, 400);
      }

      const couple = await createCouple(
        userId,
        partnerId,
        relationshipStatus || 'dating',
        startedAt ? new Date(startedAt) : undefined
      );

      return c.json({ success: true, couple });
    } catch (error: unknown) {
      console.error("Create couple error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Get current user's couple
  app.get("/api/couple", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const couple = await getCouple(userId);

      if (!couple) {
        return c.json({ success: true, couple: null });
      }

      const coupleRow = couple as CoupleRow;

      // Calculate days together
      const startedAt = coupleRow.started_at;
      const daysTogether = startedAt
        ? Math.floor((Date.now() - new Date(startedAt as string).getTime()) / (1000 * 60 * 60 * 24))
        : 0;

      // Check and record milestones
      await checkAndRecordMilestones(Number(coupleRow.id), daysTogether);

      // Get milestones
      const milestones = await getCoupleMilestones(Number(coupleRow.id));

      return c.json({
        success: true,
        couple: {
          ...coupleRow,
          daysTogether,
          milestones,
        },
      });
    } catch (error: unknown) {
      console.error("Get couple error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // ============ COUPLE REQUESTS (demande / acceptation de couple) ============
  // NOTE: registered before /api/couple/:coupleId so literal "request(s)"/"check"
  // segments are not captured by the :coupleId param.

  // Send a couple request
  app.post("/api/couple/request", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(coupleRequestBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const targetUserId = Number(parsed.data.target_user_id);

      if (!Number.isInteger(targetUserId) || targetUserId <= 0) {
        return c.json({ success: false, error: "target_user_id required" }, 400);
      }

      const result = await createCoupleRequest(userId, targetUserId);
      if (!result.ok) {
        return c.json({ success: false, error: result.error }, 400);
      }

      return c.json({ success: true, request: result.request });
    } catch (error) {
      console.error("Create couple request error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Respond to a couple request (accept / reject) — only the target may respond
  app.put("/api/couple/request/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const requestId = parseInt(c.req.param("id"));
      if (!Number.isInteger(requestId)) {
        return c.json({ success: false, error: "Invalid request id" }, 400);
      }

      const parsed = await parseBody(coupleRespondBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const action = parsed.data.action;

      const result = await respondToCoupleRequest(requestId, userId, action);
      if (!result.ok) {
        return c.json({ success: false, error: result.error }, result.status as 403 | 404 | 409);
      }

      if (result.action === "accepted") {
        return c.json({ success: true, action: "accepted", couple: result.couple });
      }
      return c.json({ success: true, action: "rejected" });
    } catch (error) {
      console.error("Respond couple request error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Cancel a sent couple request — only the requester may cancel
  app.delete("/api/couple/request/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const requestId = parseInt(c.req.param("id"));
      if (!Number.isInteger(requestId)) {
        return c.json({ success: false, error: "Invalid request id" }, 400);
      }

      const result = await cancelCoupleRequest(requestId, userId);
      if (!result.ok) {
        return c.json({ success: false, error: result.error }, result.status as 403 | 404 | 409);
      }

      return c.json({ success: true });
    } catch (error) {
      console.error("Cancel couple request error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // List pending couple requests (sent + received)
  app.get("/api/couple/requests", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const { sent, received } = await getCoupleRequestsForUser(userId);

      return c.json({ success: true, sent, received });
    } catch (error) {
      console.error("Get couple requests error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Check couple/request status with a specific user
  app.get("/api/couple/check/:userId", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const otherUserId = parseInt(c.req.param("userId"));
      if (!Number.isInteger(otherUserId)) {
        return c.json({ success: false, error: "Invalid user id" }, 400);
      }

      const status = await getCoupleStatusWith(userId, otherUserId);

      return c.json({
        success: true,
        status,
        in_couple_mode: status === "coupled",
      });
    } catch (error) {
      console.error("Check couple status error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Archive the user's conversations except with the partner
  app.post("/api/couple/archive-conversations", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const body = await c.req.json().catch(() => ({}));
      const rawPartner = (body as { partner_user_id?: unknown }).partner_user_id;
      const partnerUserId =
        rawPartner === undefined || rawPartner === null
          ? null
          : Number(rawPartner);
      if (partnerUserId !== null && !Number.isInteger(partnerUserId)) {
        return c.json({ success: false, error: "Invalid partner_user_id" }, 400);
      }
      const rawMessage = (body as { message?: unknown }).message;
      const message = typeof rawMessage === "string" ? rawMessage : undefined;

      const { archived } = await archiveConversationsExceptPartner(
        userId,
        partnerUserId,
        message
      );

      return c.json({ success: true, archived });
    } catch (error) {
      console.error("Archive conversations error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Update relationship status
  app.patch("/api/couple/:coupleId/status", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ error: "Forbidden" }, 403);
      }
      const { relationshipStatus } = await c.req.json();

      await updateRelationshipStatus(coupleId, relationshipStatus);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Update couple status error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // End couple mode (soft delete)
  app.delete("/api/couple/:coupleId", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ error: "Forbidden" }, 403);
      }
      await deleteCouple(coupleId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete couple error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Get daily question
  app.get("/api/couple/:coupleId/question", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ error: "Forbidden" }, 403);
      }
      const question = await getDailyQuestion(coupleId);

      return c.json({ success: true, question });
    } catch (error: unknown) {
      console.error("Get daily question error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Answer daily question
  app.post("/api/couple/:coupleId/question/:questionId/answer", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ error: "Forbidden" }, 403);
      }
      const questionId = parseInt(c.req.param("questionId"));
      const { answer } = await c.req.json();

      await answerDailyQuestion(coupleId, questionId, userId, answer);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Answer question error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Get question history
  app.get("/api/couple/:coupleId/questions", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ error: "Forbidden" }, 403);
      }
      const questions = await getCoupleQuestionHistory(coupleId);

      return c.json({ success: true, questions });
    } catch (error: unknown) {
      console.error("Get questions error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });

  // Get milestones
  app.get("/api/couple/:coupleId/milestones", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ error: "Forbidden" }, 403);
      }
      const milestones = await getCoupleMilestones(coupleId);

      return c.json({ success: true, milestones });
    } catch (error: unknown) {
      console.error("Get milestones error:", error);
      return c.json({ success: false, error: (error as Error).message }, 500);
    }
  });
}
