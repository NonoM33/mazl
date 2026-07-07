import { Hono } from "hono";
import { syncSubscription, getSubscription } from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";

// Map a RevenueCat product identifier to our stored plan_type.
// Product identifiers are declared in mobile/lib/core/services/revenuecat_service.dart
// (monthly, yearly, two_month, six_month, consumable). We also accept the
// common aliases RevenueCat/stores may surface (annual, three_month, lifetime).
function mapProductIdToPlanType(rawProductId: string): string {
  const productId = rawProductId.toLowerCase();

  // Order matters: match the most specific tokens first.
  if (productId.includes("lifetime") || productId.includes("consumable")) {
    return "lifetime";
  }
  if (productId.includes("six_month") || productId.includes("6_month") || productId.includes("6month")) {
    return "six_month";
  }
  if (productId.includes("three_month") || productId.includes("3_month") || productId.includes("3month")) {
    return "three_month";
  }
  if (productId.includes("two_month") || productId.includes("2_month") || productId.includes("2month")) {
    return "two_month";
  }
  if (productId.includes("yearly") || productId.includes("annual")) {
    return "yearly";
  }
  if (productId.includes("monthly")) {
    return "monthly";
  }
  return "unknown";
}

// Presentation layer for the SUBSCRIPTIONS feature (user-facing status + the
// RevenueCat webhook). These routes are moved verbatim from the monolith
// (src/index.ts): behaviour, payloads, status codes and auth are identical.
// The admin routes (/api/admin/subscriptions*) intentionally stay behind for a
// later admin feature extraction.
export function registerSubscriptionsRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get user subscription
  app.get("/api/subscription", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const subscription = await getSubscription(userId);

      return c.json({ success: true, subscription });
    } catch (error: unknown) {
      console.error("Subscription error:", error);
      return c.json({ success: false, error: "Failed to get subscription" }, 500);
    }
  });

  // RevenueCat webhook
  //
  // Authentication: RevenueCat is configured (dashboard > Integrations > Webhooks)
  // to send a shared secret in the `Authorization` header. We compare it against
  // REVENUECAT_WEBHOOK_SECRET using a constant-time comparison to avoid timing
  // side-channels. Without valid auth an attacker could forge events to grant or
  // revoke any user's subscription.
  app.post("/api/subscriptions/webhook", async (c) => {
    try {
      const crypto = require("crypto");

      const configuredSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
      if (!configuredSecret) {
        // Fail closed: refuse to process events if the shared secret is not set.
        console.error("RevenueCat webhook: REVENUECAT_WEBHOOK_SECRET is not configured; rejecting event.");
        return c.json({ success: false, error: "Webhook not configured" }, 503);
      }

      const providedAuth = c.req.header("Authorization") ?? "";
      const expectedBuf = Buffer.from(configuredSecret);
      const providedBuf = Buffer.from(providedAuth);
      const authorized =
        expectedBuf.length === providedBuf.length &&
        crypto.timingSafeEqual(expectedBuf, providedBuf);
      if (!authorized) {
        return c.json({ success: false, error: "Unauthorized" }, 401);
      }

      const body = await c.req.json();

      // RevenueCat sends events with app_user_id
      const appUserId: unknown = body?.event?.app_user_id;
      if (typeof appUserId !== "string" || appUserId.length === 0) {
        return c.json({ success: false, error: "No user ID" }, 400);
      }

      // Ignore anonymous RevenueCat identities ($RCAnonymousID:...): they are not
      // tied to one of our users, so there is nothing to sync. Acknowledge with
      // 200 so RevenueCat does not retry.
      if (appUserId.startsWith("$RCAnonymousID:")) {
        console.warn(`RevenueCat webhook: ignoring anonymous app_user_id ${appUserId}`);
        return c.json({ success: true, ignored: "anonymous" });
      }

      // Parse user ID (expected format is "user_123", but tolerate a bare id).
      const userId = parseInt(appUserId.replace("user_", ""), 10);
      if (Number.isNaN(userId)) {
        console.warn(`RevenueCat webhook: unparsable app_user_id ${appUserId}`);
        return c.json({ success: false, error: "Invalid user ID format" }, 400);
      }

      const event = body?.event;
      const productId: string = typeof event?.product_id === "string" ? event.product_id : "";
      const expiresAt = event?.expiration_at_ms
        ? new Date(event.expiration_at_ms).toISOString()
        : null;

      const planType = mapProductIdToPlanType(productId);

      // Determine status from event type
      let status = "active";
      if (event?.type === "CANCELLATION" || event?.type === "EXPIRATION") {
        status = "cancelled";
      } else if (event?.type === "BILLING_ISSUE") {
        status = "billing_issue";
      }

      await syncSubscription(userId, {
        planType,
        status,
        revenuecatId: event?.id,
        expiresAt: expiresAt || undefined,
      });

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Webhook error:", error);
      return c.json({ success: false, error: "Webhook processing failed" }, 500);
    }
  });
}
