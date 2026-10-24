import type { Hono } from "hono";
import type { Sql } from "postgres";
import type { AuditLog } from "../audit/application/ports";
import type { RequirePermission, StaffVariables } from "../staff/application/ports";
import { createFeed, type Feed } from "./application/discover";
import { MatchingTuning } from "./application/tuning";
import { PgCandidateSource } from "./infra/pg-candidate-source";
import { PgFeedHydrator } from "./infra/pg-feed-hydrator";
import { PgParamsRepository } from "./infra/pg-params-repository";
import { ensureMatchingSchema } from "./infra/schema";
import { registerMatchingAdminRoutes } from "./presentation/matching-admin.routes";

export interface MatchingModuleOptions {
  readonly sql: Sql;
  readonly audit: AuditLog;
  readonly requirePermission: RequirePermission;
}

export interface MatchingModule {
  // Creates the tables and the initial parameter version. Call it once at start-up,
  // after initDb and after the trust-safety schema (member_sanctions).
  ensureSchema(): Promise<void>;
  readonly feed: Pick<Feed, "discover" | "dailyPicks">;
  registerAdminRoutes(app: Hono<{ Variables: StaffVariables }>): void;
}

export function createMatchingModule(options: MatchingModuleOptions): MatchingModule {
  const params = new PgParamsRepository(options.sql);
  const feed = createFeed({ params, candidates: new PgCandidateSource(options.sql), hydrator: new PgFeedHydrator(options.sql) });
  const tuning = new MatchingTuning({ params, audit: options.audit });
  return {
    ensureSchema: () => ensureMatchingSchema(options.sql),
    feed: { discover: feed.discover, dailyPicks: feed.dailyPicks },
    registerAdminRoutes: (app) =>
      registerMatchingAdminRoutes(app, { requirePermission: options.requirePermission, audit: options.audit, tuning }),
  };
}
