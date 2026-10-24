import { Hono } from "hono";
import {
  getDiscoverProfiles,
  getSwipeAction,
  canSwipeOn,
  recordSwipe,
  getMatches,
  getReceivedLikes,
  getReceivedLikesCount,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parsePage } from "../../shared/http/validation";
import { emitNewMatch } from "../../shared/realtime/connections";
import { createRateLimiter } from "../../shared/http/rate-limit";
import type { CreditsGateway } from "../credits/application/ports";
import type { Feed } from "./application/discover";
import { registerSwipeRoute } from "./swipe.routes";

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
  // The ranked feed (matching engine): the order is decided server-side.
  // TEMPORARY: while src/index.ts does not pass it, the legacy SQL ordering of
  // getDiscoverProfiles serves the feed. Make it required once wired.
  readonly feed?: Pick<Feed, "discover" | "dailyPicks">;
}

const legacyFeed: Pick<Feed, "discover" | "dailyPicks"> = {
  discover: (userId, page) => getDiscoverProfiles(userId, page.limit, page.offset),
  dailyPicks: (userId) => getDiscoverProfiles(userId, 5, 0),
};

// A page of the discover feed: the server decides how much it hands out.
const DISCOVER_DEFAULT_LIMIT = 20;
const DISCOVER_MAX_LIMIT = 50;

export function registerMatchingRoutes(app: Hono<{ Variables: AppVariables }>, deps: MatchingRouteDeps): void {
  const feed = deps.feed ?? legacyFeed;
  // CONTRAT.md §2.3: one shared budget of 300 feed requests per hour and user
  // for /api/discover and /api/daily-picks, against profile scraping.
  const feedLimiter = createRateLimiter({ max: 300, windowMs: 60 * 60 * 1000 });

  // Get profiles for discovery
  app.get("/api/discover", requireAuth, feedLimiter, async (c) => {
    try {
      const userId = c.get("userId");
      const { limit, offset } = parsePage(c.req.query("limit"), c.req.query("offset"), {
        defaultLimit: DISCOVER_DEFAULT_LIMIT,
        maxLimit: DISCOVER_MAX_LIMIT,
      });

      const profiles = await feed.discover(userId, { limit, offset });

      return c.json({ success: true, profiles });
    } catch (error: unknown) {
      console.error("Discover error:", error);
      return c.json({ success: false, error: "Failed to get profiles" }, 500);
    }
  });

  // Get daily picks (curated selection of profiles)
  app.get("/api/daily-picks", requireAuth, feedLimiter, async (c) => {
    try {
      const userId = c.get("userId");

      // Get profiles and return top 5 as daily picks
      const profiles = await feed.dailyPicks(userId);

      // Add "picked today" timestamp
      const today = new Date().toISOString().split('T')[0];

      return c.json({
        success: true,
        picks: profiles,
        date: today,
        refreshesAt: new Date(new Date().setHours(24, 0, 0, 0)).toISOString()
      });
    } catch (error: unknown) {
      console.error("Daily picks error:", error);
      return c.json({ success: false, error: "Failed to get daily picks" }, 500);
    }
  });

  // Record swipe action. A super like is debited from the credits first.
  registerSwipeRoute(app, {
    authenticate: requireAuth,
    credits: deps.credits,
    swipes: { currentAction: getSwipeAction, canSwipeOn, record: recordSwipe, onMatch: emitNewMatch },
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
