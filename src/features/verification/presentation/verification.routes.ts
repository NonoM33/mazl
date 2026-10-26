import type { Hono } from "hono";
import { deleteFaceReference, type DeleteFaceReferenceDeps } from "../application/face-reference";
import { getVerificationStatus, type FaceStatusDeps } from "../application/face-status";
import { startFaceSession, type StartSessionDeps } from "../application/start-session";
import { submitFaceVerification, type SubmitFaceDeps } from "../application/submit-face";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { parseBody } from "../../../shared/http/validation";
import { MAX_BODY_BYTES, parseFaceSubmission, readMultipartCapped, sessionRequestSchema } from "./face-request";
import { registerLegacyVerificationRoutes } from "./legacy-routes";
import { captureDiagnosticsLine, captureDiagnosticsSchema } from "./capture-diagnostics";

export interface VerificationRouteDeps {
  readonly session: StartSessionDeps;
  readonly submit: SubmitFaceDeps;
  readonly status: FaceStatusDeps;
  readonly reference: DeleteFaceReferenceDeps;
}

type App = Hono<{ Variables: AppVariables }>;

const iso = (d: Date | null): string | null => (d ? d.toISOString() : null);

// Errors are logged by class only: never an image, an embedding or a score.
function logFailure(where: string, error: unknown): void {
  console.error(`Face verification ${where} failed:`, error instanceof Error ? error.name : "unknown");
}

// Literal /api/verification/* paths: registered before any parameterised
// route that could capture them.
export function registerVerificationRoutes(app: App, deps: VerificationRouteDeps): void {
  // POST /api/verification/face/diagnostics: counts the app measured while a
  // selfie check did not complete (no image), logged to find device issues.
  app.post("/api/verification/face/diagnostics", requireAuth, async (c) => {
    const body = await parseBody(captureDiagnosticsSchema, c);
    if (!body.ok) return c.json({ success: false, error: body.error }, 400);
    console.log(captureDiagnosticsLine(c.get("userId"), body.data));
    return c.json({ success: true });
  });

  app.post("/api/verification/face/session", requireAuth, async (c) => {
    const body = await parseBody(sessionRequestSchema, c);
    if (!body.ok) return c.json({ success: false, error: body.error }, 400);
    try {
      const result = await startFaceSession(deps.session, c.get("userId"), body.data.purpose);
      if (!result.ok) {
        return c.json(
          { success: false, error: result.reason, next_attempt_time: result.nextAttemptTime.toISOString() },
          429,
        );
      }
      return c.json({
        success: true,
        session_id: result.sessionId,
        challenges: result.challenges,
        expires_at: result.expiresAt.toISOString(),
      });
    } catch (error: unknown) {
      logFailure("session", error);
      return c.json({ success: false, error: "Failed to start verification" }, 500);
    }
  });

  app.post("/api/verification/face/submit", requireAuth, async (c) => {
    if (!(c.req.header("Content-Type") ?? "").toLowerCase().startsWith("multipart/form-data")) {
      return c.json({ success: false, error: "multipart/form-data required" }, 400);
    }
    const declared = Number(c.req.header("Content-Length") ?? "0");
    if (declared > MAX_BODY_BYTES) return c.json({ success: false, error: "payload_too_large" }, 413);

    const form = await readMultipartCapped(c.req.raw, MAX_BODY_BYTES);
    if (form === "too_large") return c.json({ success: false, error: "payload_too_large" }, 413);
    if (form === "malformed") return c.json({ success: false, error: "Malformed multipart body" }, 400);
    const parsed = await parseFaceSubmission(form);
    if (!parsed.ok) return c.json({ success: false, error: parsed.error }, parsed.status);

    try {
      const result = await submitFaceVerification(deps.submit, {
        userId: c.get("userId"),
        sessionId: parsed.sessionId,
        frames: parsed.frames,
      });
      if (!result.verified) return c.json({ success: true, verified: false, reason: result.reason });
      return c.json({
        success: true,
        verified: true,
        photo_matches: result.photoMatches.map((m) => ({ photo_id: m.photoId, match: m.match })),
      });
    } catch (error: unknown) {
      logFailure("submit", error);
      return c.json({ success: false, error: "Failed to verify" }, 500);
    }
  });

  app.delete("/api/verification/face/reference", requireAuth, async (c) => {
    try {
      await deleteFaceReference(deps.reference, c.get("userId"));
      return c.json({ success: true });
    } catch (error: unknown) {
      logFailure("reference deletion", error);
      return c.json({ success: false, error: "Failed to delete the face reference" }, 500);
    }
  });

  app.get("/api/verification/status", requireAuth, async (c) => {
    try {
      const s = await getVerificationStatus(deps.status, c.get("userId"));
      return c.json({
        success: true,
        photo: { verified: s.photo.verified, verified_at: iso(s.photo.verifiedAt), attempts_today: s.photo.attemptsToday },
        identity: {
          verified: s.identity.verified,
          verified_at: iso(s.identity.verifiedAt),
          attempts_today: s.identity.attemptsToday,
        },
        level: s.level,
        is_verified: s.isVerified,
        attempts_today: s.attemptsToday,
        next_attempt_time: iso(s.nextAttemptTime),
      });
    } catch (error: unknown) {
      logFailure("status", error);
      return c.json({ success: false, error: "Failed to get verification status" }, 500);
    }
  });

  registerLegacyVerificationRoutes(app);
}
