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
