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
