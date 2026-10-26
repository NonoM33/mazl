import type { Context, Hono, MiddlewareHandler } from "hono";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import type { ConsentService } from "../application/consent-service";
import type { ExportService } from "../application/export-service";
import { ConsentVersionOutdatedError, isConsentPurpose } from "../domain/consent";

type Authenticated = Context<{ Variables: AppVariables }>;

export interface PrivacyRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  // Per member, applied after authenticate (3 exports a day).
  readonly exportLimiter: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly consents: Pick<ConsentService, "list" | "decide">;
  readonly exports: Pick<ExportService, "export">;
}

const decisionSchema = z.object({
  granted: z.boolean(),
  version: z.string().min(1).max(20),
  source: z.enum(["web", "app"]),
});

async function readJson(c: Authenticated): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return undefined;
  }
}

function failure(c: Authenticated, error: unknown): Response {
  if (error instanceof ConsentVersionOutdatedError) {
    return c.json({ success: false, error: "consent_version_outdated", current_version: error.currentVersion }, 409);
  }
  console.error("Privacy request failed:", error instanceof Error ? error.name : "unknown");
  return c.json({ success: false, error: "internal_error" }, 500);
}

export function registerPrivacyRoutes(app: Hono<{ Variables: AppVariables }>, deps: PrivacyRouteDeps): void {
  app.get("/api/privacy/consents", deps.authenticate, async (c) => {
    try {
      return c.json({ success: true, consents: await deps.consents.list(c.get("userId")) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  // One route per purpose: religious_data (art. 9) and analytics.
  app.put("/api/privacy/consents/:purpose", deps.authenticate, async (c) => {
    const purpose = c.req.param("purpose");
    if (!isConsentPurpose(purpose)) return c.json({ success: false, error: "unknown_purpose" }, 404);
    const body = decisionSchema.safeParse(await readJson(c));
    if (!body.success) return c.json({ success: false, error: "invalid_body" }, 400);
    try {
      const stored = await deps.consents.decide(c.get("userId"), purpose, body.data);
      return c.json({
        success: true,
        consent: { granted: stored.granted, version: stored.version, decided_at: stored.decidedAt.toISOString() },
      });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.get("/api/users/me/export", deps.authenticate, deps.exportLimiter, async (c) => {
    try {
      const file = await deps.exports.export(c.get("userId"));
      c.header("Content-Disposition", `attachment; filename="${file.filename}"`);
      c.header("Cache-Control", "no-store");
      return c.body(JSON.stringify(file.document, null, 2), 200, { "Content-Type": "application/json; charset=utf-8" });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });
}
