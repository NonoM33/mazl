import type { Hono, MiddlewareHandler } from "hono";
import type { CreditsGateway } from "../credits/application/ports";
import type { CreditsView } from "../credits/domain/view";
import type { AppVariables } from "../../shared/http/middleware";
import { parseBody, swipeBodySchema } from "../../shared/http/validation";

export interface SwipeResult {
  readonly match: boolean;
  readonly targetUserId?: number;
}

// The swipe storage, injected so the route is tested without a database.
export interface SwipeStore {
  // The action already recorded from this member on this target, if any.
  currentAction(userId: number, targetUserId: number): Promise<string | null>;
  // Whether the target exists, is active and is not blocked in either direction.
  canSwipeOn(userId: number, targetUserId: number): Promise<boolean>;
  record(userId: number, targetUserId: number, action: string): Promise<SwipeResult>;
  // Notifies both members of a reciprocal match.
  onMatch(userId: number, targetUserId: number): Promise<void>;
}

export interface SwipeRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly credits: CreditsGateway;
  readonly swipes: SwipeStore;
}

// What the debit step decided: record the swipe, or stop with nothing to spend.
type SuperLikeOutcome = { readonly kind: "recorded"; readonly result: SwipeResult } | { readonly kind: "exhausted"; readonly credits: CreditsView };

// A super like costs one credit, taken BEFORE the swipe is recorded. The same
// super like sent again to the same person costs nothing, so the app can
// replay a request safely: the stored swipe says so, and the debit journal,
// checked under the balance lock, catches two simultaneous requests. A failed
// recording gives the credit back.
async function recordSuperLike(deps: SwipeRouteDeps, userId: number, targetUserId: number): Promise<SuperLikeOutcome> {
  const { credits, swipes } = deps;
  if ((await swipes.currentAction(userId, targetUserId)) === "super_like") {
    return { kind: "recorded", result: await swipes.record(userId, targetUserId, "super_like") };
  }
  const spent = await credits.spend(userId, "super_like", targetUserId, { kind: "once_per_target" });
  if (!spent.ok && spent.reason === "already_spent") {
    return { kind: "recorded", result: await swipes.record(userId, targetUserId, "super_like") };
  }
  if (!spent.ok) return { kind: "exhausted", credits: spent.credits };
  try {
    return { kind: "recorded", result: await swipes.record(userId, targetUserId, "super_like") };
  } catch (error: unknown) {
    await cancelQuietly(credits, userId, spent.spendId);
    throw error;
  }
}

async function cancelQuietly(credits: CreditsGateway, userId: number, spendId: number): Promise<void> {
  try {
    await credits.cancelSpend(userId, spendId);
  } catch (cancelError: unknown) {
    console.error("Super like debit could not be cancelled:", cancelError);
  }
}

export function registerSwipeRoute(app: Hono<{ Variables: AppVariables }>, deps: SwipeRouteDeps): void {
  app.post("/api/swipes", deps.authenticate, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(swipeBodySchema, c);
      if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
      const { target_user_id: targetUserId, action } = parsed.data;

      if (targetUserId === userId) {
        return c.json({ success: false, error: "Cannot swipe on yourself" }, 400);
      }
      // Checked before anything is debited or recorded; the same answer whether
      // the target is unknown, closed, or blocked in either direction.
      if (!(await deps.swipes.canSwipeOn(userId, targetUserId))) {
        return c.json({ success: false, error: "User not found" }, 404);
      }

      if (action !== "super_like") {
        const result = await deps.swipes.record(userId, targetUserId, action);
        if (result.match) await deps.swipes.onMatch(userId, targetUserId);
        return c.json({ success: true, ...result });
      }

      const outcome = await recordSuperLike(deps, userId, targetUserId);
      if (outcome.kind === "exhausted") {
        return c.json({ success: false, error: "super_likes_exhausted", credits: outcome.credits }, 402);
      }
      // On a reciprocal match, notify both users over WebSocket if connected.
      if (outcome.result.match) await deps.swipes.onMatch(userId, targetUserId);
      return c.json({ success: true, ...outcome.result, credits: await deps.credits.credits(userId) });
    } catch (error: unknown) {
      console.error("Swipe error:", error);
      return c.json({ success: false, error: "Failed to record swipe" }, 500);
    }
  });
}
