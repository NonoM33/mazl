import type { Hono } from "hono";
import { startVerification } from "../../../db";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";

// The pre-face-verification endpoints, kept for app versions in the field.
// `start` still hands out a gesture; `submit` no longer verifies anyone: the
// old flow marked any base64 string as verified.
export function registerLegacyVerificationRoutes(app: Hono<{ Variables: AppVariables }>): void {
  app.post("/api/verification/start", requireAuth, async (c) => {
    try {
      const result = await startVerification(c.get("userId"));
      if (!result.ok) {
        return c.json(
          {
            success: false,
            error: result.message ?? "Daily verification limit reached",
            next_attempt_time: result.nextAttemptTime,
          },
          429,
        );
      }
      return c.json({ success: true, gesture_id: result.gestureId });
    } catch (error: unknown) {
      console.error("Verification start error:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "Failed to start verification" }, 500);
    }
  });

  app.post("/api/verification/submit", requireAuth, (c) =>
    c.json({ success: true, verified: false, reason: "app_update_required" }),
  );
}
