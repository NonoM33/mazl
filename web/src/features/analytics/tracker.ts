import { matchPath } from "../../shared/router";

// The website's side of docs/analytics/plan-de-marquage.md: screens only,
// relayed by the server, never before the member's consent.

export interface AnalyticsBatchEvent {
  readonly name: string;
  readonly properties: Readonly<Record<string, string | number>>;
  readonly at: string;
}

export interface AnalyticsBatch {
  readonly platform: "web";
  readonly app_version: string;
  readonly events: readonly AnalyticsBatchEvent[];
}

export interface WebAnalyticsOptions {
  readonly post: (batch: AnalyticsBatch) => Promise<void>;
  readonly now: () => Date;
  readonly appVersion: string;
}

export interface WebAnalytics {
  // null: not decided yet; events wait in memory until then.
  setConsent(granted: boolean | null): void;
  screen(path: string): void;
  flush(): Promise<void>;
}

const MAX_WAITING = 100;
const MAX_BATCH = 50;

const SCREENS: readonly (readonly [string, string])[] = [
  ["/", "home"],
  ["/decouvrir", "discover"],
  ["/likes", "likes"],
  ["/messages", "messages"],
  ["/messages/:id", "chat"],
  ["/profil", "profile"],
  ["/profil/modifier", "editProfile"],
  ["/statistiques", "stats"],
  ["/evenements", "events"],
  ["/evenements/:id", "eventDetail"],
  ["/reglages", "settings"],
  ["/premium", "premium"],
  ["/couple", "coupleSpace"],
  ["/couple/activites", "coupleActivities"],
  ["/couple/calendrier", "coupleCalendar"],
  ["/couple/evenements", "coupleEvents"],
];

// The route's name: the path may hold an id, the name never does.
export function screenNameOf(path: string): string | null {
  return SCREENS.find(([pattern]) => matchPath(pattern, path) !== null)?.[1] ?? null;
}

export function createWebAnalytics(options: WebAnalyticsOptions): WebAnalytics {
  let consent: boolean | null = null;
  let waiting: AnalyticsBatchEvent[] = [];
  let lastScreen: string | null = null;

  const push = (name: string, properties: AnalyticsBatchEvent["properties"]) => {
    if (consent === false) return;
    waiting.push({ name, properties, at: options.now().toISOString() });
    if (waiting.length > MAX_WAITING) waiting = waiting.slice(-MAX_WAITING);
  };

  return {
    setConsent(granted) {
      if (granted === consent) return;
      const before = consent;
      consent = granted;
      if (granted === false) waiting = [];
      if (granted === true && before !== true) waiting.unshift({ name: "analytics_consent_granted", properties: {}, at: options.now().toISOString() });
    },
    screen(path) {
      const screen = screenNameOf(path);
      if (screen === null || screen === lastScreen) return;
      lastScreen = screen;
      push("screen_viewed", { screen });
    },
    async flush() {
      if (consent !== true) return;
      while (waiting.length > 0) {
        const events = waiting.slice(0, MAX_BATCH);
        try {
          await options.post({ platform: "web", app_version: options.appVersion, events });
        } catch {
          return; // Kept for the next flush.
        }
        waiting = waiting.slice(events.length);
      }
    },
  };
}
