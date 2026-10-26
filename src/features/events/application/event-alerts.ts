import type { EventAlertStore, EventOpenedPush } from "./ports";

// « Me prévenir » on a "coming soon" event, and the opening of an event, which
// tells every member who asked. An alert is sent once: a member told about an
// opening is not told again. Opening again an open event sends the alerts that
// could not leave the first time (no push provider yet, a failed delivery).

export type AlertOutcome = "requested" | "withdrawn" | "not_found" | "already_open";

export type OpenOutcome =
  | { readonly kind: "not_found" }
  // `pending`: alerts kept for later (push not configured, not delivered, or a draft).
  | { readonly kind: "opened" | "already_open"; readonly notified: number; readonly pending: number };

export interface EventAlerts {
  request(eventId: number, userId: number): Promise<AlertOutcome>;
  withdraw(eventId: number, userId: number): Promise<AlertOutcome>;
  isRequested(eventId: number, userId: number): Promise<boolean>;
  open(eventId: number): Promise<OpenOutcome>;
}

export function createEventAlerts(deps: { readonly store: EventAlertStore; readonly push: EventOpenedPush }): EventAlerts {
  const { store, push } = deps;

  async function request(eventId: number, userId: number): Promise<AlertOutcome> {
    const availability = await store.availabilityOf(eventId);
    if (availability === null) return "not_found";
    if (availability === "open") return "already_open";
    await store.request(eventId, userId);
    return "requested";
  }

  async function withdraw(eventId: number, userId: number): Promise<AlertOutcome> {
    if ((await store.availabilityOf(eventId)) === null) return "not_found";
    await store.withdraw(eventId, userId);
    return "withdrawn";
  }

  async function open(eventId: number): Promise<OpenOutcome> {
    const opened = await store.open(eventId);
    if (opened === null) return { kind: "not_found" };
    const kind = opened.alreadyOpen ? "already_open" : "opened";
    const recipients = await store.pendingRecipients(eventId);
    // A draft has no public page to open: its alerts wait for its publication.
    if (!opened.published || !push.isEnabled() || recipients.length === 0) {
      return { kind, notified: 0, pending: recipients.length };
    }
    const reached = await push.notify({ eventId, title: opened.title, recipientIds: recipients });
    await store.markNotified(eventId, reached);
    return { kind, notified: reached.length, pending: recipients.length - reached.length };
  }

  return { request, withdraw, isRequested: (eventId, userId) => store.isRequested(eventId, userId), open };
}
