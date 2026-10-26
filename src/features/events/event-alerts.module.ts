import type { Sql } from "postgres";
import type { PushTransport } from "../push/application/ports";
import { createEventAlerts, type EventAlerts } from "./application/event-alerts";
import { PgEventAlertStore } from "./infra/pg-event-alert-store";
import { transportEventOpenedPush } from "./infra/transport-event-opened-push";

// Composition root of the "coming soon" events: « Me prévenir », and the push
// sent to those members when an administrator opens the event.
export function createEventAlertsModule(options: { readonly sql: Sql; readonly transport: PushTransport }): EventAlerts {
  return createEventAlerts({
    store: new PgEventAlertStore(options.sql),
    push: transportEventOpenedPush(options.transport, { error: (line) => console.error(line) }),
  });
}
