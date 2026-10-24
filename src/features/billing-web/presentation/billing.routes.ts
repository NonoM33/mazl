import type { Context, Hono, MiddlewareHandler } from "hono";
import { bodyLimit } from "hono/body-limit";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import type { CatalogService } from "../application/catalog-service";
import { unavailableCatalog } from "../application/catalog-service";
import type { CheckoutService, PortalService } from "../application/checkout-service";
import type { StatusService } from "../application/status-service";
import type { WebhookService } from "../application/webhook-service";
import {
  AlreadySubscribedError,
  InvalidSignatureError,
  NoCustomerError,
  OfferUnavailableError,
  StripeGatewayError,
  WithdrawalWaiverRequiredError,
} from "../domain/errors";
import { OFFERS, offerById } from "../domain/offers";

type App = Hono<{ Variables: AppVariables }>;
type RouteContext = Context<{ Variables: AppVariables }>;

export interface BillingServices {
  readonly catalog: CatalogService;
  readonly checkout: CheckoutService;
  readonly portal: PortalService;
  readonly status: StatusService;
  readonly webhook: WebhookService;
}

export interface BillingRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly checkoutLimiter: MiddlewareHandler<{ Variables: AppVariables }>;
  // Undefined when STRIPE_SECRET_KEY is not configured.
  readonly services: BillingServices | undefined;
}

const WEBHOOK_MAX_BYTES = 256 * 1024;

const checkoutBodySchema = z.object({
  offer: z.enum(OFFERS.map((offer) => offer.id) as [string, ...string[]]),
  withdrawal_waiver: z.boolean().optional(),
  waiver_version: z.string().max(40).optional(),
});

const unavailable = (c: RouteContext): Response => c.json({ success: false, error: "billing_unavailable" }, 503);

async function readJson(c: RouteContext): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return undefined;
  }
}

// Failures are logged by class only: never a key, a body or a signature.
function failure(c: RouteContext, error: unknown): Response {
  if (error instanceof WithdrawalWaiverRequiredError) return c.json({ success: false, error: "withdrawal_waiver_required" }, 400);
  if (error instanceof AlreadySubscribedError) return c.json({ success: false, error: "already_subscribed", source: error.source }, 409);
  if (error instanceof OfferUnavailableError) return c.json({ success: false, error: "offer_unavailable" }, 422);
  if (error instanceof NoCustomerError) return c.json({ success: false, error: "no_customer" }, 404);
  if (error instanceof StripeGatewayError) {
    console.error(`Billing request failed: ${error.message}`);
    return c.json({ success: false, error: "billing_upstream_error" }, 502);
  }
  console.error("Billing request failed:", error instanceof Error ? error.name : "unknown");
  return c.json({ success: false, error: "internal_error" }, 500);
}

function registerUnavailable(app: App, deps: BillingRouteDeps): void {
  app.get("/api/billing/catalog", (c) => c.json({ success: true, ...unavailableCatalog() }));
  app.get("/api/billing/status", deps.authenticate, unavailable);
  app.post("/api/billing/checkout", deps.authenticate, unavailable);
  app.post("/api/billing/portal", deps.authenticate, unavailable);
  app.post("/api/billing/stripe/webhook", unavailable);
}

function registerWebhook(app: App, webhook: WebhookService): void {
  const tooLarge = bodyLimit({ maxSize: WEBHOOK_MAX_BYTES, onError: (c) => c.json({ success: false, error: "payload_too_large" }, 413) });
  app.post("/api/billing/stripe/webhook", tooLarge, async (c) => {
    // The signature covers the exact bytes: the body is read raw, never parsed first.
    const rawBody = await c.req.text();
    try {
      const outcome = await webhook.handle(rawBody, c.req.header("stripe-signature"));
      return c.json(outcome === "duplicate" ? { received: true, duplicate: true } : { received: true });
    } catch (error: unknown) {
      if (error instanceof InvalidSignatureError) return c.json({ success: false, error: "invalid_signature" }, 400);
      console.error("Stripe webhook failed:", error instanceof Error ? `${error.name}: ${error.message}` : "unknown");
      return c.json({ success: false, error: "webhook_failed" }, 500);
    }
  });
}

export function registerBillingRoutes(app: App, deps: BillingRouteDeps): void {
  const { services } = deps;
  if (services === undefined) return registerUnavailable(app, deps);

  app.get("/api/billing/catalog", async (c) => {
    try {
      return c.json({ success: true, ...(await services.catalog.catalog()) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.get("/api/billing/status", deps.authenticate, async (c) => {
    try {
      return c.json({ success: true, ...(await services.status.status(c.get("userId"))) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.post("/api/billing/checkout", deps.authenticate, deps.checkoutLimiter, async (c) => {
    const body = checkoutBodySchema.safeParse(await readJson(c));
    const offer = body.success ? offerById(body.data.offer) : undefined;
    if (!body.success || offer === undefined) return c.json({ success: false, error: "invalid_body" }, 400);
    try {
      const session = await services.checkout.start(c.get("userId"), {
        offer,
        waiverAccepted: body.data.withdrawal_waiver,
        waiverVersion: body.data.waiver_version,
      });
      return c.json({ success: true, url: session.url });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.post("/api/billing/portal", deps.authenticate, async (c) => {
    try {
      return c.json({ success: true, ...(await services.portal.open(c.get("userId"))) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  registerWebhook(app, services.webhook);
}
