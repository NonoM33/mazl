import { z } from "zod";
import { getCouple } from "../../db";

// Shared helpers and schemas for the COUPLE feature. Extracted verbatim from the
// monolith (src/index.ts): behaviour is identical, but the couple-only
// `assertCoupleMembership` helper and the request/respond body schemas now live
// with the feature that uses them exclusively.

// A couple row as returned by the DB layer. Only `id` is read by the couple
// route handlers; the rest of the row is preserved and spread back unchanged.
// This replaces the previous untyped `(couple as any).id` accesses without
// altering runtime behaviour.
export type CoupleRow = { id: number } & Record<string, unknown>;

// Narrow a DB couple row to the numeric primary key used by every couple query.
export function coupleId(couple: CoupleRow): number {
  return Number(couple.id);
}

// Membership guard for `/api/couple/:coupleId/*` routes: a user may only act on
// the (single, active) couple they belong to. Verbatim from src/index.ts.
export async function assertCoupleMembership(
  userId: number,
  coupleId: number,
): Promise<boolean> {
  if (Number.isNaN(coupleId)) return false;
  const couple = await getCouple(userId);
  if (!couple) return false;
  const ownedId = Number((couple as { id: number }).id);
  return ownedId === coupleId;
}

// POST /api/couple/request body — only `target_user_id` is read.
export const coupleRequestBodySchema = z
  .object({
    target_user_id: z.number(),
  })
  .passthrough();

// PUT /api/couple/request/:id body — accept / reject a pending request.
export const coupleRespondBodySchema = z
  .object({
    action: z.enum(["accept", "reject"]),
  })
  .passthrough();

// What a client is told when something unexpected fails: the cause is logged
// on the server, never sent (it can name tables, columns or internals).
export const GENERIC_SERVER_ERROR = "Internal server error";

// Longest farewell message posted into an archived conversation.
export const ARCHIVE_MESSAGE_MAX_LENGTH = 500;

// POST /api/couple/archive-conversations body. The partner is optional: the
// server always keeps the couple's own partner, and refuses any other one.
export const archiveConversationsBodySchema = z
  .object({
    partner_user_id: z.number().int().nullable().optional(),
    message: z.string().max(ARCHIVE_MESSAGE_MAX_LENGTH).nullable().optional(),
  })
  .passthrough();

// Largest value of a Postgres INTEGER column: anything above is never a real id.
const POSTGRES_INTEGER_MAX = 2_147_483_647;

// A route id (`/events/:id`...) as a positive integer, or null when it is not one.
export function parseRouteId(raw: string | undefined): number | null {
  if (raw === undefined || !/^\d+$/.test(raw)) return null;
  const id = Number(raw);
  return id >= 1 && id <= POSTGRES_INTEGER_MAX ? id : null;
}

const idSchema = z.number().int().min(1).max(POSTGRES_INTEGER_MAX);

// A real calendar day written YYYY-MM-DD (a trailing time is tolerated and
// dropped, so an ISO timestamp from a client still works). 2024-02-31 is refused.
export const calendarDateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}(?:[T ].*)?$/, "must be a date (YYYY-MM-DD)")
  .refine((value) => {
    const [year, month, day] = value.slice(0, 10).split("-").map(Number);
    if (year === undefined || month === undefined || day === undefined) return false;
    const parsed = new Date(Date.UTC(year, month - 1, day));
    return parsed.getUTCFullYear() === year && parsed.getUTCMonth() === month - 1 && parsed.getUTCDate() === day;
  }, "must be a real calendar date")
  .transform((value) => value.slice(0, 10));

// POST /api/couple/bookings body.
export const bookingBodySchema = z
  .object({
    activityId: idSchema.nullable().optional(),
    eventId: idSchema.nullable().optional(),
    bookingDate: calendarDateSchema,
    bookingTime: z
      .string()
      .regex(/^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/, "must be a time (HH:MM)")
      .nullable()
      .optional(),
    notes: z.string().max(1000).nullable().optional(),
  })
  .passthrough()
  .refine((body) => body.activityId != null || body.eventId != null, {
    message: "activityId or eventId is required",
  });

