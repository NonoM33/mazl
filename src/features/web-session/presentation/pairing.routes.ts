import type { Context, Hono, MiddlewareHandler } from "hono";
import { createMiddleware } from "hono/factory";
import { extractBearerToken, verifyJWT } from "../../../auth";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import type { WebSessionModule } from "../web-session.module";
import { SESSION_HEADER } from "./cookie";
import { scanBody } from "./schemas";

type Ctx = Context<{ Variables: AppVariables }>;

// Approving a sign-in is the phone's job: a web session must never do it,
// otherwise a hijacked browser could sign in more browsers. Only the app's
// tokens pass: any token with an audience (the web bridge's) is refused,
// whatever headers came with it (security review H1).
export const refuseWebSession: MiddlewareHandler<{ Variables: AppVariables }> = createMiddleware(async (c, next) => {
  const token = extractBearerToken(c.req.header("Authorization"));
  const payload = token ? verifyJWT(token) : null;
  if (c.req.header(SESSION_HEADER) || !payload || payload.aud !== undefined) {
    return c.json({ success: false, error: "web_session_forbidden" }, 403);
  }
  await next();
});

export function registerPairingRoutes(app: Hono<{ Variables: AppVariables }>, module: WebSessionModule): void {
  const scanLimit = createRateLimiter({ max: 10, windowMs: 10 * 60_000 });

  app.post("/api/web/pairings/scan", requireAuth, refuseWebSession, scanLimit, async (c) => {
    const parsed = scanBody.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) return c.json({ success: false, error: "invalid_body" }, 400);
    const pairing = await module.pairings.scan(c.get("userId"), parsed.data.code);
    if (!pairing) return c.json({ success: false, error: "pairing_not_found" }, 404);
    return c.json({
      success: true,
      pairing: {
        id: pairing.id,
        browser: pairing.browserLabel,
        created_at: pairing.createdAt.toISOString(),
        expires_at: pairing.expiresAt.toISOString(),
      },
    });
  });

  const decide = (status: "approved" | "denied") => async (c: Ctx): Promise<Response> => {
    const outcome = await module.pairings.decide(c.get("userId"), c.req.param("id") ?? "", status);
    if (outcome === "not_found") return c.json({ success: false, error: "pairing_not_found" }, 404);
    if (outcome === "not_pending") return c.json({ success: false, error: "pairing_not_pending" }, 409);
    return c.json({ success: true });
  };
  app.post("/api/web/pairings/:id/approve", requireAuth, refuseWebSession, decide("approved"));
  app.post("/api/web/pairings/:id/deny", requireAuth, refuseWebSession, decide("denied"));
}
