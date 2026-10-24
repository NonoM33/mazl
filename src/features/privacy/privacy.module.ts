import type { Hono } from "hono";
import type { Sql } from "postgres";
import { createRateLimiter } from "../../shared/http/rate-limit";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { ConsentService } from "./application/consent-service";
import { ExportService } from "./application/export-service";
import { PgConsentRepository } from "./infra/pg-consent-repository";
import { PgExportReader } from "./infra/pg-export-reader";
import { registerPrivacyRoutes } from "./presentation/privacy.routes";
import { createReligiousFieldsGuard } from "./presentation/religious-fields-guard";

export { ensurePrivacySchema } from "./infra/schema";
export { RELIGIOUS_DATA_TEXT, RELIGIOUS_DATA_VERSION } from "./domain/consent";

export interface PrivacyModule {
  readonly consents: ConsentService;
  readonly exports: ExportService;
}

const EXPORTS_PER_DAY = 3;

export function createPrivacyModule(sql: Sql): PrivacyModule {
  return {
    consents: new ConsentService(new PgConsentRepository(sql)),
    exports: new ExportService(new PgExportReader(sql)),
  };
}

export function registerPrivacy(app: Hono<{ Variables: AppVariables }>, module: PrivacyModule): void {
  registerPrivacyRoutes(app, {
    authenticate: requireAuth,
    exportLimiter: createRateLimiter({ max: EXPORTS_PER_DAY, windowMs: 24 * 60 * 60_000 }),
    consents: module.consents,
    exports: module.exports,
  });
  // In front of the profile route (registered after this): no religious data
  // stored without a valid consent (security review M4).
  app.put("/api/profile", requireAuth, createReligiousFieldsGuard(module.consents));
}
