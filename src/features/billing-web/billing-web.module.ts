import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import type { AppVariables } from "../../shared/http/middleware";
import { createRateLimiter } from "../../shared/http/rate-limit";
import type { UserErasure } from "../admin/admin.erasure";
import { PgCreditsRepository } from "../credits/infra/pg-credits-repository";
import { CatalogService } from "./application/catalog-service";
import { CheckoutService, PortalService } from "./application/checkout-service";
import { systemClock, type Clock } from "./application/clock";
import type { BillingRepository, CheckoutOverrides, StripeGateway, WebhookVerifier } from "./application/ports";
import { StatusService } from "./application/status-service";
import { SubscriptionCancellation } from "./application/subscription-cancellation";
import { SubscriptionSync } from "./application/subscription-sync";
import { WebhookService } from "./application/webhook-service";
import { readBillingConfig, type BillingConfig } from "./infra/config";
import { PgBillingRepository } from "./infra/pg-billing-repository";
import { createStripeClient, SdkStripeGateway } from "./infra/stripe-sdk-gateway";
import { StripeWebhookVerifier } from "./infra/stripe-webhook-verifier";
import { registerBillingRoutes, type BillingServices } from "./presentation/billing.routes";

export { ensureBillingWebSchema } from "./infra/schema";

export interface BillingWebOptions {
  readonly sql: Sql;
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly env?: Readonly<Record<string, string | undefined>>;
  // Test seams: the real Stripe adapters are built from the configuration otherwise.
  readonly gateway?: StripeGateway;
  readonly verifier?: WebhookVerifier;
  readonly repository?: BillingRepository;
  readonly clock?: Clock;
  // Price and promotion decided in the back-office storefront; none: the environment variables.
  readonly overrides?: CheckoutOverrides;
}

export interface BillingWebModule {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  // Undefined while STRIPE_SECRET_KEY is missing: the routes answer 503.
  readonly services: BillingServices | undefined;
  // Returns the member's Stripe customer, deleted by forgetCustomer after the erasure.
  readonly cancelSubscriptions: (userId: number) => Promise<string | undefined | void>;
  readonly forgetCustomer?: (customerId: string) => Promise<void>;
}

function buildServices(options: BillingWebOptions, config: BillingConfig): { services: BillingServices; cancellation: SubscriptionCancellation } | undefined {
  if (!config.available) return undefined;
  const stripe = createStripeClient({ secretKey: config.secretKey, apiBase: config.apiBase });
  const gateway = options.gateway ?? new SdkStripeGateway(stripe);
  const repository = options.repository ?? new PgBillingRepository(options.sql);
  const clock = options.clock ?? systemClock;
  const sync = new SubscriptionSync({ gateway, repository, settings: config.settings });
  const services: BillingServices = {
    catalog: new CatalogService(gateway, config.settings, clock, options.overrides),
    checkout: new CheckoutService(gateway, repository, config.settings, options.overrides),
    portal: new PortalService(gateway, repository, config.settings),
    status: new StatusService(repository, sync, clock),
    webhook: new WebhookService({
      verifier: options.verifier ?? new StripeWebhookVerifier(stripe, config.webhookSecret),
      repository,
      sync,
      credits: new PgCreditsRepository(options.sql),
    }),
  };
  return { services, cancellation: new SubscriptionCancellation(gateway, repository) };
}

// Web payments through Stripe Checkout (docs/web/adr/W04-stripe.md). Throws
// BillingConfigError at boot on an unsafe configuration (live key, no webhook secret).
export function createBillingWeb(options: BillingWebOptions): BillingWebModule {
  const built = buildServices(options, readBillingConfig(options.env ?? process.env));
  return {
    authenticate: options.authenticate,
    services: built?.services,
    cancelSubscriptions: async (userId) => (built === undefined ? undefined : await built.cancellation.cancelAll(userId)),
    forgetCustomer: async (customerId) => {
      if (built !== undefined) await built.cancellation.forgetCustomer(customerId);
    },
  };
}

export function registerBillingWeb(app: Hono<{ Variables: AppVariables }>, module: BillingWebModule): void {
  registerBillingRoutes(app, {
    authenticate: module.authenticate,
    checkoutLimiter: createRateLimiter({ max: 10, windowMs: 60 * 60_000 }),
    services: module.services,
  });
}

// A failed Stripe cancellation fails the erasure: a member must never be erased
// while the card keeps being charged.
export function withStripeCancellation(erasure: UserErasure, billing: Pick<BillingWebModule, "cancelSubscriptions" | "forgetCustomer">): UserErasure {
  return {
    around: async (userId, deletion) => {
      const customerId = await billing.cancelSubscriptions(userId);
      const erased = await erasure.around(userId, deletion);
      // The member is gone: a failure here leaves an empty customer at Stripe,
      // reported, never an undeleted member.
      if (typeof customerId === "string" && billing.forgetCustomer) {
        await billing.forgetCustomer(customerId).catch((error: unknown) => {
          console.error("Stripe customer deletion failed:", error instanceof Error ? error.name : "unknown");
        });
      }
      return erased;
    },
  };
}
