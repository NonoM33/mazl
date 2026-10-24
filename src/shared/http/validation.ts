import type { Context } from "hono";
import { z } from "zod";
import type { AppVariables } from "./middleware";

// ============ INPUT VALIDATION (permissive safety net) ============
// Shared request-body validation helper and the zod schemas reused across
// features. `parseBody` guards only the TYPES of fields actually read by each
// handler; schemas use `.passthrough()` so extra fields from the mobile app are
// never rejected. On failure the caller returns the same
// `{ success: false, error }` 400 shape as the rest of the API.

type BodyParseResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };

export async function parseBody<T>(
  schema: z.ZodType<T>,
  c: Context<{ Variables: AppVariables }>,
): Promise<BodyParseResult<T>> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return { ok: false, error: "Invalid JSON body" };
  }
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    const path = first?.path.join(".");
    const message = first
      ? path
        ? `${path}: ${first.message}`
        : first.message
      : "Invalid request body";
    return { ok: false, error: message };
  }
  return { ok: true, data: parsed.data };
}

// Shared across features (matching): POST /api/swipes body.
export const swipeBodySchema = z
  .object({
    target_user_id: z.number(),
    action: z.enum(["like", "pass", "super_like"]),
  })
  .passthrough();

// ============ SECURITY HARDENING ============

// Largest value of a Postgres INTEGER key: a bigger id cannot exist, and handing
// it to a query would raise a 500 instead of an honest "not found".
const MAX_ID = 2_147_483_647;

// A path or body identifier: digits only, positive, fitting an INTEGER key.
// "12abc", "1e3", "-4", "0" and "3000000000" are all refused.
export function parseId(raw: string): number | null {
  if (!/^\d{1,10}$/.test(raw)) return null;
  const id = Number(raw);
  return id >= 1 && id <= MAX_ID ? id : null;
}

export const idSchema = z.number().int().min(1).max(MAX_ID);

// limit/offset of the listing routes: out-of-range or unreadable values fall
// back to the default (or the bound), they never reach the query.
export function parsePage(
  rawLimit: string | undefined,
  rawOffset: string | undefined,
  options: { defaultLimit: number; maxLimit: number },
): { limit: number; offset: number } {
  const limit = Number(rawLimit);
  const offset = Number(rawOffset);
  return {
    limit: Number.isInteger(limit) && limit >= 1 ? Math.min(limit, options.maxLimit) : options.defaultLimit,
    offset: Number.isInteger(offset) && offset >= 0 && offset <= MAX_ID ? offset : 0,
  };
}
