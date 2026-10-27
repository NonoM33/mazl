import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import { registerCoupleCoreRoutes } from "./couple.core.routes";
import { registerCoupleContentRoutes } from "./couple.content.routes";
import type { CoupleSpace } from "./couple-space.module";

// Presentation layer for the COUPLE feature. All `/api/couple/*` endpoints were
// moved verbatim out of the monolith (src/index.ts) — same paths, behaviour,
// payloads, status codes and, crucially, the same relative DECLARATION ORDER.
//
// The block is split across two files purely for readability; they are
// registered here in the exact original sequence:
//   1. core   — couple create/get, requests (request/requests/check/archive),
//                then the parameterised `/api/couple/:coupleId*` routes.
//   2. content — activities, saved, bookings, events, memories, dates,
//                bucket-list, stats/achievements.
// Registering core before content preserves the original ordering, and within
// each file the literal routes stay declared before their parameterised
// siblings so `:coupleId` / `:id` never capture literal segments such as
// `request`, `requests`, `check`, `activities`, `saved`, `events/registered`.
//
// IMPORTANT: this feature never imports from ../../index — realtime/auth/db
// helpers all come from the shared modules and the db layer, avoiding a cycle.
// The space routes (today, rituals, outings, check-in, daily question, concierge)
// come first: none of their paths is shadowed by a `:coupleId` route.
export function registerCoupleRoutes(app: Hono<{ Variables: AppVariables }>, space: CoupleSpace): void {
  space.registerMemberRoutes(app);
  registerCoupleCoreRoutes(app);
  registerCoupleContentRoutes(app);
}
