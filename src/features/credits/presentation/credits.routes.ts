import type { Context, Hono, MiddlewareHandler } from "hono";
import { z } from "zod";
import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../../subscriptions/domain/errors";
import type { AppVariables } from "../../../shared/http/middleware";
import type { CreditsService } from "../application/credits-service";

type App = Hono<{ Variables: AppVariables }>;
type RouteContext = Context<{ Variables: AppVariables }>;

export interface CreditsRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly credits: Pick<CreditsService, "credits" | "verifyPurchase">;
}

const MAX_TRANSACTION_CHARS = 20 * 1024;
const verifyBodySchema = z.object({ signedTransaction: z.string().min(1).max(MAX_TRANSACTION_CHARS) });

async function readJson(c: RouteContext): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return undefined;
  }
}

// Failures are logged by reason only: never a token, a payload or a signature.
function failure(c: RouteContext, error: unknown): Response {
  if (error instanceof InvalidTransactionError) {
    console.warn(`Apple consumable verification rejected: ${error.reason}`);
    return c.json({ success: false, error: "invalid_transaction" }, 422);
  }
  if (error instanceof TransactionOwnedByAnotherUserError) {
    return c.json({ success: false, error: "transaction_owned_by_another_user" }, 409);
  }
  console.error("Credits request failed:", error instanceof Error ? error.name : "unknown");
  return c.json({ success: false, error: "internal_error" }, 500);
}

export function registerCreditsRoutes(app: App, deps: CreditsRouteDeps): void {
  app.get("/api/credits", deps.authenticate, async (c) => {
    try {
      return c.json({ success: true, credits: await deps.credits.credits(c.get("userId")) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  // The app sends the StoreKit 2 signed transaction of a consumable purchase.
  app.post("/api/credits/apple/verify", deps.authenticate, async (c) => {
    const body = verifyBodySchema.safeParse(await readJson(c));
    if (!body.success) return c.json({ success: false, error: "invalid_body" }, 400);
    try {
      const purchase = await deps.credits.verifyPurchase(c.get("userId"), body.data.signedTransaction);
      return c.json({
        success: true,
        credited: purchase.credited,
        kind: purchase.kind,
        quantity: purchase.quantity,
        credits: purchase.credits,
      });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });
}
