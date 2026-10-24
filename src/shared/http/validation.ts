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

// Shared across features (matching): POST /api/swipes body.
export const swipeBodySchema = z
  .object({
    target_user_id: idSchema,
    action: z.enum(["like", "pass", "super_like"]),
  })
  .passthrough();

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

// ============ PROFILE BODY ============

export const MIN_MEMBER_AGE = 18;
const MAX_MEMBER_AGE = 120;
const MAX_PREFERRED_AGE = 99;

// Age in whole years on `now` (UTC) for a YYYY-MM-DD string, or null when the
// string is not a real calendar date ("2000-02-31" is not one).
export function ageFromIsoDate(iso: string, now: Date = new Date()): number | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
  if (!match) return null;
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const date = new Date(Date.UTC(year, month - 1, day));
  const isReal = date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
  if (!isReal) return null;
  const birthdayPassed =
    now.getUTCMonth() > month - 1 || (now.getUTCMonth() === month - 1 && now.getUTCDate() >= day);
  return now.getUTCFullYear() - year - (birthdayPassed ? 0 : 1);
}

const birthdateSchema = z.string().superRefine((value, ctx) => {
  const age = ageFromIsoDate(value);
  if (age === null) {
    ctx.addIssue({ code: "custom", message: "must be a valid YYYY-MM-DD date" });
  } else if (age < MIN_MEMBER_AGE || age > MAX_MEMBER_AGE) {
    ctx.addIssue({ code: "custom", message: `members must be between ${MIN_MEMBER_AGE} and ${MAX_MEMBER_AGE} years old` });
  }
});

// The app sends an explicit null for a field the member never filled in: it
// means "leave it alone", exactly like an absent field.
const optional = <T extends z.ZodType>(schema: T) => schema.nullish().transform((value) => value ?? undefined);

const preferredAge = z.number().int().min(MIN_MEMBER_AGE).max(MAX_PREFERRED_AGE);

// PUT /api/profile. Values mirror what the mobile app really sends (gender and
// lookingFor are 'male' | 'female'; the denomination, kashrut and shabbat
// labels are French texts that the app and its filters may extend, so they are
// only capped at their 50-character column). Extra fields stay tolerated.
export const updateProfileBodySchema = z
  .object({
    displayName: optional(z.string().max(50)),
    birthdate: optional(birthdateSchema),
    gender: optional(z.enum(["male", "female"])),
    bio: optional(z.string().max(1000)),
    location: optional(z.string().max(100)),
    latitude: optional(z.number().min(-90).max(90)),
    longitude: optional(z.number().min(-180).max(180)),
    denomination: optional(z.string().max(50)),
    kashrutLevel: optional(z.string().max(50)),
    shabbatObservance: optional(z.string().max(50)),
    lookingFor: optional(z.enum(["male", "female", "all"])),
    ageMin: optional(preferredAge),
    ageMax: optional(preferredAge),
    distanceMax: optional(z.number()),
  })
  .passthrough()
  .refine((body) => body.ageMin === undefined || body.ageMax === undefined || body.ageMin <= body.ageMax, {
    message: "ageMin must not exceed ageMax",
    path: ["ageMin"],
  });

// ============ PROMPTS BODY ============

export const MAX_PROMPT_ANSWER = 300;

const promptAnswer = z.string().trim().min(1).max(MAX_PROMPT_ANSWER);

export const addPromptBodySchema = z
  .object({
    prompt_id: z.string().min(1).max(50),
    answer: promptAnswer,
    // The app sends the 1-based rank of the new prompt (1 to 3).
    position: z.number().int().min(0).max(9).optional(),
  })
  .passthrough();

export const updatePromptBodySchema = z.object({ answer: promptAnswer }).passthrough();
