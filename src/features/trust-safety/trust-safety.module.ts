import { randomBytes } from "node:crypto";
import type { Hono, Env } from "hono";
import type { Sql } from "postgres";
import type { AuditLog } from "../audit/application/ports";
import type { RequirePermission } from "../staff/application/ports";
import { AppealsService } from "./application/appeals-service";
import { SanctionEffects } from "./application/effects";
import { MembersService } from "./application/members-service";
import { OverviewService } from "./application/overview-service";
import type { AccountEnforcement, Clock, MemberNotifier, RandomBytes } from "./application/ports";
import { ReportsService } from "./application/reports-service";
import { SanctionsService } from "./application/sanctions-service";
import { reactivateExpiredSuspensions, startSanctionSweeper } from "./infra/expiry";
import { PgAppealsRepository } from "./infra/pg-appeals";
import { PgAuthorityRepository } from "./infra/pg-authorities";
import { PgConversationReader } from "./infra/pg-conversation";
import { PgFiguresRepository } from "./infra/pg-figures";
import { PgMembersRepository } from "./infra/pg-members";
import { PgReportsRepository } from "./infra/pg-reports";
import { PgSanctionsRepository } from "./infra/pg-sanctions";
import { ensureTrustSafetySchema } from "./infra/schema";
import { SilentNotifier } from "./infra/silent-notifier";
import { registerTrustSafetyRoutes } from "./presentation/trust-safety.routes";

export interface TrustSafetyModuleOptions {
  readonly sql: Sql;
  readonly audit: Pick<AuditLog, "record">;
  readonly requirePermission: RequirePermission;
  readonly enforcement: AccountEnforcement;
  readonly notifier?: MemberNotifier;
  // Test seams.
  readonly clock?: Clock;
  readonly random?: RandomBytes;
}

export interface TrustSafetyModule {
  register<E extends Env>(app: Hono<E>): void;
  ensureSchema(): Promise<void>;
  // Re-enables accounts whose suspension ran out; returns stop().
  startSweeper(intervalMs?: number): () => void;
  reactivateExpiredSuspensions(): Promise<number>;
}

const DEFAULT_SWEEP_MS = 60_000;

export function createTrustSafetyModule(options: TrustSafetyModuleOptions): TrustSafetyModule {
  const { sql } = options;
  const clock = options.clock ?? (() => new Date());
  const random = options.random ?? ((length: number) => new Uint8Array(randomBytes(length)));
  const reports = new PgReportsRepository(sql);
  const sanctions = new PgSanctionsRepository(sql);
  const appeals = new PgAppealsRepository(sql);
  const members = new PgMembersRepository(sql);
  const figures = new PgFiguresRepository(sql);
  const notifier = options.notifier ?? new SilentNotifier();
  const effects = new SanctionEffects(options.enforcement, sanctions, notifier);
  const services = {
    reports: new ReportsService({ reports, sanctions, members, conversations: new PgConversationReader(sql), effects, clock, random }),
    sanctions: new SanctionsService(sanctions, members, effects, clock, random),
    members: new MembersService(members, reports, sanctions, clock),
    appeals: new AppealsService(appeals, sanctions, effects, notifier, clock),
    overview: new OverviewService(figures, reports, clock),
    authorities: new PgAuthorityRepository(sql),
  };
  const sweep = () => reactivateExpiredSuspensions(sql, options.enforcement);
  return {
    register: (app) => registerTrustSafetyRoutes(app, { requirePermission: options.requirePermission, audit: options.audit, services }),
    ensureSchema: () => ensureTrustSafetySchema(sql),
    startSweeper: (intervalMs = DEFAULT_SWEEP_MS) => startSanctionSweeper(sweep, intervalMs),
    reactivateExpiredSuspensions: sweep,
  };
}
