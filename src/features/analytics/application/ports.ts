import type { ClientPlatform, EventProperties } from "../domain/events";

// An event ready to leave the server: pseudonymous, allowlisted, with the
// common properties (platform, app_version, env) already added.
export interface OutgoingEvent {
  readonly profileId: string;
  readonly name: string;
  readonly properties: EventProperties;
  readonly at: Date;
  readonly platform: ClientPlatform | "server";
}

// Where the events go (OpenPanel). May reject: the service never lets it fail a request.
export interface AnalyticsSink {
  send(events: readonly OutgoingEvent[]): Promise<void>;
}

// A stable pseudonym per member that cannot be turned back into the member's id.
export interface Pseudonymizer {
  profileIdOf(userId: number): string;
}

export type AnalyticsConsentCheck = (userId: number) => Promise<boolean>;
