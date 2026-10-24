import type { Hono, MiddlewareHandler } from "hono";
import { createMiddleware } from "hono/factory";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import type { LikeAllowanceService } from "../application/like-allowance-service";

type Authenticate = MiddlewareHandler<{ Variables: AppVariables }>;

export interface LikeAllowanceDeps {
  readonly authenticate: Authenticate;
  readonly allowance: Pick<LikeAllowanceService, "allowance" | "checkLike">;
}

// Beyond this the id cannot exist and the query would fail: the swipe handler answers 400.
const POSTGRES_INT_MAX = 2_147_483_647;

// Only what the guard needs from the swipe body; anything else is the handler's business.
const likeBodySchema = z.object({ action: z.literal("like"), target_user_id: z.number().int().positive().max(POSTGRES_INT_MAX) });

// Hono caches the parsed body, so the swipe handler that runs next reads it again.
async function readLike(c: { req: { json: () => Promise<unknown> } }): Promise<z.infer<typeof likeBodySchema> | undefined> {
  try {
    const parsed = likeBodySchema.safeParse(await c.req.json());
    return parsed.success ? parsed.data : undefined;
  } catch {
    return undefined;
  }
}

export function createLikeAllowanceGuard(deps: LikeAllowanceDeps): MiddlewareHandler<{ Variables: AppVariables }> {
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const like = await readLike(c);
    if (like === undefined) return await next();
    try {
      const verdict = await deps.allowance.checkLike(c.get("userId"), like.target_user_id);
      if (!verdict.allowed) return c.json({ success: false, error: "likes_exhausted", allowance: verdict.allowance }, 402);
    } catch (error: unknown) {
      console.error("Like allowance failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "internal_error" }, 500);
    }
    await next();
  });
}

export function registerLikeAllowanceRoutes(app: Hono<{ Variables: AppVariables }>, deps: LikeAllowanceDeps): void {
  app.get("/api/likes/allowance", deps.authenticate, async (c) => {
    try {
      return c.json({ success: true, allowance: await deps.allowance.allowance(c.get("userId")) });
    } catch (error: unknown) {
      console.error("Like allowance failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "internal_error" }, 500);
    }
  });

  // Registered before the matching routes: after the guard calls next(), the
  // matching handler of the same path answers. Authentication runs first because
  // the guard needs the member; matching's own requireAuth then runs again.
  app.post("/api/swipes", deps.authenticate, createLikeAllowanceGuard(deps));
}
