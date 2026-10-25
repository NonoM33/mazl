import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import { PgPlusStatus } from "../credits/infra/pg-plus-status";
import type { PlusStatus } from "../credits/application/ports";
import type { AppVariables } from "../../shared/http/middleware";
import { teaserOf } from "./domain/teaser";

// Wraps GET /api/likes/received without touching the matching routes (they
// are rewritten on another branch): the answer gets `is_premium` at its root
// (V1-CONTRAT section 3) and, for a member without mazl+, each like is reduced
// to its teaser after the matching handler has answered.

export interface LikesVisibilityDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly plusStatus: PlusStatus;
}

const isRecord = (value: unknown): value is Record<string, unknown> => typeof value === "object" && value !== null && !Array.isArray(value);

async function reshaped(response: Response, isPremium: boolean): Promise<Response> {
  const body: unknown = await response.clone().json().catch(() => null);
  if (!isRecord(body) || !Array.isArray(body.likes)) return response;
  const likes = isPremium ? body.likes : body.likes.filter(isRecord).map(teaserOf);
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  return new Response(JSON.stringify({ ...body, is_premium: isPremium, likes }), { status: response.status, headers });
}

export function registerLikesVisibility(app: Hono<{ Variables: AppVariables }>, deps: LikesVisibilityDeps): void {
  app.get("/api/likes/received", deps.authenticate, async (c, next) => {
    await next();
    if (c.res.status !== 200) return;
    c.res = await reshaped(c.res, await deps.plusStatus.isPlus(c.get("userId")));
  });
}

export function createPlusStatus(sql: Sql): PlusStatus {
  return new PgPlusStatus(sql);
}
