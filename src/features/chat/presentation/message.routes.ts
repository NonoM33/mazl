import type { Hono } from "hono";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import { parseBody } from "../../../shared/http/validation";
import type { ChatLimits } from "../application/chat-limits";
import type { ChatService } from "../application/chat-service";
import { notFoundResponse, respondToFailure } from "./http-errors";
import { limitBy } from "./limit-middleware";
import { parseId, reactionSchema, reportSchema } from "./schemas";

const reportLimiter = createRateLimiter({ max: 20, windowMs: 60 * 60_000 });

// Actions on one message: /api/messages/:id/{reactions,unsend,report}.
export function registerMessageRoutes(app: Hono<{ Variables: AppVariables }>, chat: ChatService, limits: ChatLimits): void {
  app.post("/api/messages/:id/reactions", requireAuth, limitBy(limits.reactions), async (c) => {
    try {
      const messageId = parseId(c.req.param("id"));
      if (messageId === null) return notFoundResponse(c);
      const parsed = await parseBody(reactionSchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const reactions = await chat.toggleReaction(c.get("userId"), messageId, parsed.data.emoji);
      return c.json({ success: true, reactions });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });

  app.post("/api/messages/:id/unsend", requireAuth, limitBy(limits.unsend), async (c) => {
    try {
      const messageId = parseId(c.req.param("id"));
      if (messageId === null) return notFoundResponse(c);
      return c.json({ success: true, message: await chat.unsend(c.get("userId"), messageId) });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });

  app.post("/api/messages/:id/report", requireAuth, reportLimiter, async (c) => {
    try {
      const messageId = parseId(c.req.param("id"));
      if (messageId === null) return notFoundResponse(c);
      const parsed = await parseBody(reportSchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      await chat.report(c.get("userId"), messageId, parsed.data.reason, parsed.data.details ?? null);
      return c.json({ success: true });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });
}