// PATCH /api/couple/:coupleId/status body.
export const RELATIONSHIP_STATUSES = ["dating", "in_relationship", "engaged", "married"] as const;
export const relationshipStatusBodySchema = z
  .object({ relationshipStatus: z.enum(RELATIONSHIP_STATUSES) })
  .passthrough();

// POST /api/couple/:coupleId/question/:questionId/answer body.
export const dailyAnswerBodySchema = z
  .object({ answer: z.string().trim().min(1).max(2000) })
  .passthrough();

// A picture link: https only (javascript:, data:, http: and relative links are refused).
const httpsUrlSchema = z
  .string()
  .max(2048)
  .refine((value) => {
    try {
      const url = new URL(value);
      return url.protocol === "https:" && url.hostname.length > 0;
    } catch {
      return false;
    }
  }, "must be an https url");

// POST /api/couple/memories body. `type` is stored in a VARCHAR(20).
export const memoryBodySchema = z
  .object({
    type: z.string().min(1).max(20).regex(/^[a-z_]+$/i, "must be letters and underscores"),
    title: z.string().max(255).nullable().optional(),
    content: z.string().max(5000).nullable().optional(),
    imageUrl: httpsUrlSchema.nullable().optional(),
    memoryDate: calendarDateSchema.nullable().optional(),
    location: z.string().max(255).nullable().optional(),
  })
  .passthrough();

// POST /api/couple/dates body.
export const dateBodySchema = z
  .object({
    title: z.string().trim().min(1).max(255),
    date: calendarDateSchema,
    type: z.string().trim().min(1).max(50),
    isRecurring: z.boolean().nullable().optional(),
    remindDaysBefore: z.number().int().min(0).max(365).nullable().optional(),
    notes: z.string().max(2000).nullable().optional(),
  })
  .passthrough();

// PUT /api/couple/dates/:id body: every field optional, unknown ones dropped.
export const dateUpdateBodySchema = z.object({
  title: z.string().trim().min(1).max(255).optional(),
  date: calendarDateSchema.optional(),
  notes: z.string().max(2000).optional(),
  remindDaysBefore: z.number().int().min(0).max(365).optional(),
});

// POST /api/couple/bucket-list body.
export const bucketItemBodySchema = z
  .object({
    title: z.string().trim().min(1).max(255),
    description: z.string().max(2000).nullable().optional(),
    category: z.string().max(50).nullable().optional(),
    targetDate: calendarDateSchema.nullable().optional(),
  })
  .passthrough();

// POST /api/couple/activities/:id/save body (an empty body is fine).
export const saveActivityBodySchema = z
  .object({ notes: z.string().max(1000).nullable().optional() })
  .passthrough();

const PAGE_SIZE_DEFAULT = 20;
const PAGE_SIZE_MAX = 100;
const PAGE_OFFSET_MAX = 100_000;

// `limit` (1..100, default 20) and `offset` (>= 0, default 0) of a list route,
// or null when one of them is not a plain integer in range.
export function parsePagination(
  limit: string | undefined,
  offset: string | undefined,
): { limit: number; offset: number } | null {
  const parsedLimit = limit === undefined || limit === "" ? PAGE_SIZE_DEFAULT : /^\d+$/.test(limit) ? Number(limit) : NaN;
  const parsedOffset = offset === undefined || offset === "" ? 0 : /^\d+$/.test(offset) ? Number(offset) : NaN;
  if (!(parsedLimit >= 1 && parsedLimit <= PAGE_SIZE_MAX)) return null;
  if (!(parsedOffset >= 0 && parsedOffset <= PAGE_OFFSET_MAX)) return null;
  return { limit: parsedLimit, offset: parsedOffset };
}
