import { describe, expect, test } from "bun:test";
import { createWebAnalytics, screenNameOf, type AnalyticsBatch } from "../../web/src/features/analytics/tracker";

const NOW = new Date("2026-10-26T12:00:00Z");

function setup() {
  const batches: AnalyticsBatch[] = [];
  const analytics = createWebAnalytics({
    post: (batch) => {
      batches.push(batch);
      return Promise.resolve();
    },
    now: () => NOW,
    appVersion: "1.0.0",
  });
  return { analytics, batches };
}

describe("web analytics: consent first", () => {
  test("before any decision, events wait in memory and nothing is posted", async () => {
    const { analytics, batches } = setup();
    analytics.screen("/decouvrir");
    await analytics.flush();
    expect(batches).toEqual([]);
  });

  test("granted: the waiting events leave, after the consent event, in one web batch", async () => {
    const { analytics, batches } = setup();
    analytics.screen("/decouvrir");
    analytics.setConsent(true);
    await analytics.flush();
    expect(batches).toEqual([
      {
        platform: "web",
        app_version: "1.0.0",
        events: [
          { name: "analytics_consent_granted", properties: {}, at: NOW.toISOString() },
          { name: "screen_viewed", properties: { screen: "discover" }, at: NOW.toISOString() },
        ],
      },
    ]);
  });

  test("refused or withdrawn: the waiting events are dropped and nothing more is posted", async () => {
    const { analytics, batches } = setup();
    analytics.screen("/decouvrir");
    analytics.setConsent(false);
    analytics.screen("/likes");
    await analytics.flush();
    expect(batches).toEqual([]);
  });

  test("the same screen twice in a row counts once", async () => {
    const { analytics, batches } = setup();
    analytics.setConsent(true);
    analytics.screen("/likes");
    analytics.screen("/likes");
    await analytics.flush();
    expect(batches[0]?.events.map((event) => event.name)).toEqual(["analytics_consent_granted", "screen_viewed"]);
  });

  test("at most 100 events wait for a decision", async () => {
    const { analytics, batches } = setup();
    for (let index = 0; index < 120; index += 1) analytics.screen(index % 2 === 0 ? "/likes" : "/profil");
    analytics.setConsent(true);
    await analytics.flush();
    expect(batches.flatMap((batch) => batch.events)).toHaveLength(101);
  });

  test("a failed post keeps the events for the next flush", async () => {
    let fail = true;
    const batches: AnalyticsBatch[] = [];
    const analytics = createWebAnalytics({
      post: (batch) => (fail ? Promise.reject(new Error("offline")) : (batches.push(batch), Promise.resolve())),
      now: () => NOW,
      appVersion: "1.0.0",
    });
    analytics.setConsent(true);
    await analytics.flush();
    fail = false;
    await analytics.flush();
    expect(batches.flatMap((batch) => batch.events.map((event) => event.name))).toEqual(["analytics_consent_granted"]);
  });
});

describe("screen names: never a path or an id", () => {
  test("each route has a stable name", () => {
    expect(screenNameOf("/")).toBe("home");
    expect(screenNameOf("/decouvrir")).toBe("discover");
    expect(screenNameOf("/messages")).toBe("messages");
    expect(screenNameOf("/messages/42")).toBe("chat");
    expect(screenNameOf("/evenements/7")).toBe("eventDetail");
    expect(screenNameOf("/profil/modifier")).toBe("editProfile");
    expect(screenNameOf("/couple/calendrier")).toBe("coupleCalendar");
  });

  test("an unknown path is not tracked", () => {
    expect(screenNameOf("/inconnu/jeanne@example.com")).toBeNull();
  });
});
