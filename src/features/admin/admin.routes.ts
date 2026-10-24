import type { UserErasure } from "./admin.erasure";
import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import type { DocumentsModule } from "../documents";
import { registerAdminVerificationRoutes } from "./admin.verification.routes";
import {
  registerAdminEventsCrudRoutes,
  registerAdminEventsModuleRoutes,
} from "./admin.events.routes";
import {
  registerAdminUsersOverviewRoutes,
  registerAdminMembersModuleRoutes,
} from "./admin.members.routes";
import { registerAdminSubscriptionsRoutes } from "./admin.subscriptions.routes";
import {
  registerAdminTestingRoutes,
  registerAdminTestMessageRoute,
} from "./admin.tools.routes";
import { registerAdminCampaignsRoutes } from "./admin.campaigns.routes";
import { registerAdminModerationRoutes } from "./admin.moderation.routes";

// Presentation layer for the ADMIN feature. All `/api/admin/*` endpoints were
// moved verbatim out of the monolith (src/index.ts) — same absolute paths,
// behaviour, payloads, status codes. Admin routes authenticate with a dedicated
// admin JWT + email whitelist via `assertAdmin`
// (NOT the user `requireAuth` middleware); those helpers live in admin.auth.ts.
//
// The sub-registrations are invoked here in the EXACT original relative
// declaration order of the admin routes as they appeared in src/index.ts:
//   1. verification   — login, google-login, verify, pending/verified,
//                        document & profile review, document file download.
//   2. events CRUD     — GET/POST/PUT/DELETE /api/admin/events, attendees.
//   3. users overview  — stats, users list, user status.
//   4. subscriptions   — GET /api/admin/subscriptions.
//   5. testing tools   — test-match, seed-profiles, reset-swipes.
//   6. test message    — POST /api/admin/test-message.
//   7. members module  — user detail, ban/unban, notes, activity, delete,
//                        verification level.
//   8. events module   — details, photos, check-in, export, duplicate.
//   9. campaigns       — campaigns CRUD/send, segments.
//  10. moderation      — reports, report stats, handle report, pending photos,
//                        approve/reject photo, moderation logs.
//
// The documents module is passed through to the verification routes: the
// document file-download endpoint reads through its file store (owned by
// src/index.ts, disk or bucket).
export function registerAdminRoutes(
  app: Hono<{ Variables: AppVariables }>,
  documents: DocumentsModule,
  erasure: UserErasure,
): void {
  registerAdminVerificationRoutes(app, documents);
  registerAdminEventsCrudRoutes(app);
  registerAdminUsersOverviewRoutes(app);
  registerAdminSubscriptionsRoutes(app);
  registerAdminTestingRoutes(app);
  registerAdminTestMessageRoute(app);
  registerAdminMembersModuleRoutes(app, erasure);
  registerAdminEventsModuleRoutes(app);
  registerAdminCampaignsRoutes(app);
  registerAdminModerationRoutes(app);
}
