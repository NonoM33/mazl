import type { Context, Hono } from "hono";
import { getConversationById, getConversations } from "../../../db";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import { parseBody } from "../../../shared/http/validation";
import type { ChatService } from "../application/chat-service";
import { notFound } from "../domain/errors";
import { notFoundResponse, respondToFailure } from "./http-errors";
import { parseId, readSchema, sendMessageSchema } from "./schemas";

type ChatApp = Hono<{ Variables: AppVariables }>;
type ChatContext = Context<{ Variables: AppVariables }>;

const sendLimiter = createRateLimiter({ max: 90, windowMs: 60_000 });

// Digits only, or the default; anything else is the caller's mistake.
function queryNumber(raw: string | undefined): number | null | "invalid" {
  if (raw === undefined || raw === "") return null;
  return /^\d{1,9}$/.test(raw) ? Number(raw) : "invalid";
}

async function optionalReadBody(c: ChatContext) {
  const text = await c.req.text();
  if (text.trim() === "") return { ok: true as const, upToId: null };
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    return { ok: true as const, upToId: null };
  }
  const parsed = readSchema.safeParse(raw);
  return parsed.success ? { ok: true as const, upToId: parsed.data.up_to_id ?? null } : { ok: false as const };
}

// Conversation list and detail (unchanged URLs), message history, send and read.
export function registerChatRoutes(app: ChatApp, chat: ChatService): void {
  app.get("/api/conversations", requireAuth, async (c) => {
    try {
      return c.json({ success: true, conversations: await getConversations(c.get("userId")) });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });

  app.get("/api/conversations/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const conversationId = parseId(c.req.param("id"));
      const conversation = conversationId === null ? null : await getConversationById(conversationId);
      const row = conversation as { user1_id: number; user2_id: number } | null;
      // A conversation that is not yours looks exactly like one that does not exist.
      if (row === null || (row.user1_id !== userId && row.user2_id !== userId)) throw notFound();
      return c.json({ success: true, conversation });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });

  app.get("/api/conversations/:id/messages", requireAuth, async (c) => {
    try {
      const conversationId = parseId(c.req.param("id"));
      if (conversationId === null) return notFoundResponse(c);
      const before = queryNumber(c.req.query("before"));
      const limit = queryNumber(c.req.query("limit"));
      if (before === "invalid" || limit === "invalid") {
        return c.json({ success: false, error: "before and limit must be positive integers" }, 400);
      }
      const page = await chat.listMessages(c.get("userId"), conversationId, { before, limit });
      return c.json({ success: true, messages: page.messages, has_more: page.hasMore });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });

  app.post("/api/conversations/:id/messages", requireAuth, sendLimiter, async (c) => {
    try {
      const conversationId = parseId(c.req.param("id"));
      if (conversationId === null) return notFoundResponse(c);
      const parsed = await parseBody(sendMessageSchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const body = parsed.data;
      const { message } = await chat.send(c.get("userId"), conversationId, {
        clientId: body.client_id,
        type: body.type,
        content: body.content,
        mediaIds: body.media_ids,
        replyToId: body.reply_to_id,
      });
      return c.json({ success: true, message });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });

  app.put("/api/conversations/:id/read", requireAuth, async (c) => {
    try {
      const conversationId = parseId(c.req.param("id"));
      if (conversationId === null) return notFoundResponse(c);
      const body = await optionalReadBody(c);
      if (!body.ok) return c.json({ success: false, error: "up_to_id must be a positive integer" }, 400);
      const outcome = await chat.markRead(c.get("userId"), conversationId, body.upToId);
      return c.json({ success: true, up_to_id: outcome?.upToId ?? null, read_at: outcome?.readAt.toISOString() ?? null });
    } catch (error: unknown) {
      return respondToFailure(c, error);
    }
  });
}
