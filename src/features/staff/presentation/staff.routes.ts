import type { Context, Env, Hono, MiddlewareHandler } from "hono";
import { Hono as HonoApp } from "hono";
import type { ZodType } from "zod";
import { clientIp } from "../../../shared/http/client-ip";
import { createIpRateLimiter, tooManyRequests } from "../../../shared/http/rate-limit";
import { currentStaff, type RequirePermission, type StaffVariables } from "../application/ports";
import type { LoginOutcome } from "../application/staff-auth";
import type { StaffAuth } from "../application/staff-auth";
import type { StaffDirectory } from "../application/staff-directory";
import type { StaffMfa } from "../application/staff-mfa";
import type { LoginResultDto, MfaConfirmedDto, MfaEnrollmentDto } from "./dto";
import { toMeDto, toStaffMemberDto } from "./mappers";
import {
  createStaffSchema,
  googleLoginSchema,
  mfaConfirmSchema,
  mfaLoginSchema,
  passwordLoginSchema,
  updateStaffSchema,
} from "./staff.schemas";

export interface StaffRouteDeps {
  readonly auth: StaffAuth;
  readonly mfa: StaffMfa;
  readonly directory: StaffDirectory;
  readonly requirePermission: RequirePermission;
  // Authenticated member, no permission and no second-factor requirement.
  readonly authenticate: MiddlewareHandler<{ Variables: StaffVariables }>;
  readonly mfaRequired: boolean;
}

type StaffContext = Context<{ Variables: StaffVariables }>;

const fail = (c: StaffContext, status: 400 | 401 | 403 | 404 | 409 | 500 | 503, error: string, message?: string): Response =>
  c.json({ success: false, error, ...(message === undefined ? {} : { message }) }, status);

async function readBody<T>(c: StaffContext, schema: ZodType<T>): Promise<T | null> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return null;
  }
  const parsed = schema.safeParse(raw);
  return parsed.success ? parsed.data : null;
}

const invalid = (c: StaffContext): Response => fail(c, 400, "invalid_request", "Requête invalide.");

