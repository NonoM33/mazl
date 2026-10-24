import { Hono } from "hono";
import {
  getDiscoverProfiles,
  getSwipeAction,
  getProfilePreferences,
  recordSwipe,
  getMatches,
  getReceivedLikes,
  getReceivedLikesCount,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { emitNewMatch } from "../../shared/realtime/connections";
import { createRateLimiter } from "../../shared/http/rate-limit";
import type { CreditsGateway } from "../credits/application/ports";
import { registerSwipeRoute } from "./swipe.routes";
import { registerDiscoverRoutes } from "./presentation/discover.routes";

// Presentation layer for the MATCHING feature (core swipe / match / discover /
// received likes). These routes are moved verbatim from the monolith
// (src/index.ts): behaviour, payloads, status codes and relative ordering are
// identical to the original inline handlers. Boost, prompts, verification and
// couple endpoints are intentionally NOT part of this feature.
//
// `POST /api/swipes` still emits the `match:new` WebSocket event through
// `emitNewMatch`, now imported from `src/shared/realtime/connections.ts` (it
// depends on the shared `sql`/`sendToUser` helpers) with identical behaviour.
export interface MatchingRouteDeps {
  readonly credits: CreditsGateway;
}

export function registerMatchingRoutes(app: Hono<{ Variables: AppVariables }>, deps: MatchingRouteDeps): void {
  // CONTRAT.md §2.3: one shared budget of 300 feed requests per hour and user
  // for /api/discover and /api/daily-picks, against profile scraping.
  const feedLimiter = createRateLimiter({ max: 300, windowMs: 60 * 60 * 1000 });

  // Discovery feeds (GET /api/discover, GET /api/daily-picks): refused with 409
  // profile_incomplete until the caller has given gender and looking_for.
  registerDiscoverRoutes(app, {
    authenticate: requireAuth,
    feedLimiter,
    feed: {
      loadPreferences: getProfilePreferences,
      loadCandidates: getDiscoverProfiles,
    },
  });

  // Record swipe action. A super like is debited from the credits first.
  registerSwipeRoute(app, {
    authenticate: requireAuth,
    credits: deps.credits,
    swipes: { currentAction: getSwipeAction, record: recordSwipe, onMatch: emitNewMatch },
  });

  // Get user's matches
  app.get("/api/matches", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const matches = await getMatches(userId);

      return c.json({ success: true, matches });
    } catch (error: unknown) {
      console.error("Matches error:", error);
      return c.json({ success: false, error: "Failed to get matches" }, 500);
    }
  });

  // Profiles of users who liked me but with whom I have not matched yet.
  app.get("/api/likes/received", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const rows = await getReceivedLikes(userId);
      const likes = rows.map((r) => ({
        user_id: r.user_id,
        display_name: r.display_name,
        picture: r.picture,
        age: r.age !== null ? Math.trunc(r.age) : null,
        is_verified: r.is_verified === true,
        liked_at: r.liked_at,
      }));

      return c.json({ success: true, count: likes.length, likes });
    } catch (error: unknown) {
      console.error("Received likes error:", error);
      return c.json({ success: false, error: "Failed to get received likes" }, 500);
    }
  });

  // Count of received likes.
  app.get("/api/likes/received/count", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const count = await getReceivedLikesCount(userId);
      return c.json({ success: true, count });
    } catch (error: unknown) {
      console.error("Received likes count error:", error);
      return c.json({ success: false, error: "Failed to get likes count" }, 500);
    }
  });
}
