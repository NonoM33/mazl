import type { Context, Hono, MiddlewareHandler } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
import { getDiscoverFeed, type DiscoverFeedDeps } from "../application/discover-feed";

type AppEnv = { Variables: AppVariables };

export interface DiscoverRouteDeps<Candidate> {
  readonly authenticate: MiddlewareHandler<AppEnv>;
  /** Shared budget against profile scraping (CONTRAT.md §2.3). */
  readonly feedLimiter: MiddlewareHandler<AppEnv>;
  readonly feed: DiscoverFeedDeps<Candidate>;
}

// 409 profile_incomplete: the caller has not said who they are / who they look
// for. The app answers by sending the member to the profile setup.
function incompleteProfile(c: Context<AppEnv>, missing: readonly string[]): Response {
  return c.json({ success: false, error: "profile_incomplete", missing }, 409);
}

// GET /api/discover and GET /api/daily-picks: the two feeds built from the same
// candidate query, hence the same guard.
export function registerDiscoverRoutes<Candidate>(
  app: Hono<AppEnv>,
  deps: DiscoverRouteDeps<Candidate>,
): void {
  const { authenticate, feedLimiter, feed } = deps;

  app.get("/api/discover", authenticate, feedLimiter, async (c) => {
    try {
      const userId = c.get("userId");
      const limit = parseInt(c.req.query("limit") || "20");
      const offset = parseInt(c.req.query("offset") || "0");

      const result = await getDiscoverFeed(feed, userId, limit, offset);
      if (!result.ok) return incompleteProfile(c, result.missing);

      return c.json({ success: true, profiles: result.profiles });
    } catch (error: unknown) {
      console.error("Discover error:", error);
      return c.json({ success: false, error: "Failed to get profiles" }, 500);
    }
  });

  app.get("/api/daily-picks", authenticate, feedLimiter, async (c) => {
    try {
      const userId = c.get("userId");

      const result = await getDiscoverFeed(feed, userId, 5, 0);
      if (!result.ok) return incompleteProfile(c, result.missing);

      // Add "picked today" timestamp
      const today = new Date().toISOString().split("T")[0];

      return c.json({
        success: true,
        picks: result.profiles,
        date: today,
        refreshesAt: new Date(new Date().setHours(24, 0, 0, 0)).toISOString(),
      });
    } catch (error: unknown) {
      console.error("Daily picks error:", error);
      return c.json({ success: false, error: "Failed to get daily picks" }, 500);
    }
  });
}