export function registerStaffRoutes<E extends Env>(app: Hono<E>, deps: StaffRouteDeps): void {
  const router = new HonoApp<{ Variables: StaffVariables }>();
  const { auth, mfa, directory, mfaRequired } = deps;
  const signInLimiter = createIpRateLimiter({ max: 20, windowMs: 15 * 60_000 });
  const manage = deps.requirePermission("staff.manage");

  router.onError((error, c) => {
    console.error("Staff request failed:", error instanceof Error ? error.name : "unknown");
    return c.json({ success: false, error: "internal_error" }, 500);
  });

  async function loginResponse(c: StaffContext, outcome: LoginOutcome): Promise<Response> {
    if (!outcome.ok) {
      switch (outcome.reason) {
        case "locked":
          return tooManyRequests(c, outcome.retryAfter);
        case "not_configured":
          return fail(c, 503, "not_configured", "Configuration serveur manquante.");
        case "not_staff":
          return fail(c, 403, "not_staff", "Ce compte n'appartient pas au staff.");
        case "invalid_google_token":
          return fail(c, 401, "invalid_google_token", "Identité Google invalide.");
        case "invalid_credentials":
          return fail(c, 401, "invalid_credentials", "E-mail ou mot de passe incorrect.");
      }
    }
    if (outcome.kind === "mfa_challenge") {
      const data: LoginResultDto = { kind: "mfa_challenge", challenge: outcome.challenge };
      return c.json({ success: true, data });
    }
    const data: LoginResultDto = { kind: "session", token: outcome.token, me: toMeDto(outcome.staff, false, mfaRequired) };
    return c.json({ success: true, data });
  }

  router.post("/api/backoffice/auth/password", async (c) => {
    const body = await readBody(c, passwordLoginSchema);
    if (!body) return invalid(c);
    return loginResponse(c, await auth.loginWithPassword(body.email, body.password, clientIp(c)));
  });

  router.post("/api/backoffice/auth/google", signInLimiter, async (c) => {
    const body = await readBody(c, googleLoginSchema);
    if (!body) return invalid(c);
    return loginResponse(c, await auth.loginWithGoogle(body.credential));
  });

  router.post("/api/backoffice/auth/mfa", signInLimiter, async (c) => {
    const body = await readBody(c, mfaLoginSchema);
    if (!body) return invalid(c);
    const outcome = await auth.loginWithMfa(body.challenge, body.code);
    if (!outcome.ok) {
      if (outcome.reason === "locked") return tooManyRequests(c, outcome.retryAfter);
      return outcome.reason === "invalid_code"
        ? fail(c, 401, "invalid_code", "Code incorrect.")
        : fail(c, 401, "invalid_challenge", "Défi expiré ou invalide, reconnectez-vous.");
    }
    const data: LoginResultDto = { kind: "session", token: outcome.token, me: toMeDto(outcome.staff, true, mfaRequired) };
    return c.json({ success: true, data });
  });

  router.get("/api/backoffice/me", deps.authenticate, async (c) => {
    const principal = currentStaff(c);
    const staff = await directory.resolve(principal.email);
    if (!staff) return fail(c, 401, "unauthorized", "Connexion requise.");
    return c.json({ success: true, data: toMeDto(staff, principal.mfa, mfaRequired) });
  });

  router.post("/api/backoffice/mfa/enroll", deps.authenticate, async (c) => {
    const staff = await directory.resolve(currentStaff(c).email);
    if (!staff) return fail(c, 401, "unauthorized", "Connexion requise.");
    const result = await mfa.enroll(staff);
    if (!result.ok) return fail(c, 409, "already_enrolled", "Un second facteur est déjà configuré.");
    const data: MfaEnrollmentDto = { secret: result.secret, otpauthUri: result.otpauthUri };
    return c.json({ success: true, data });
  });

  router.post("/api/backoffice/mfa/confirm", deps.authenticate, async (c) => {
    const body = await readBody(c, mfaConfirmSchema);
    if (!body) return invalid(c);
    const staff = await directory.resolve(currentStaff(c).email);
    if (!staff) return fail(c, 401, "unauthorized", "Connexion requise.");
    const result = await mfa.confirm(staff, body.code);
    if (!result.ok) {
      if (result.reason === "locked") return tooManyRequests(c, result.retryAfter ?? 1);
      return result.reason === "invalid_code"
        ? fail(c, 401, "invalid_code", "Code incorrect.")
        : fail(c, 409, "no_enrollment", "Aucun enrôlement en cours.");
    }
    const data: MfaConfirmedDto = { token: auth.sessionFor(result.staff, true), me: toMeDto(result.staff, true, mfaRequired) };
    return c.json({ success: true, data });
  });

  router.get("/api/backoffice/staff", manage, async (c) => {
    const members = await directory.list();
    return c.json({ success: true, data: members.map(toStaffMemberDto) });
  });

  router.post("/api/backoffice/staff", manage, async (c) => {
    const body = await readBody(c, createStaffSchema);
    if (!body) return invalid(c);
    const result = await directory.create(currentStaff(c).email, body);
    if (!result.ok) {
      return result.reason === "environment_member"
        ? fail(c, 409, "environment_member", "Cette adresse vient de l'environnement et n'est pas modifiable.")
        : fail(c, 409, "already_exists", "Ce membre existe déjà.");
    }
    return c.json({ success: true, data: toStaffMemberDto(result.member) }, 201);
  });

  router.patch("/api/backoffice/staff/:email", manage, async (c) => {
    const body = await readBody(c, updateStaffSchema);
    if (!body) return invalid(c);
    const patch = { ...(body.role === undefined ? {} : { role: body.role }), ...(body.active === undefined ? {} : { active: body.active }) };
    const result = await directory.update(currentStaff(c).email, c.req.param("email"), patch);
    if (!result.ok) {
      switch (result.reason) {
        case "environment_member":
          return fail(c, 409, "environment_member", "Cette adresse vient de l'environnement et n'est pas modifiable.");
        case "self_lockout":
          return fail(c, 409, "self_lockout", "Vous ne pouvez pas vous retirer la gestion du staff.");
        case "not_found":
          return fail(c, 404, "not_found", "Membre introuvable.");
      }
    }
    return c.json({ success: true, data: toStaffMemberDto(result.member) });
  });

  app.route("/", router);
}
