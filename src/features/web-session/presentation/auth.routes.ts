import type { Context, Hono } from "hono";
import type { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import { createIpRateLimiter } from "../../../shared/http/rate-limit";
import { browserLabel } from "../domain/browser-label";
import { remainingSeconds } from "../domain/session";
import type { OpenedSession, WebMember } from "../application/ports";
import type { WebSessionModule } from "../web-session.module";
import { SESSION_HEADER, clearedCookie, sessionCookie } from "./cookie";
import { hostAllowed, originAllowed } from "./origin";
import { appleBody, googleBody, qrBody } from "./schemas";

type Ctx = Context<{ Variables: AppVariables }>;

const fail = (c: Ctx, error: string, status: 400 | 401 | 403 | 404 | 503) => c.json({ success: false, error }, status);

async function readBody<S extends z.ZodType>(c: Ctx, schema: S): Promise<z.infer<S> | null> {
  const raw: unknown = await c.req.json().catch(() => null);
  const parsed = schema.safeParse(raw);
  return parsed.success ? parsed.data : null;
}

function setCookie(c: Ctx, module: WebSessionModule, opened: OpenedSession): void {
  c.header("Set-Cookie", sessionCookie(opened.token, remainingSeconds(opened.session, module.now())));
  c.header("Cache-Control", "no-store");
}

const userView = (member: WebMember) => ({ id: member.id, name: member.name });

export function registerAuthRoutes(app: Hono<{ Variables: AppVariables }>, module: WebSessionModule): void {
  const challengeLimit = createIpRateLimiter({ max: 60, windowMs: 15 * 60_000 });
  const qrLimit = createIpRateLimiter({ max: 30, windowMs: 15 * 60_000 });
  const googleLimit = createIpRateLimiter({ max: 30, windowMs: 15 * 60_000 });
  const appleLimit = createIpRateLimiter({ max: 30, windowMs: 15 * 60_000 });
  const pollLimit = createIpRateLimiter({ max: 120, windowMs: 60_000 });
  const rightHost = (c: Ctx): boolean => hostAllowed(module.config, c.req.header("host") ?? null);
  const label = (c: Ctx): string => browserLabel(c.req.header("user-agent"));

  // Sign-in cannot be forged from another site (security review M1): a form of
  // another site can only send text/plain, urlencoded or multipart, so JSON is
  // required, and a request that names another origin is refused.
  app.use("/api/web/auth/*", async (c, next) => {
    if (c.req.method !== "POST") return next();
    const type = c.req.header("content-type") ?? "";
    if (!/^application\/json\s*(;|$)/i.test(type)) return c.json({ success: false, error: "json_required" }, 415);
    const origin = c.req.header("origin");
    if (origin !== undefined && !originAllowed(module.config, origin, c.req.header("host") ?? null)) return fail(c, "wrong_origin", 403);
    await next();
  });

  app.get("/api/web/auth/config", (c) =>
    c.json({
      success: true,
      google_client_id: module.config.googleClientId,
      apple_services_id: module.config.appleServicesId,
      pow_difficulty: module.pow.difficulty,
    }),
  );

  app.post("/api/web/auth/challenge", challengeLimit, (c) => {
    const issued = module.pow.issue();
    return c.json({
      success: true,
      challenge: issued.challenge,
      difficulty: issued.difficulty,
      expires_at: new Date(issued.expiresAt * 1000).toISOString(),
    });
  });

  app.post("/api/web/auth/qr", qrLimit, async (c) => {
    if (!rightHost(c)) return fail(c, "wrong_origin", 403);
    const body = await readBody(c, qrBody);
    if (!body) return fail(c, "invalid_body", 400);
    if (module.pow.verify(body.pow) !== null) return fail(c, "pow_invalid", 403);
    const created = await module.pairings.create(label(c));
    return c.json({
      success: true,
      pairing: {
        id: created.id,
        code: created.code,
        browser_secret: created.browserSecret,
        expires_at: created.expiresAt.toISOString(),
      },
    });
  });

  app.get("/api/web/auth/qr/:id", pollLimit, async (c) => {
    if (!rightHost(c)) return fail(c, "wrong_origin", 403);
    const outcome = await module.pairings.poll(c.req.param("id"), c.req.header("x-pairing-secret") ?? "");
    c.header("Cache-Control", "no-store");
    switch (outcome.kind) {
      case "not_found":
        return fail(c, "not_found", 404);
      case "account_disabled":
        return fail(c, "account_disabled", 403);
      case "status":
        return c.json({ success: true, status: outcome.status });
      case "signed_in": {
        setCookie(c, module, outcome.opened);
        return c.json({ success: true, status: "approved", user: userView(outcome.member) });
      }
    }
  });

  app.post("/api/web/auth/google", googleLimit, async (c) => {
    if (!rightHost(c)) return fail(c, "wrong_origin", 403);
    const body = await readBody(c, googleBody);
    if (!body) return fail(c, "invalid_body", 400);
    if (module.pow.verify(body.pow) !== null) return fail(c, "pow_invalid", 403);
    const identity = await module.identity.google(body.idToken);
    if (!identity) return fail(c, "invalid_token", 401);
    return signInExisting(c, module, "google", identity.sub, label(c));
  });

  app.post("/api/web/auth/apple", appleLimit, async (c) => {
    const audience = module.config.appleServicesId;
    if (audience === null) return fail(c, "apple_unavailable", 503);
    if (!rightHost(c)) return fail(c, "wrong_origin", 403);
    const body = await readBody(c, appleBody);
    if (!body) return fail(c, "invalid_body", 400);
    if (module.pow.verify(body.pow) !== null) return fail(c, "pow_invalid", 403);
    const identity = await module.identity.apple(body.identityToken, audience);
    if (!identity) return fail(c, "invalid_token", 401);
    return signInExisting(c, module, "apple", identity.sub, label(c));
  });

  app.post("/api/web/auth/logout", async (c) => {
    const sessionId = c.req.header(SESSION_HEADER);
    const live = sessionId ? await module.sessions.get(sessionId) : null;
    if (live) await module.sessions.revoke(live.member.id, live.session.id);
    c.header("Set-Cookie", clearedCookie());
    return c.json({ success: true });
  });
}

async function signInExisting(
  c: Ctx,
  module: WebSessionModule,
  provider: "google" | "apple",
  providerId: string,
  browser: string,
): Promise<Response> {
  const lookup = await module.members.findByProvider(provider, providerId);
  if (lookup.kind === "absent") return fail(c, "account_not_found", 404);
  if (lookup.kind === "disabled") return fail(c, "account_disabled", 403);
  const opened = await module.sessions.open(lookup.member, provider, browser);
  setCookie(c, module, opened);
  return c.json({ success: true, user: userView(lookup.member) });
}

