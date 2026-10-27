import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import type { AppVariables } from "../../shared/http/middleware";
import type { CreditsGateway } from "../credits/application/ports";
import { BOOST_MINUTES } from "../engagement/boost.routes";
import { activateBoost, getActiveBoost } from "../../db";
import { createActivityRecorder } from "./application/activity-recorder";
import { createBoostTimingService, type BoostTimingService } from "./application/boost-timing-service";
import type { ScheduledBoostNotifier } from "./application/ports";
import { CreditsBoostLauncher } from "./infra/credits-boost-launcher";
import { PgActivityStore } from "./infra/pg-activity-store";
import { PgScheduleStore } from "./infra/pg-schedule-store";
import { registerBoostTimingRoutes } from "./presentation/boost-timing.routes";

export { ensureBoostTimingSchema } from "./infra/schema";

export interface BoostTimingModule {
  readonly service: BoostTimingService;
  register(app: Hono<{ Variables: AppVariables }>, authenticate: MiddlewareHandler<{ Variables: AppVariables }>): void;
}

export function createBoostTimingModule(options: { sql: Sql; credits: CreditsGateway; notifier: ScheduledBoostNotifier }): BoostTimingModule {
  const activity = new PgActivityStore(options.sql);
  const service = createBoostTimingService({
    activity,
    schedules: new PgScheduleStore(options.sql),
    boosts: new CreditsBoostLauncher(options.credits, { getActive: getActiveBoost, activate: activateBoost }, BOOST_MINUTES),
    notifier: options.notifier,
  });
  const recorder = createActivityRecorder(activity);
  return { service, register: (app, authenticate) => registerBoostTimingRoutes(app, { authenticate, timing: service, activity: recorder }) };
}
