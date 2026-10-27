import type { Env, Hono } from "hono";
import type { Sql } from "postgres";
import type { AuditLog } from "../audit/application/ports";
import type { RequirePermission, StaffVariables } from "../staff/application/ports";
import { CampaignService } from "./application/campaign-service";
import { CatalogService } from "./application/catalog-service";
import type { AppStorePricing, WebPricing } from "./application/ports";
import { appStoreNotConfigured, webPricingNotConfigured } from "./infra/not-configured";
import { PgCheckoutOverrides } from "./infra/pg-checkout-overrides";
import { PgStorefrontRepository } from "./infra/pg-storefront-repository";
import { ensureStorefrontSchema } from "./infra/schema";
import { registerPublicStorefrontRoute, registerStorefrontAdminRoutes } from "./presentation/routes";

export interface StorefrontModuleOptions {
  readonly sql: Sql;
  readonly audit: AuditLog;
  readonly requirePermission: RequirePermission;
  readonly env: Readonly<Record<string, string | undefined>>;
  // Adapters to Apple and Stripe; absent: "store_not_configured" is answered.
  readonly appStore?: AppStorePricing;
  readonly webPricing?: WebPricing;
  readonly now?: () => Date;
}

export interface StorefrontModule {
  ensureSchema(): Promise<void>;
  registerPublicRoutes<E extends Env>(app: Hono<E>): void;
  registerAdminRoutes(app: Hono<{ Variables: StaffVariables }>): void;
}

// Prices and promotions the web checkout reads from the storefront catalogue.
export function createCheckoutOverrides(sql: Sql): PgCheckoutOverrides {
  return new PgCheckoutOverrides(sql);
}

export function createStorefrontModule(options: StorefrontModuleOptions): StorefrontModule {
  const repository = new PgStorefrontRepository(options.sql);
  const now = options.now ?? ((): Date => new Date());
  const deps = {
    repository,
    apple: options.appStore ?? appStoreNotConfigured,
    web: options.webPricing ?? webPricingNotConfigured,
    audit: options.audit,
    env: options.env,
    now,
  };
  const catalog = new CatalogService(deps);
  const campaigns = new CampaignService(deps);
  return {
    ensureSchema: () => ensureStorefrontSchema(options.sql),
    registerPublicRoutes: (app) => registerPublicStorefrontRoute(app, { repository, now }),
    registerAdminRoutes: (app) =>
      registerStorefrontAdminRoutes(app, {
        requirePermission: options.requirePermission,
        catalog,
        campaigns,
        repository,
        now,
        exposeOpenApi: options.env.NODE_ENV !== "production",
      }),
  };
}
