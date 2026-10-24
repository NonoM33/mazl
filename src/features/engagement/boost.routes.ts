import type { Hono, MiddlewareHandler } from "hono";
import type { CreditsGateway } from "../credits/application/ports";
import type { CreditsView } from "../credits/domain/view";
import type { AppVariables } from "../../shared/http/middleware";

export interface BoostRecord {
  readonly id: number;
  readonly user_id: number;
  readonly activated_at: Date;
  readonly expires_at: Date;
  readonly created_at: Date;
}

// The boosts storage, injected so the routes are tested without a database.
export interface BoostStore {
  getActive(userId: number): Promise<BoostRecord | null>;
  usedToday(userId: number): Promise<number>;
  activate(userId: number, durationMinutes: number): Promise<BoostRecord>;
}

export interface BoostRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly credits: CreditsGateway;
  readonly boosts: BoostStore;
}

const BOOST_MINUTES = 30;

// Keys are snake_case to match the mobile BoostStatus.fromJson parser.
async function buildBoostStatus(deps: BoostRouteDeps, userId: number, credits: CreditsView) {
  const [activeBoost, boostsUsedToday] = await Promise.all([deps.boosts.getActive(userId), deps.boosts.usedToday(userId)]);
  const expiresAt = activeBoost ? activeBoost.expires_at.toISOString() : null;
  return {
    is_active: activeBoost !== null,
    expires_at: expiresAt,
    active_until: expiresAt,
    remaining_boosts: credits.boost.available,
    boosts_used_today: boostsUsedToday,
    views_during_boost: 0,
    likes_during_boost: 0,
    credits,
  };
}

async function cancelQuietly(credits: CreditsGateway, userId: number, spendId: number): Promise<void> {
  try {
    await credits.cancelSpend(userId, spendId);
  } catch (cancelError: unknown) {
    console.error("Boost debit could not be cancelled:", cancelError);
  }
}

export function registerBoostRoutes(app: Hono<{ Variables: AppVariables }>, deps: BoostRouteDeps): void {
  app.get("/api/boost/status", deps.authenticate, async (c) => {
    try {
      const userId = c.get("userId");
      const status = await buildBoostStatus(deps, userId, await deps.credits.credits(userId));
      return c.json({ success: true, ...status });
    } catch (error: unknown) {
      console.error("Boost status error:", error);
      return c.json({ success: false, error: "Failed to get boost status" }, 500);
    }
  });

  // Activate a boost (30 minutes). The credit is taken before the insertion
  // and given back if the insertion fails.
  app.post("/api/boost/activate", deps.authenticate, async (c) => {
    try {
      const userId = c.get("userId");
      if ((await deps.boosts.getActive(userId)) !== null) {
        return c.json({ success: false, error: "boost_already_active" }, 409);
      }
      // The guard, checked under the balance lock, stops a second activation
      // sent at the same time from paying for a second boost.
      const spent = await deps.credits.spend(userId, "boost", undefined, { kind: "once_within", minutes: BOOST_MINUTES });
      if (!spent.ok && spent.reason === "already_spent") {
        return c.json({ success: false, error: "boost_already_active" }, 409);
      }
      if (!spent.ok) return c.json({ success: false, error: "boosts_exhausted", credits: spent.credits }, 402);

      let boost: BoostRecord;
      try {
        boost = await deps.boosts.activate(userId, BOOST_MINUTES);
      } catch (error: unknown) {
        await cancelQuietly(deps.credits, userId, spent.spendId);
        throw error;
      }
      const status = await buildBoostStatus(deps, userId, spent.credits);
      return c.json({ success: true, boost, status, ...status }, 201);
    } catch (error: unknown) {
      console.error("Boost activate error:", error);
      return c.json({ success: false, error: "Failed to activate boost" }, 500);
    }
  });
}
