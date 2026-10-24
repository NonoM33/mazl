import type { Context, Hono, MiddlewareHandler } from "hono";
import { bodyLimit } from "hono/body-limit";
import { z } from "zod";
import { handleAppleNotification } from "../application/handle-notification";
import type { SubscriptionRepository } from "../application/ports";
import type { TransactionVerifier } from "../application/transaction-verifier";
import { verifyApplePurchase } from "../application/verify-purchase";
import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../domain/errors";
import type { AppVariables } from "../../../shared/http/middleware";

type App = Hono<{ Variables: AppVariables }>;
type RouteContext = Context<{ Variables: AppVariables }>;

export interface SubscriptionsRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly transactions: TransactionVerifier;
  readonly repository: SubscriptionRepository;
}

const MAX_TRANSACTION_CHARS = 20 * 1024;
const MAX_NOTIFICATION_CHARS = 64 * 1024;
const MAX_NOTIFICATION_BODY_BYTES = 128 * 1024;

const verifyBodySchema = z.object({ signedTransaction: z.string().min(1).max(MAX_TRANSACTION_CHARS) });
const notificationBodySchema = z.object({ signedPayload: z.string().min(1).max(MAX_NOTIFICATION_CHARS) });

async function readJson(c: RouteContext): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return undefined;
  }
}

// Failures are logged by reason only: never a token, a payload or a signature.
function failure(c: RouteContext, where: string, error: unknown): Response {
  if (error instanceof InvalidTransactionError) {
    console.warn(`Apple ${where} rejected: ${error.reason}`);
    return c.json({ success: false, error: "invalid_transaction" }, 422);
  }
  if (error instanceof TransactionOwnedByAnotherUserError) {
    return c.json({ success: false, error: "transaction_owned_by_another_user" }, 409);
  }
  console.error(`Apple ${where} failed:`, error instanceof Error ? error.name : "unknown");
  return c.json({ success: false, error: "internal_error" }, 500);
}

const invalidBody = (c: RouteContext): Response => c.json({ success: false, error: "invalid_body" }, 400);

export function registerSubscriptionsRoutes(app: App, deps: SubscriptionsRouteDeps): void {
  app.get("/api/subscription", deps.authenticate, async (c) => {
    try {
      const subscription = await deps.repository.findByUserId(c.get("userId"));
      return c.json({ success: true, subscription });
    } catch (error: unknown) {
      console.error("Subscription error:", error);
      return c.json({ success: false, error: "Failed to get subscription" }, 500);
    }
  });

  // The app sends the StoreKit 2 signed transaction of a purchase or restore.
  app.post("/api/subscriptions/apple/verify", deps.authenticate, async (c) => {
    const body = verifyBodySchema.safeParse(await readJson(c));
    if (!body.success) return invalidBody(c);
    try {
      const purchase = await verifyApplePurchase(deps, c.get("userId"), body.data.signedTransaction);
      return c.json({
        success: true,
        subscription: {
          plan_type: purchase.planType,
          status: purchase.status,
          expires_at: purchase.expiresAt.toISOString(),
          product_id: purchase.productId,
        },
      });
    } catch (error: unknown) {
      return failure(c, "purchase verification", error);
    }
  });

  // App Store Server Notifications V2. Public by design: Apple cannot
  // authenticate, so the JWS signature chain is the only credential.
  app.post(
    "/api/subscriptions/apple/notifications",
    bodyLimit({ maxSize: MAX_NOTIFICATION_BODY_BYTES, onError: (c) => c.json({ success: false, error: "invalid_body" }, 400) }),
    async (c) => {
      const body = notificationBodySchema.safeParse(await readJson(c));
      if (!body.success) return invalidBody(c);
      try {
        const outcome = await handleAppleNotification(deps, body.data.signedPayload);
        return c.json(outcome.kind === "ignored" ? { success: true, ignored: outcome.reason } : { success: true });
      } catch (error: unknown) {
        return failure(c, "notification", error);
      }
    },
  );
}
