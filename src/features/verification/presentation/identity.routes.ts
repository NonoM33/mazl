import type { Hono } from "hono";
import { submitIdentityVerification, type SubmitIdentityDeps } from "../application/submit-identity";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { readMultipartCapped } from "./face-request";
import { MAX_IDENTITY_BODY_BYTES, parseIdentitySubmission } from "./identity-request";

type App = Hono<{ Variables: AppVariables }>;

// POST /api/verification/identity (CONTRAT.md §4). The body holds a face and
// identity data: nothing of it is ever logged, only the error class.
export function registerIdentityRoutes(app: App, deps: SubmitIdentityDeps): void {
  app.post("/api/verification/identity", requireAuth, async (c) => {
    if (!(c.req.header("Content-Type") ?? "").toLowerCase().startsWith("multipart/form-data")) {
      return c.json({ success: false, error: "multipart/form-data required" }, 400);
    }
    if (Number(c.req.header("Content-Length") ?? "0") > MAX_IDENTITY_BODY_BYTES) {
      return c.json({ success: false, error: "payload_too_large" }, 413);
    }
    const form = await readMultipartCapped(c.req.raw, MAX_IDENTITY_BODY_BYTES);
    if (form === "too_large") return c.json({ success: false, error: "payload_too_large" }, 413);
    if (form === "malformed") return c.json({ success: false, error: "Malformed multipart body" }, 400);
    const parsed = await parseIdentitySubmission(form);
    if (!parsed.ok) return c.json({ success: false, error: parsed.error }, parsed.status);

    try {
      const result = await submitIdentityVerification(deps, {
        userId: c.get("userId"),
        sessionId: parsed.sessionId,
        frames: parsed.frames,
        chip: parsed.chip,
      });
      // The outcome only: never a document field, a face or a score.
      console.log(`Identity verification user ${c.get("userId")}: ${result.verified ? "verified" : `refused (${result.reason})`}`);
      if (!result.verified) return c.json({ success: true, verified: false, reason: result.reason });
      return c.json({ success: true, verified: true });
    } catch (error: unknown) {
      console.error("Identity verification failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "Failed to verify" }, 500);
    } finally {
      parsed.chip.dg1.fill(0);
      parsed.chip.dg2.fill(0);
      parsed.chip.sod.fill(0);
    }
  });
}
