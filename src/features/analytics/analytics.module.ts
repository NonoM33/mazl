import type { Hono, MiddlewareHandler } from "hono";
import { createRateLimiter } from "../../shared/http/rate-limit";
import type { AppVariables } from "../../shared/http/middleware";
import { AnalyticsService } from "./application/analytics-service";
import type { AnalyticsConsentCheck, Pseudonymizer } from "./application/ports";
import { HmacPseudonymizer } from "./infra/hmac-pseudonymizer";
import { OpenPanelSink, type OpenPanelConfig } from "./infra/openpanel-sink";
import { registerAnalyticsRoutes } from "./presentation/analytics.routes";
import { observeServerEvents } from "./presentation/server-events";

export { withMessageAnalytics } from "./presentation/message-analytics";
export type { AnalyticsService } from "./application/analytics-service";

type Env = Readonly<Record<string, string | undefined>>;

interface AnalyticsSettings {
  readonly openPanel: OpenPanelConfig;
  readonly idKey: string;
}

// The app flushes every ~10 s: 30 batches a minute is far above normal use.
const BATCHES_PER_MINUTE = 30;

// All four variables, or none: a partial configuration is a mistake worth saying.
export function readAnalyticsSettings(env: Env): AnalyticsSettings | null {
  const apiUrl = env.OPENPANEL_API_URL?.trim() ?? "";
  const clientId = env.OPENPANEL_CLIENT_ID?.trim() ?? "";
  const clientSecret = env.OPENPANEL_CLIENT_SECRET?.trim() ?? "";
  const idKey = env.ANALYTICS_ID_KEY?.trim() ?? "";
  const given = [apiUrl, clientId, clientSecret, idKey].filter((value) => value !== "").length;
  if (given === 0) return null;
  if (given < 4) {
    console.warn("Analytics disabled: OPENPANEL_API_URL, OPENPANEL_CLIENT_ID, OPENPANEL_CLIENT_SECRET and ANALYTICS_ID_KEY are all needed");
    return null;
  }
  return { openPanel: { apiUrl, clientId, clientSecret }, idKey };
}

const unusedPseudonyms: Pseudonymizer = {
  profileIdOf: () => {
    throw new Error("analytics disabled");
  },
};

export function createAnalyticsService(env: Env, allowsAnalytics: AnalyticsConsentCheck): AnalyticsService {
  const settings = readAnalyticsSettings(env);
  return new AnalyticsService({
    sink: settings === null ? null : new OpenPanelSink(settings.openPanel),
    pseudonyms: settings === null ? unusedPseudonyms : new HmacPseudonymizer(settings.idKey),
    allowsAnalytics,
    environment: env.ANALYTICS_ENV?.trim() || (env.NODE_ENV === "production" ? "production" : "development"),
  });
}

// Register BEFORE the routes it observes (POST /api/swipes, purchases, verifications).
export function observeAnalytics(app: Hono<{ Variables: AppVariables }>, analytics: AnalyticsService): void {
  app.use("/api/*", observeServerEvents(analytics));
}

export function registerAnalytics(
  app: Hono<{ Variables: AppVariables }>,
  analytics: AnalyticsService,
  authenticate: MiddlewareHandler<{ Variables: AppVariables }>,
): void {
  registerAnalyticsRoutes(app, {
    authenticate,
    limiter: createRateLimiter({ max: BATCHES_PER_MINUTE, windowMs: 60_000 }),
    analytics,
  });
}
