import { Hono } from "hono";
import {
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
} from "./couple.shared";
import {
  canRequestCouple,
  getCoupleRequestView,
  getCoupleViewFor,
} from "./infra/couple-queries";
import {
  emitCoupleAccepted,
  emitCoupleEnded,
  emitCoupleRejected,
  emitCoupleRequest,
  pushCoupleAccepted,
  pushCoupleRequest,
} from "./application/couple-notifier";

// COUPLE feature — core endpoints: couple creation/retrieval, couple requests
// (send / respond / cancel / list / check / archive), and the
// membership-gated status / question / milestones routes. Moved verbatim from
// src/index.ts, preserving behaviour, payloads, status codes and — critically —
// the relative declaration order: the literal `request(s)` / `check` /
// `archive-conversations` routes stay registered BEFORE the parameterised
// `/api/couple/:coupleId*` routes so the `:coupleId` param never captures them.
export function registerCoupleCoreRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // ============ COUPLE MODE ENDPOINTS ============

  // A couple is never created on one member's word alone (contract §0.1):
  // it only exists once the other member accepted a request.
  app.post("/api/couple", requireAuth, (c) =>
    c.json({ success: false, error: "couple_request_required" }, 403),
  );

  // Get current user's couple (contract §1, seen from the caller)
  app.get("/api/couple", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const couple = await getCoupleViewFor(userId);
      if (!couple) {
        return c.json({ success: true, couple: null, milestones: [] });
      }

      const daysTogether = couple.started_at
        ? Math.floor((Date.now() - new Date(couple.started_at).getTime()) / (1000 * 60 * 60 * 24))
        : 0;
      await checkAndRecordMilestones(couple.id, daysTogether);
      const milestones = await getCoupleMilestones(couple.id);

      return c.json({ success: true, couple, milestones });
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

      if (targetUserId === userId) {
        return c.json({ success: false, error: "Cannot send a couple request to yourself" }, 400);
      }
      if (!(await canRequestCouple(userId, targetUserId))) {
        return c.json({ success: false, error: "not_matched" }, 403);
      }

      const result = await createCoupleRequest(userId, targetUserId);
      if (!result.ok) {
        return c.json({ success: false, error: result.error }, 400);
      }

      const view = await getCoupleRequestView(result.request.id);
      if (!view) {
        return c.json({ success: false, error: "Couple request not found" }, 500);
      }
      emitCoupleRequest(view);
      pushCoupleRequest(view);

      return c.json({
        success: true,
        request: {
          id: view.id,
          requester_id: view.requester_id,
          target_id: view.target_id,
          status: view.status,
          created_at: view.created_at,
          target_name: view.target_name,
          target_picture: view.target_picture,
        },
      });
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

      const request = await getCoupleRequestView(requestId);
      const requesterId = request?.requester_id;

      if (result.action === "accepted") {
        const couple = await getCoupleViewFor(userId);
        if (!couple) {
          return c.json({ success: false, error: "Couple not found" }, 500);
        }
        if (requesterId !== undefined) {
          const requesterCouple = await getCoupleViewFor(requesterId);
          if (requesterCouple) {
            emitCoupleAccepted(requesterId, requesterCouple);
            pushCoupleAccepted(requesterId, requesterCouple.partner_name);
          }
        }
        return c.json({ success: true, action: "accepted", couple });
      }
      if (requesterId !== undefined) emitCoupleRejected(requesterId, requestId);
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
      const couple = await getCoupleViewFor(userId);
      await deleteCouple(coupleId);
      if (couple) emitCoupleEnded(couple.partner_id, coupleId);

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
