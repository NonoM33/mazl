import type { Sql } from "postgres";
import { hasOpenConnection, onNewMatch } from "../../shared/realtime/connections";
import type { MessageNotifier } from "../chat/application/ports";
import { createPushNotifier, type PushNotifier } from "./application/push-notifier";
import { PgPushDirectory } from "./infra/pg-push-directory";
import { oneSignalTransport } from "./infra/onesignal-transport";

// Composition root of the push notifications of matches and messages
// (V1-CONTRAT section 1). Nothing is sent, and no query is made, while
// ONESIGNAL_REST_API_KEY is absent.
export interface PushModule {
  readonly notifier: PushNotifier;
  // For the chat: told about each stored message, answers at once.
  readonly messageNotifier: MessageNotifier;
  // Pushes both members of every new match, whoever formed it.
  followMatches(): void;
}

export function createPushModule(options: { sql: Sql }): PushModule {
  const notifier = createPushNotifier({
    transport: oneSignalTransport,
    directory: new PgPushDirectory(options.sql),
    connections: { isConnected: hasOpenConnection },
    log: { error: (line) => console.error(line) },
  });
  return {
    notifier,
    messageNotifier: { messageCreated: (event) => void notifier.messageReceived(event).catch(() => undefined) },
    followMatches: () => onNewMatch((match) => void notifier.matchFormed(match).catch(() => undefined)),
  };
}
