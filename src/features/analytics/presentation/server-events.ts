import type { Context, MiddlewareHandler } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
import type { AnalyticsService } from "../application/analytics-service";
import { serverEvents, type AnalyticsEvent, type SwipeAction } from "../domain/events";

type Recorder = Pick<AnalyticsService, "recordServerEvent">;
type RouteContext = Context<{ Variables: AppVariables }>;
type Json = Record<string, unknown>;

interface Observation {
  readonly userId: number;
  readonly request: Json;
  readonly response: Json;
  readonly at: Date;
}

type Observer = (seen: Observation) => ReadonlyArray<readonly [number, AnalyticsEvent | null]>;

const SWIPE_ACTIONS: readonly string[] = ["like", "pass", "super_like"];

const observeSwipe: Observer = ({ userId, request, response, at }) => {
  const action = request.action;
  if (typeof action !== "string" || !SWIPE_ACTIONS.includes(action)) return [];
  const swipe = action as SwipeAction;
  const events: Array<readonly [number, AnalyticsEvent | null]> = [[userId, serverEvents.swipe(swipe, at)]];
  if (response.match === true) {
    events.push([userId, serverEvents.matchCreated(swipe, "initiator", at)]);
    if (typeof response.targetUserId === "number") events.push([response.targetUserId, serverEvents.matchCreated(swipe, "receiver", at)]);
  }
  return events;
};

const observeSubscription: Observer = ({ userId, response, at }) => {
  const subscription = response.subscription as Json | undefined;
  const product = subscription?.product_id;
  const plan = subscription?.plan_type;
  return typeof product === "string" && typeof plan === "string" ? [[userId, serverEvents.subscriptionValidated(product, plan, at)]] : [];
};

// `credited: false` is a replayed receipt: already counted.
const observeConsumable: Observer = ({ userId, response, at }) =>
  response.credited === true && typeof response.kind === "string" ? [[userId, serverEvents.consumableValidated(response.kind, at)]] : [];

const observeVerification =
  (step: "face" | "identity"): Observer =>
  ({ userId, response, at }) =>
    typeof response.verified === "boolean"
      ? [[userId, serverEvents.verificationSubmitted(step, response.verified ? "approved" : "rejected", at)]]
      : [];

// Routes whose success is an event of the plan (docs/analytics/plan-de-marquage.md).
const OBSERVED: Readonly<Record<string, Observer>> = {
  "POST /api/swipes": observeSwipe,
  "POST /api/subscriptions/apple/verify": observeSubscription,
  "POST /api/credits/apple/verify": observeConsumable,
  "POST /api/verification/face/submit": observeVerification("face"),
  "POST /api/verification/identity": observeVerification("identity"),
};

async function jsonOf(read: () => Promise<unknown>): Promise<Json> {
  try {
    const value = await read();
    return typeof value === "object" && value !== null && !Array.isArray(value) ? (value as Json) : {};
  } catch {
    return {};
  }
}

// The request body was parsed by the route itself: Hono hands back its cached copy.
async function observation(c: RouteContext, isMultipart: boolean, at: Date): Promise<Observation | null> {
  const userId = c.get("userId");
  if (typeof userId !== "number" || c.res.status !== 200) return null;
  const response = await jsonOf(() => c.res.clone().json());
  if (response.success !== true) return null;
  const request = isMultipart ? {} : await jsonOf(() => c.req.json());
  return { userId, request, response, at };
}

// Watches the responses of a few routes, so that the features stay unaware of
// the analytics. Never changes or delays the response beyond reading it.
export function observeServerEvents(analytics: Recorder, clock: () => Date = () => new Date()): MiddlewareHandler<{ Variables: AppVariables }> {
  return async (c, next) => {
    await next();
    const observer = OBSERVED[`${c.req.method} ${c.req.path}`];
    if (observer === undefined) return;
    const isMultipart = (c.req.header("Content-Type") ?? "").startsWith("multipart/");
    const seen = await observation(c, isMultipart, clock());
    if (seen === null) return;
    for (const [userId, event] of observer(seen)) analytics.recordServerEvent(userId, event);
  };
}
