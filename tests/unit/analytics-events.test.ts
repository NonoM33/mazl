import { describe, expect, test } from "bun:test";
import {
  CLIENT_EVENT_NAMES,
  parseClientContext,
  parseClientEvent,
  serverEvents,
} from "../../src/features/analytics/domain/events";

// docs/analytics/plan-de-marquage.md is the source of these lists: written
// from the plan, not from the code, so a property added by mistake fails here.
const PLAN_CLIENT_EVENTS: Record<string, Record<string, string | number>> = {
  app_opened: {},
  screen_viewed: { screen: "discover" },
  onboarding_step_viewed: { step: 2, step_name: "photos" },
  signup_completed: {},
  paywall_viewed: { source: "likes" },
  purchase_moment_shown: { moment: "dailyLikeLimit" },
  purchase_moment_accepted: { moment: "undoRefused" },
  purchase_moment_dismissed: { moment: "firstMatch" },
  purchase_started: { product_id: "com.mazl.plus.monthly" },
  purchase_cancelled: { product_id: "com.mazl.plus.monthly" },
  analytics_consent_granted: {},
};

const NOW = new Date("2026-10-26T12:00:00Z");

describe("client events: an allowlist", () => {
  test("the accepted names are exactly those of the plan", () => {
    expect([...CLIENT_EVENT_NAMES].sort()).toEqual(Object.keys(PLAN_CLIENT_EVENTS).sort());
  });

  for (const [name, properties] of Object.entries(PLAN_CLIENT_EVENTS)) {
    test(`${name} keeps exactly the properties of the plan`, () => {
      const event = parseClientEvent({ name, properties, at: "2026-10-26T11:59:00Z" }, NOW);
      expect(event).not.toBeNull();
      expect(event?.properties).toEqual(properties);
      expect(event?.at.toISOString()).toBe("2026-10-26T11:59:00.000Z");
    });
  }

  test("an unknown event is refused", () => {
    expect(parseClientEvent({ name: "religion_selected", properties: {} }, NOW)).toBeNull();
    expect(parseClientEvent({ name: "message_sent", properties: {} }, NOW)).toBeNull();
  });

  test("an unknown property is removed, never forwarded", () => {
    const event = parseClientEvent(
      { name: "screen_viewed", properties: { screen: "chat", email: "jeanne@example.com", denomination: "massorti", text: "Shalom" } },
      NOW,
    );
    expect(event?.properties).toEqual({ screen: "chat" });
  });

  test("a screen that is a path, an e-mail or free text refuses the event", () => {
    for (const screen of ["/profile/42", "jeanne@example.com", "Jeanne Exemple", "chat?id=4", "", "x".repeat(41), 42]) {
      expect(parseClientEvent({ name: "screen_viewed", properties: { screen } }, NOW)).toBeNull();
    }
  });

  test("a purchase moment is one of the five of the plan, nothing else", () => {
    for (const moment of ["dailyLikeLimit", "thirdLikeReceived", "undoRefused", "passportAttempt", "firstMatch"]) {
      expect(parseClientEvent({ name: "purchase_moment_shown", properties: { moment } }, NOW)?.properties).toEqual({ moment });
    }
    for (const moment of ["jeanne@example.com", "/likes", "madeUp", "", 3]) {
      expect(parseClientEvent({ name: "purchase_moment_shown", properties: { moment } }, NOW)).toBeNull();
    }
  });

  test("a missing property refuses the event", () => {
    expect(parseClientEvent({ name: "screen_viewed", properties: {} }, NOW)).toBeNull();
    expect(parseClientEvent({ name: "onboarding_step_viewed", properties: { step: 1 } }, NOW)).toBeNull();
  });

  test("a step must be a whole number from 0 to 30", () => {
    for (const step of [-1, 31, 1.5, "2"]) {
      expect(parseClientEvent({ name: "onboarding_step_viewed", properties: { step, step_name: "photos" } }, NOW)).toBeNull();
    }
  });

  test("a product id with spaces or capitals refuses the event", () => {
    for (const product_id of ["Plus Monthly", "COM.MAZL", "a@b", "x".repeat(81)]) {
      expect(parseClientEvent({ name: "purchase_started", properties: { product_id } }, NOW)).toBeNull();
    }
  });

  test("the time: missing or in the future becomes now, older than a day is refused", () => {
    expect(parseClientEvent({ name: "app_opened" }, NOW)?.at).toEqual(NOW);
    expect(parseClientEvent({ name: "app_opened", at: "2026-10-27T12:00:00Z" }, NOW)?.at).toEqual(NOW);
    expect(parseClientEvent({ name: "app_opened", at: "not a date" }, NOW)?.at).toEqual(NOW);
    expect(parseClientEvent({ name: "app_opened", at: "2026-10-25T11:00:00Z" }, NOW)).toBeNull();
  });

  test("anything that is not an object is refused", () => {
    for (const raw of [null, "app_opened", 3, [], { name: 3 }, { name: "app_opened", properties: "x" }]) {
      expect(parseClientEvent(raw, NOW)).toBeNull();
    }
  });
});

describe("client context", () => {
  test("platform and version are checked", () => {
    expect(parseClientContext({ platform: "ios", app_version: "1.0.0+12" })).toEqual({ platform: "ios", appVersion: "1.0.0+12" });
    expect(parseClientContext({ platform: "web", app_version: "1.2.3" })).toEqual({ platform: "web", appVersion: "1.2.3" });
    expect(parseClientContext({ platform: "server", app_version: "1.0.0" })).toBeNull();
    expect(parseClientContext({ platform: "ios", app_version: "iPhone de Jeanne" })).toBeNull();
    expect(parseClientContext({ platform: "ios" })).toBeNull();
  });
});

describe("server events", () => {
  test("carry only the properties of the plan", () => {
    expect(serverEvents.swipe("like", NOW)).toMatchObject({ name: "swipe", properties: { action: "like" } });
    expect(serverEvents.matchCreated("super_like", "receiver", NOW)?.properties).toEqual({ via: "super_like", role: "receiver" });
    expect(serverEvents.messageSent(NOW)?.properties).toEqual({});
    expect(serverEvents.subscriptionValidated("com.mazl.plus.monthly", "monthly", NOW)?.properties).toEqual({
      kind: "subscription",
      product_id: "com.mazl.plus.monthly",
      plan_type: "monthly",
    });
    expect(serverEvents.consumableValidated("super_like", NOW)?.properties).toEqual({ kind: "consumable", product: "super_like" });
    expect(serverEvents.verificationSubmitted("face", "approved", NOW)?.properties).toEqual({ step: "face", outcome: "approved" });
  });

  test("an unexpected value from another feature is dropped, not forwarded", () => {
    expect(serverEvents.subscriptionValidated("Plus de Jeanne", "monthly", NOW)).toBeNull();
    expect(serverEvents.consumableValidated("jeanne@example.com", NOW)).toBeNull();
  });
});
