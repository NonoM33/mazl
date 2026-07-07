import { Hono } from "hono";
import {
  getDiscoverProfiles,
  recordSwipe,
  getMatches,
  getReceivedLikes,
  getReceivedLikesCount,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parseBody, swipeBodySchema } from "../../shared/http/validation";
import { emitNewMatch } from "../../shared/realtime/connections";

// Presentation layer for the MATCHING feature (core swipe / match / discover /
// received likes). These routes are moved verbatim from the monolith
// (src/index.ts): behaviour, payloads, status codes and relative ordering are
// identical to the original inline handlers. Boost, prompts, verification and
// couple endpoints are intentionally NOT part of this feature.
//
// `POST /api/swipes` still emits the `match:new` WebSocket event through
// `emitNewMatch`, now imported from `src/shared/realtime/connections.ts` (it
// depends on the shared `sql`/`sendToUser` helpers) with identical behaviour.
export function registerMatchingRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get profiles for discovery
  app.get("/api/discover", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const limit = parseInt(c.req.query("limit") || "20");
      const offset = parseInt(c.req.query("offset") || "0");

      const profiles = await getDiscoverProfiles(userId, limit, offset);

      return c.json({ success: true, profiles });
    } catch (error: unknown) {
      console.error("Discover error:", error);
      return c.json({ success: false, error: "Failed to get profiles" }, 500);
    }
  });

  // Get daily picks (curated selection of profiles)
  app.get("/api/daily-picks", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      // Get profiles and return top 5 as daily picks
      const profiles = await getDiscoverProfiles(userId, 5, 0);

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

  // Record swipe action
  app.post("/api/swipes", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(swipeBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const { target_user_id, action } = parsed.data;

      const result = await recordSwipe(userId, target_user_id, action);

      // On a reciprocal match, notify both users over WebSocket if connected.
      if (result.match) {
        await emitNewMatch(userId, target_user_id);
      }

      return c.json({ success: true, ...result });
    } catch (error: unknown) {
      console.error("Swipe error:", error);
      return c.json({ success: false, error: "Failed to record swipe" }, 500);
    }
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
