import type { Hono, MiddlewareHandler } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
import { INTERNAL_ERROR, INVALID_BODY, fail, logFailure, ok, readJson } from "../../../shared/http/envelope";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import type { PremiumSettingsService } from "../application/premium-settings-service";
import { PLUS_REQUIRED, incognitoBodySchema, passportBodySchema, readReceiptsBodySchema, settingsView } from "../domain/settings";

export interface PremiumSettingsRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly settings: PremiumSettingsService;
}

const WRITES_PER_HOUR = 60;
const HOUR_MS = 60 * 60 * 1000;

// GET /api/premium/settings, PUT /api/discover/passport, PUT /api/profile/incognito,
// PUT /api/profile/read-receipts. The server says what is in force; the app never
// keeps a mazl+ setting on its own.
export function registerPremiumSettingsRoutes(app: Hono<{ Variables: AppVariables }>, deps: PremiumSettingsRouteDeps): void {
  const writes = createRateLimiter({ max: WRITES_PER_HOUR, windowMs: HOUR_MS });
  const { authenticate, settings } = deps;

  app.get("/api/premium/settings", authenticate, async (c) => {
    try {
      return ok(c, settingsView(await settings.read(c.get("userId"))));
    } catch (error: unknown) {
      logFailure("Premium settings read failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });

  app.put("/api/discover/passport", authenticate, writes, async (c) => {
    try {
      const body = await readJson(c, passportBodySchema);
      if (!body.ok) return fail(c, INVALID_BODY, 400);
      const outcome = await settings.setPassport(c.get("userId"), body.data);
      if (!outcome.ok) return fail(c, PLUS_REQUIRED, 402);
      return ok(c, { passport: outcome.value });
    } catch (error: unknown) {
      logFailure("Passport update failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });

  app.put("/api/profile/incognito", authenticate, writes, async (c) => {
    try {
      const body = await readJson(c, incognitoBodySchema);
      if (!body.ok) return fail(c, INVALID_BODY, 400);
      const outcome = await settings.setIncognito(c.get("userId"), body.data.enabled);
      if (!outcome.ok) return fail(c, PLUS_REQUIRED, 402);
      return ok(c, { incognito: outcome.value });
    } catch (error: unknown) {
      logFailure("Discreet mode update failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });

  app.put("/api/profile/read-receipts", authenticate, writes, async (c) => {
    try {
      const body = await readJson(c, readReceiptsBodySchema);
      if (!body.ok) return fail(c, INVALID_BODY, 400);
      return ok(c, { send_read_receipts: await settings.setReadReceipts(c.get("userId"), body.data.enabled) });
    } catch (error: unknown) {
      logFailure("Read receipts update failed", error);
      return fail(c, INTERNAL_ERROR, 500);
    }
  });
}
