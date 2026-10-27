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
} from "../../db";
import { sql } from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { NO_PREMIUM } from "./domain/premium";
import { PgCouplePremium } from "./infra/pg-couple-premium";
import { parseBody } from "../../shared/http/validation";
import {
  archiveConversationsBodySchema,
  assertCoupleMembership,
  coupleRequestBodySchema,
  coupleRespondBodySchema,
  GENERIC_SERVER_ERROR,
  relationshipStatusBodySchema,
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
  const premium = new PgCouplePremium(sql);
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
        return c.json({ success: true, couple: null, milestones: [], premium: NO_PREMIUM });
      }

      const daysTogether = couple.started_at
        ? Math.floor((Date.now() - new Date(couple.started_at).getTime()) / (1000 * 60 * 60 * 24))
        : 0;
      await checkAndRecordMilestones(couple.id, daysTogether);
      const milestones = await getCoupleMilestones(couple.id);

      // MAZL Couple (docs/couple/ESPACE-COUPLE.md section 1): computed from both members' subscriptions.
      return c.json({ success: true, couple, milestones, premium: await premium.of(userId, couple.id, new Date()) });
    } catch (error: unknown) {
      console.error("Get couple error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
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
        return c.json({ success: false, error: result.error }, result.status ?? 400);
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
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
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
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
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
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
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
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
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
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Archive the user's conversations except with the partner. Only a member of
  // an active couple may do it, and the partner kept is always the couple's own.
  app.post("/api/couple/archive-conversations", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(archiveConversationsBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }

      const couple = await getCoupleViewFor(userId);
      if (!couple) {
        return c.json({ success: false, error: "Not in a couple" }, 403);
      }
      const requestedPartner = parsed.data.partner_user_id;
      if (requestedPartner !== undefined && requestedPartner !== null && requestedPartner !== couple.partner_id) {
        return c.json({ success: false, error: "Forbidden" }, 403);
      }

      const { archived } = await archiveConversationsExceptPartner(
        userId,
        couple.partner_id,
        parsed.data.message ?? undefined,
      );

      return c.json({ success: true, archived });
    } catch (error) {
      console.error("Archive conversations error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Update relationship status
  app.patch("/api/couple/:coupleId/status", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ success: false, error: "Forbidden" }, 403);
      }
      const parsed = await parseBody(relationshipStatusBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }

      await updateRelationshipStatus(coupleId, parsed.data.relationshipStatus);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Update couple status error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // End couple mode (soft delete)
  app.delete("/api/couple/:coupleId", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ success: false, error: "Forbidden" }, 403);
      }
      const couple = await getCoupleViewFor(userId);
      await deleteCouple(coupleId);
      if (couple) emitCoupleEnded(couple.partner_id, coupleId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete couple error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });

  // Get milestones
  app.get("/api/couple/:coupleId/milestones", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const coupleId = parseInt(c.req.param("coupleId"));
      if (!(await assertCoupleMembership(userId, coupleId))) {
        return c.json({ success: false, error: "Forbidden" }, 403);
      }
      const milestones = await getCoupleMilestones(coupleId);

      return c.json({ success: true, milestones });
    } catch (error: unknown) {
      console.error("Get milestones error:", error);
      return c.json({ success: false, error: GENERIC_SERVER_ERROR }, 500);
    }
  });
}
