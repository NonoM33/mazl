// The tracking plan, as code: docs/analytics/plan-de-marquage.md. An allowlist:
// an unknown event is refused, an unknown property removed, a value outside
// its format refuses the event. Nothing here may carry personal data.

export type PropertyValue = string | number;
export type EventProperties = Readonly<Record<string, PropertyValue>>;

export interface AnalyticsEvent {
  readonly name: string;
  readonly properties: EventProperties;
  readonly at: Date;
}

export type ClientPlatform = "ios" | "android" | "web";

export interface ClientContext {
  readonly platform: ClientPlatform;
  readonly appVersion: string;
}

type Rule = (value: unknown) => PropertyValue | null;

const IDENTIFIER = /^[a-z][a-zA-Z0-9_]{0,39}$/;
const PRODUCT_ID = /^[a-z0-9][a-z0-9._]{0,79}$/;
const APP_VERSION = /^\d{1,4}\.\d{1,4}\.\d{1,4}(\+\d{1,6})?$/;
const MAX_STEP = 30;
const MAX_AGE_MS = 24 * 60 * 60_000;
const FUTURE_TOLERANCE_MS = 60_000;

const matching =
  (pattern: RegExp): Rule =>
  (value) =>
    typeof value === "string" && pattern.test(value) ? value : null;

const oneOf =
  (...allowed: readonly string[]): Rule =>
  (value) =>
    typeof value === "string" && allowed.includes(value) ? value : null;

const stepNumber: Rule = (value) => (typeof value === "number" && Number.isInteger(value) && value >= 0 && value <= MAX_STEP ? value : null);

const identifier = matching(IDENTIFIER);
const productId = matching(PRODUCT_ID);

const CLIENT_EVENTS: Readonly<Record<string, Readonly<Record<string, Rule>>>> = {
  app_opened: {},
  screen_viewed: { screen: identifier },
  onboarding_step_viewed: { step: stepNumber, step_name: identifier },
  signup_completed: {},
  paywall_viewed: { source: identifier },
  purchase_started: { product_id: productId },
  purchase_cancelled: { product_id: productId },
  analytics_consent_granted: {},
};

export const CLIENT_EVENT_NAMES: readonly string[] = Object.keys(CLIENT_EVENTS);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// Every rule must accept its property; properties without a rule are dropped.
function applyRules(rules: Readonly<Record<string, Rule>>, raw: Record<string, unknown>): EventProperties | null {
  const kept: Record<string, PropertyValue> = {};
  for (const [key, rule] of Object.entries(rules)) {
    const value = rule(raw[key]);
    if (value === null) return null;
    kept[key] = value;
  }
  return kept;
}

// The time the event happened on the device: never in the future, at most a day old.
function eventTime(raw: unknown, now: Date): Date | null {
  if (typeof raw !== "string") return now;
  const at = new Date(raw);
  if (Number.isNaN(at.getTime()) || at.getTime() > now.getTime() + FUTURE_TOLERANCE_MS) return now;
  if (now.getTime() - at.getTime() > MAX_AGE_MS) return null;
  return at;
}

export function parseClientEvent(raw: unknown, now: Date): AnalyticsEvent | null {
  if (!isRecord(raw) || typeof raw.name !== "string") return null;
  const rules = Object.hasOwn(CLIENT_EVENTS, raw.name) ? CLIENT_EVENTS[raw.name] : undefined;
  if (rules === undefined) return null;
  const rawProperties = raw.properties ?? {};
  if (!isRecord(rawProperties)) return null;
  const properties = applyRules(rules, rawProperties);
  const at = eventTime(raw.at, now);
  if (properties === null || at === null) return null;
  return { name: raw.name, properties, at };
}

export function parseClientContext(raw: unknown): ClientContext | null {
  if (!isRecord(raw)) return null;
  const platform = oneOf("ios", "android", "web")(raw.platform);
  const appVersion = matching(APP_VERSION)(raw.app_version);
  if (platform === null || appVersion === null) return null;
  return { platform: platform as ClientPlatform, appVersion: String(appVersion) };
}

export type SwipeAction = "like" | "pass" | "super_like";
export type MatchRole = "initiator" | "receiver";
export type VerificationStep = "face" | "identity";
export type VerificationOutcome = "approved" | "rejected";

function serverEvent(name: string, rules: Readonly<Record<string, Rule>>, raw: Record<string, unknown>, at: Date): AnalyticsEvent | null {
  const properties = applyRules(rules, raw);
  return properties === null ? null : { name, properties, at };
}

// Built by the server from what other features return: still checked, so an
// unexpected value is dropped instead of forwarded.
export const serverEvents = {
  swipe: (action: SwipeAction, at: Date): AnalyticsEvent | null =>
    serverEvent("swipe", { action: oneOf("like", "pass", "super_like") }, { action }, at),
  matchCreated: (via: SwipeAction, role: MatchRole, at: Date): AnalyticsEvent | null =>
    serverEvent("match_created", { via: oneOf("like", "super_like"), role: oneOf("initiator", "receiver") }, { via, role }, at),
  messageSent: (at: Date): AnalyticsEvent => ({ name: "message_sent", properties: {}, at }),
  subscriptionValidated: (product: string, planType: string, at: Date): AnalyticsEvent | null =>
    serverEvent(
      "purchase_validated",
      { kind: oneOf("subscription"), product_id: productId, plan_type: identifier },
      { kind: "subscription", product_id: product, plan_type: planType },
      at,
    ),
  consumableValidated: (product: string, at: Date): AnalyticsEvent | null =>
    serverEvent("purchase_validated", { kind: oneOf("consumable"), product: identifier }, { kind: "consumable", product }, at),
  verificationSubmitted: (step: VerificationStep, outcome: VerificationOutcome, at: Date): AnalyticsEvent | null =>
    serverEvent(
      "verification_submitted",
      { step: oneOf("face", "identity"), outcome: oneOf("approved", "rejected") },
      { step, outcome },
      at,
    ),
};
