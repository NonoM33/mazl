import type { Hono } from "hono";
import type { Sql } from "postgres";
import { assertAdmin } from "../admin/admin.auth";
import { getPublishedEventById } from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { hasOpenConnection, onNewMatch } from "../../shared/realtime/connections";
import type { MessageNotifier } from "../chat/application/ports";
import type { LikeListener } from "../matching/swipe.routes";
import { createPushNotifier, type PushNotifier } from "./application/push-notifier";
import { PgBoostEndings } from "./infra/pg-boost-endings";
import { ensurePushSchema } from "./infra/pg-push-devices";
import { PgPushDirectory } from "./infra/pg-push-directory";
import { memberPushDevices, memberPushTransport } from "./member-push";
import { registerPushAdminRoutes } from "./presentation/push-admin.routes";
import { registerPushDevicesRoutes } from "./presentation/push-devices.routes";

// Composition root of the push notifications (V1-CONTRAT section 1): matches,
// messages, likes, the end of a Boost, events announced by the administrators,
// sent through gorush to the APNs tokens the app declares (/api/push/devices).
// Nothing is sent, and no query is made, while gorush is not configured.
export interface PushModule {
  readonly notifier: PushNotifier;
  // For the chat: told about each stored message, answers at once.
  readonly messageNotifier: MessageNotifier;
  // For the swipe route: told about each like that formed no match.
  readonly likeListener: LikeListener;
  // Pushes both members of every new match, whoever formed it.
  followMatches(): void;
  // Looks for ended Boosts every `everyMs` (BOOST_END_SWEEP_MS, a minute by default).
  followBoostEndings(everyMs?: number): void;
  ensureSchema(): Promise<void>;
  // PUT/DELETE /api/push/devices (members) and /api/admin/push/* (administrators).
  registerRoutes(app: Hono<{ Variables: AppVariables }>): void;
}

const BOOST_END_SWEEP_MS = 60_000;

function sweepInterval(env: Readonly<Record<string, string | undefined>>): number {
  const asked = Number(env.BOOST_END_SWEEP_MS);
  return Number.isInteger(asked) && asked >= 100 ? asked : BOOST_END_SWEEP_MS;
}

export function createPushModule(options: { sql: Sql }): PushModule {
  const notifier = createPushNotifier({
    transport: memberPushTransport,
    directory: new PgPushDirectory(options.sql),
    connections: { isConnected: hasOpenConnection },
    log: { error: (line) => console.error(line) },
  });
  const boostEndings = new PgBoostEndings(options.sql);

  async function sweepBoostEndings(): Promise<void> {
    if (!memberPushTransport.isEnabled()) return;
    for (const userId of await boostEndings.claimEnded()) await notifier.boostEnded(userId);
  }

  return {
    notifier,
    messageNotifier: { messageCreated: (event) => void notifier.messageReceived(event).catch(() => undefined) },
    likeListener: { likeReceived: (like) => void notifier.likeReceived(like).catch(() => undefined) },
    followMatches: () => onNewMatch((match) => void notifier.matchFormed(match).catch(() => undefined)),
    followBoostEndings: (everyMs = sweepInterval(process.env)) => {
      const timer = setInterval(() => {
        sweepBoostEndings().catch((error: unknown) => console.error(`Boost end sweep failed: ${error instanceof Error ? error.name : "unknown"}`));
      }, everyMs);
      timer.unref();
    },
    ensureSchema: () => ensurePushSchema(options.sql),
    registerRoutes: (app) => {
      registerPushDevicesRoutes(app, { authenticate: requireAuth, devices: memberPushDevices });
      registerPushAdminRoutes(app, {
        isAdmin: assertAdmin,
        isConfigured: () => memberPushTransport.isEnabled(),
        loadEvent: async (eventId) => {
          const event = await getPublishedEventById(eventId);
          return event === null || event === undefined ? null : { id: Number(event.id), title: String(event.title ?? "") };
        },
        notifier,
      });
    },
  };
}
