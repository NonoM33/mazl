import { parseClientEvent, type AnalyticsEvent, type ClientContext, type ClientPlatform } from "../domain/events";
import type { AnalyticsConsentCheck, AnalyticsSink, OutgoingEvent, Pseudonymizer } from "./ports";

export interface AnalyticsServiceOptions {
  // null when OpenPanel is not configured: everything is then a no-op.
  readonly sink: AnalyticsSink | null;
  readonly pseudonyms: Pseudonymizer;
  readonly allowsAnalytics: AnalyticsConsentCheck;
  readonly environment: string;
  readonly clock?: () => Date;
  // How long a consent lookup is trusted; a decision of the member clears it at once.
  readonly consentTtlMs?: number;
  // Events sent but not yet acknowledged; beyond it new ones are dropped, so a
  // slow OpenPanel or a flood of batches never grows the server's memory.
  readonly maxEventsInFlight?: number;
}

const DEFAULT_CONSENT_TTL_MS = 60_000;
const DEFAULT_MAX_EVENTS_IN_FLIGHT = 2_000;
const SERVER_VERSION = "1.0.0";

interface CachedConsent {
  readonly allowed: boolean;
  readonly until: number;
}

// Nothing leaves without the member's current analytics consent, checked here
// for every event, whether it comes from the app or from the server itself.
export class AnalyticsService {
  private readonly consents = new Map<number, CachedConsent>();
  private readonly clock: () => Date;
  private readonly consentTtlMs: number;
  private readonly maxEventsInFlight: number;
  private inFlight = 0;

  constructor(private readonly options: AnalyticsServiceOptions) {
    this.clock = options.clock ?? (() => new Date());
    this.consentTtlMs = options.consentTtlMs ?? DEFAULT_CONSENT_TTL_MS;
    this.maxEventsInFlight = options.maxEventsInFlight ?? DEFAULT_MAX_EVENTS_IN_FLIGHT;
  }

  get enabled(): boolean {
    return this.options.sink !== null;
  }

  // The events of the app or the website. Returns how many were accepted.
  async recordClientEvents(userId: number, context: ClientContext, rawEvents: readonly unknown[]): Promise<number> {
    if (!this.enabled || !(await this.allows(userId))) return 0;
    const now = this.clock();
    const events = rawEvents.map((raw) => parseClientEvent(raw, now)).filter((event) => event !== null);
    this.dispatch(events.map((event) => this.outgoing(userId, event, context.platform, context.appVersion)));
    return events.length;
  }

  // Fire and forget, from the request that caused it; never throws.
  recordServerEvent(userId: number, event: AnalyticsEvent | null): void {
    if (!this.enabled || event === null) return;
    this.allows(userId)
      .then((allowed) => {
        if (allowed) this.dispatch([this.outgoing(userId, event, "server", SERVER_VERSION)]);
      })
      .catch((error: unknown) => console.warn("Analytics consent lookup failed:", error instanceof Error ? error.name : "unknown"));
  }

  forgetConsent(userId: number): void {
    this.consents.delete(userId);
  }

  private async allows(userId: number): Promise<boolean> {
    const now = this.clock().getTime();
    const cached = this.consents.get(userId);
    if (cached !== undefined && cached.until > now) return cached.allowed;
    const allowed = await this.options.allowsAnalytics(userId);
    this.consents.set(userId, { allowed, until: now + this.consentTtlMs });
    return allowed;
  }

  private outgoing(userId: number, event: AnalyticsEvent, platform: ClientPlatform | "server", appVersion: string): OutgoingEvent {
    return {
      profileId: this.options.pseudonyms.profileIdOf(userId),
      name: event.name,
      properties: { ...event.properties, platform, app_version: appVersion, env: this.options.environment },
      at: event.at,
      platform,
    };
  }

  private dispatch(events: readonly OutgoingEvent[]): void {
    const sink = this.options.sink;
    if (sink === null || events.length === 0) return;
    if (this.inFlight + events.length > this.maxEventsInFlight) {
      console.warn(`Analytics events dropped: ${this.inFlight} already in flight`);
      return;
    }
    this.inFlight += events.length;
    sink
      .send(events)
      .catch((error: unknown) => {
        console.warn("Analytics events not delivered:", error instanceof Error ? error.message : "unknown");
      })
      .finally(() => {
        this.inFlight -= events.length;
      });
  }
}
