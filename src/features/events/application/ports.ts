import type { EventAvailability } from "../domain/event-availability";

// Ports of the "coming soon" events and of their alerts (« Me prévenir »).
// The Postgres adapter lives in ../infra, the push adapter in ../event-alerts.module.ts.

export interface OpenedEvent {
  readonly title: string;
  readonly published: boolean;
  // It was open before this call.
  readonly alreadyOpen: boolean;
}

export interface EventAlertStore {
  // Availability of a PUBLISHED event; null for a draft or an unknown id.
  availabilityOf(eventId: number): Promise<EventAvailability | null>;
  request(eventId: number, userId: number): Promise<void>;
  withdraw(eventId: number, userId: number): Promise<void>;
  isRequested(eventId: number, userId: number): Promise<boolean>;
  // Switches a "coming soon" event to open (an open one stays open); null when
  // the id is unknown.
  open(eventId: number): Promise<OpenedEvent | null>;
  // Members who asked for an alert and have not been told yet.
  pendingRecipients(eventId: number): Promise<number[]>;
  markNotified(eventId: number, userIds: readonly number[]): Promise<void>;
}

export interface EventOpenedPush {
  // False when no push provider is configured: nothing is sent.
  isEnabled(): boolean;
  // The ids of the members the push reached.
  notify(event: { readonly eventId: number; readonly title: string; readonly recipientIds: readonly number[] }): Promise<number[]>;
}
