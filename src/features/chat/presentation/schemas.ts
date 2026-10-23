import { z } from "zod";

// Request bodies at the HTTP and WebSocket boundaries (CONTRAT.md §2).
// `.passthrough()` follows the rest of the API: fields an older or newer app
// adds are ignored, never rejected.

const clientId = z.string().regex(/^[\w.:-]{1,64}$/, "must be 1 to 64 characters of letters, digits, _ . : -");

export const sendMessageSchema = z
  .object({
    client_id: clientId.optional(),
    type: z.enum(["text", "photo", "voice"]).optional(),
    content: z.string().max(5000).optional(),
    media_ids: z.array(z.number().int().positive()).max(10).optional(),
    reply_to_id: z.number().int().positive().nullable().optional(),
  })
  .passthrough();

export const reactionSchema = z.object({ emoji: z.string().min(1).max(16) }).passthrough();

export const reportSchema = z
  .object({
    reason: z.string().trim().min(1).max(100),
    details: z.string().max(1000).optional(),
  })
  .passthrough();

export const readSchema = z.object({ up_to_id: z.number().int().positive().optional() }).passthrough();

// WebSocket `chat:send` keeps the shape installed apps already use.
export const socketSendSchema = z
  .object({
    conversationId: z.number().int().positive(),
    content: z.string().min(1),
    clientId: clientId.optional(),
    replyToId: z.number().int().positive().nullable().optional(),
  })
  .passthrough();

export const socketTypingSchema = z
  .object({ conversationId: z.number().int().positive(), isTyping: z.boolean().optional() })
  .passthrough();

export const socketReadSchema = z
  .object({ conversationId: z.number().int().positive(), upToId: z.number().int().positive().optional() })
  .passthrough();

export function parseId(raw: string | undefined): number | null {
  return raw !== undefined && /^\d{1,9}$/.test(raw) && Number(raw) > 0 ? Number(raw) : null;
}
