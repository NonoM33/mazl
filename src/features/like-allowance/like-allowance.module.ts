import type { Hono } from "hono";
import type { Sql } from "postgres";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { PgPlusStatus } from "../credits/infra/pg-plus-status";
import { LikeAllowanceService } from "./application/like-allowance-service";
import { PgLikeLedger } from "./infra/pg-like-ledger";
import { registerLikeAllowanceRoutes } from "./presentation/like-allowance.routes";

export function createLikeAllowanceService(sql: Sql): LikeAllowanceService {
  return new LikeAllowanceService(new PgLikeLedger(sql), new PgPlusStatus(sql));
}

// Must be called BEFORE registerMatchingRoutes so the guard sits in front of POST /api/swipes.
export function registerLikeAllowance(app: Hono<{ Variables: AppVariables }>, allowance: LikeAllowanceService): void {
  registerLikeAllowanceRoutes(app, { authenticate: requireAuth, allowance });
}
