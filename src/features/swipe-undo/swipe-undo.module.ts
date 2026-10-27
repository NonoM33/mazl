import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import type { AppVariables } from "../../shared/http/middleware";
import { PgPlusStatus } from "../credits/infra/pg-plus-status";
import { SwipeUndoService } from "./application/swipe-undo-service";
import { PgUndoStore } from "./infra/pg-undo-store";
import { registerSwipeUndoRoute } from "./presentation/undo.routes";

export { ensureSwipeUndoSchema } from "./infra/schema";

export function createSwipeUndoService(sql: Sql): SwipeUndoService {
  return new SwipeUndoService(new PgUndoStore(sql), new PgPlusStatus(sql));
}

export function registerSwipeUndo(
  app: Hono<{ Variables: AppVariables }>,
  undo: SwipeUndoService,
  authenticate: MiddlewareHandler<{ Variables: AppVariables }>,
): void {
  registerSwipeUndoRoute(app, { authenticate, undo });
}
