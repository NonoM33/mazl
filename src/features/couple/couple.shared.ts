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
