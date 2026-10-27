import type { Env, Hono } from "hono";
import type { Sql } from "postgres";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import type { AuditLog } from "../audit/application/ports";
import { PgPushDirectory } from "../push/infra/pg-push-directory";
import type { PushDirectory, PushTransport } from "../push/application/ports";
import type { RequirePermission } from "../staff/application/ports";
import { ConciergeService } from "./application/concierge-service";
import { ReminderService } from "./application/reminder-service";
import { SpaceService } from "./application/space-service";
import type { CoupleContext } from "./application/space-ports";
import { assistantFromEnv, type FetchLike } from "./infra/anthropic-concierge-assistant";
import { candleLightingFor, PARIS } from "./infra/candle-lighting";
import { createMemberReminderPush } from "./infra/member-reminder-push";
import { PgConciergeStore } from "./infra/pg-concierge-store";
import { PgCouplePremium } from "./infra/pg-couple-premium";
import { PgCoupleSpace } from "./infra/pg-couple-space";
import { PgDailyQuestions } from "./infra/pg-daily-questions";
import { PgOutings } from "./infra/pg-outings";
import { PgReminderStore } from "./infra/pg-reminder-store";
import { PgRituals } from "./infra/pg-rituals";
import { staffNames } from "./infra/pg-staff-names";
import { getCoupleViewFor } from "./infra/couple-queries";
import { registerStaffConciergeRoutes } from "./presentation/concierge-staff.routes";
import { registerSpaceRoutes } from "./presentation/space.routes";
import type { ConciergePush, ConciergeAssistant } from "./application/concierge-ports";

// Composition root of the daily couple space (docs/couple/ESPACE-COUPLE.md):
// Today, rituals and their reminders, outings, the daily question, the monthly
// check-in and the concierge, for the members and for the team.

const REMINDER_SWEEP_MS = 60_000;

export interface CoupleSpaceOptions {
  readonly sql: Sql;
  readonly env: Readonly<Record<string, string | undefined>>;
  readonly transport: PushTransport;
  readonly fetch: FetchLike;
  // Tests give their own assistant; absent, it follows ANTHROPIC_API_KEY.
  readonly assistant?: ConciergeAssistant;
  readonly now?: () => Date;
}

export interface CoupleSpace {
  registerMemberRoutes(app: Hono<{ Variables: AppVariables }>): void;
  registerStaffRoutes<E extends Env>(
    app: Hono<E>,
    deps: { requirePermission: RequirePermission; audit: AuditLog; listStaffEmails: () => Promise<string[]>; exposeOpenApi: boolean },
  ): void;
  // Sweeps the reminders every minute (COUPLE_REMINDER_SWEEP_MS to change it).
  followReminders(everyMs?: number): void;
  readonly reminders: ReminderService;
}

function sweepInterval(env: Readonly<Record<string, string | undefined>>): number {
  const asked = Number(env.COUPLE_REMINDER_SWEEP_MS);
  return Number.isInteger(asked) && asked >= 100 ? asked : REMINDER_SWEEP_MS;
}

export function createCoupleSpace(options: CoupleSpaceOptions): CoupleSpace {
  const { sql, env, transport } = options;
  const now = options.now ?? (() => new Date());
  const log = (line: string): void => console.error(line);
  const directory: PushDirectory = new PgPushDirectory(sql);
  const push = createMemberReminderPush(transport, directory, log);

  const rituals = new PgRituals(sql);
  const premium = new PgCouplePremium(sql);
  const questions = new PgDailyQuestions(sql);
  const space = new SpaceService({
    store: new PgCoupleSpace(sql),
    rituals,
    outings: new PgOutings(sql),
    questions,
    premium,
    moodPush: {
      talkRequested: (partnerId) =>
        push.send(partnerId, { title: "Votre couple", message: "Votre partenaire aimerait trouver un moment pour parler.", data: { type: "couple_mood", route: "/couple/today" } }),
    },
    candleLighting: candleLightingFor(PARIS.latitude, PARIS.longitude, "Europe/Paris"),
  });

  const conciergePush: ConciergePush = {
    teamAnswered: async (memberIds) => {
      for (const memberId of memberIds) {
        await push.send(memberId, { title: "Conciergerie MAZL", message: "L'équipe MAZL vous a répondu.", data: { type: "couple_concierge", route: "/couple/concierge" } });
      }
    },
  };
  const concierge = new ConciergeService({
    store: new PgConciergeStore(sql),
    assistant: options.assistant ?? assistantFromEnv(env, options.fetch, log),
    push: conciergePush,
    now,
    log,
  });

  const reminders = new ReminderService({ store: new PgReminderStore(sql), push, candleLightingFor, paris: PARIS, log });

  async function loadCouple(userId: number): Promise<CoupleContext | null> {
    const view = await getCoupleViewFor(userId);
    if (view === null) return null;
    return { coupleId: view.id, userId, partnerId: view.partner_id, partnerName: view.partner_name, partnerPicture: view.partner_picture, startedAt: view.started_at };
  }

  return {
    reminders,
    registerMemberRoutes: (app) =>
      registerSpaceRoutes(app, {
        authenticate: requireAuth,
        loadCouple,
        space,
        rituals,
        questions,
        concierge,
        premium,
        questionPush: {
          partnerAnswered: (partnerId) =>
            push.send(partnerId, { title: "Question du jour", message: "Votre partenaire a répondu à la question du jour.", data: { type: "couple_question", route: "/couple/us" } }),
        },
        now,
      }),
    registerStaffRoutes: (app, deps) =>
      registerStaffConciergeRoutes(app, {
        requirePermission: deps.requirePermission,
        concierge,
        audit: deps.audit,
        assignableStaff: async () => staffNames(sql, await deps.listStaffEmails()),
        exposeOpenApi: deps.exposeOpenApi,
      }),
    followReminders: (everyMs = sweepInterval(env)) => {
      const timer = setInterval(() => {
        reminders.sweep(now()).catch((error: unknown) => console.error(`Couple reminder sweep failed: ${error instanceof Error ? error.name : "unknown"}`));
      }, everyMs);
      timer.unref();
    },
  };
}
