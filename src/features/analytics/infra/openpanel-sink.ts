import type { AnalyticsSink, OutgoingEvent } from "../application/ports";

export interface OpenPanelConfig {
  readonly apiUrl: string;
  readonly clientId: string;
  readonly clientSecret: string;
}

const REQUEST_TIMEOUT_MS = 5_000;
// Loopback: OpenPanel finds no place for it, so no member is ever geolocated.
const NO_IP = "127.0.0.1";

// A user agent OpenPanel reads as the platform, without anything about the device.
const USER_AGENTS: Readonly<Record<OutgoingEvent["platform"], string>> = {
  ios: "Mozilla/5.0 (iPhone; CPU iPhone OS like Mac OS X) MAZL",
  android: "Mozilla/5.0 (Linux; Android) MAZL",
  web: "Mozilla/5.0 (Web) MAZL",
  // A single name/version: OpenPanel files it as a server event.
  server: "mazl-api/1.0",
};

// OpenPanel's own page-view event, so its Pages and entry/exit reports work.
function openPanelName(event: OutgoingEvent): { name: string; extra: Record<string, string> } {
  const screen = event.properties.screen;
  if (event.name === "screen_viewed" && typeof screen === "string") {
    return { name: "screen_view", extra: { __path: `/${screen}`, __title: screen } };
  }
  return { name: event.name, extra: {} };
}

function trackBody(event: OutgoingEvent): unknown {
  const { name, extra } = openPanelName(event);
  return {
    type: "track",
    payload: {
      name,
      profileId: event.profileId,
      properties: {
        ...event.properties,
        ...extra,
        // One device per member: sessions are counted per member, not per server IP.
        ...(event.platform === "server" ? {} : { __deviceId: event.profileId }),
        __timestamp: event.at.toISOString(),
        __ip: NO_IP,
      },
    },
  };
}

// The HTTP API of OpenPanel (self-hosted v2): POST /track, one event per request.
export class OpenPanelSink implements AnalyticsSink {
  private readonly trackUrl: string;

  constructor(
    private readonly config: OpenPanelConfig,
    private readonly fetcher: typeof fetch = fetch,
  ) {
    this.trackUrl = `${config.apiUrl.replace(/\/+$/, "")}/track`;
  }

  async send(events: readonly OutgoingEvent[]): Promise<void> {
    for (const event of events) await this.post(event);
  }

  private async post(event: OutgoingEvent): Promise<void> {
    const response = await this.fetcher(this.trackUrl, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "openpanel-client-id": this.config.clientId,
        "openpanel-client-secret": this.config.clientSecret,
        "user-agent": USER_AGENTS[event.platform],
      },
      body: JSON.stringify(trackBody(event)),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
    if (!response.ok) throw new Error(`OpenPanel answered ${response.status}`);
  }
}
