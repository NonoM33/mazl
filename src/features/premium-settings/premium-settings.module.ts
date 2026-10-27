import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import type { AppVariables } from "../../shared/http/middleware";
import { PgPlusStatus } from "../credits/infra/pg-plus-status";
import { PremiumSettingsService } from "./application/premium-settings-service";
import { PgSettingsStore } from "./infra/pg-settings-store";
import { registerPremiumSettingsRoutes } from "./presentation/settings.routes";

export { ensurePremiumSettingsSchema } from "./infra/schema";

export function createPremiumSettingsService(sql: Sql): PremiumSettingsService {
  return new PremiumSettingsService(new PgSettingsStore(sql), new PgPlusStatus(sql));
}

export function registerPremiumSettings(
  app: Hono<{ Variables: AppVariables }>,
  settings: PremiumSettingsService,
  authenticate: MiddlewareHandler<{ Variables: AppVariables }>,
): void {
  registerPremiumSettingsRoutes(app, { authenticate, settings });
}
