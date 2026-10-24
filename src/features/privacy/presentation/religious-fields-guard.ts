import type { MiddlewareHandler } from "hono";
import { createMiddleware } from "hono/factory";
import type { AppVariables } from "../../../shared/http/middleware";

// Fields of PUT /api/profile that reveal religious practice (GDPR art. 9).
export const RELIGIOUS_PROFILE_FIELDS = ["denomination", "kashrutLevel", "shabbatObservance", "relationshipIntention"] as const;

export interface ReligiousConsent {
  allowsReligiousData(userId: number): Promise<boolean>;
}

const isRecord = (value: unknown): value is Record<string, unknown> => typeof value === "object" && value !== null && !Array.isArray(value);

// Without a valid consent the server does not store those fields (security
// review M4). They are dropped silently, not refused: the app has no consent
// screen in every version yet and its sign-up must keep working. Hono parses
// the cached body text again for every read, so the filtered body replaces
// that text and the profile route reads it without the fields.
export function createReligiousFieldsGuard(consent: ReligiousConsent): MiddlewareHandler<{ Variables: AppVariables }> {
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const body: unknown = await c.req.json().catch(() => undefined);
    if (isRecord(body) && RELIGIOUS_PROFILE_FIELDS.some((field) => field in body) && !(await consent.allowsReligiousData(c.get("userId")))) {
      const kept = Object.fromEntries(Object.entries(body).filter(([key]) => !(RELIGIOUS_PROFILE_FIELDS as readonly string[]).includes(key)));
      // The cache holds promises at run time although typed as plain values.
      const cache: Record<string, unknown> = c.req.bodyCache;
      cache.text = Promise.resolve(JSON.stringify(kept));
    }
    await next();
  });
}
