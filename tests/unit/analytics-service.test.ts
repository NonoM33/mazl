import { describe, expect, test } from "bun:test";
import { AnalyticsService } from "../../src/features/analytics/application/analytics-service";
import type { AnalyticsSink, OutgoingEvent } from "../../src/features/analytics/application/ports";
import { serverEvents } from "../../src/features/analytics/domain/events";

const NOW = new Date("2026-10-26T12:00:00Z");

class RecordingSink implements AnalyticsSink {
  readonly sent: OutgoingEvent[] = [];
  failing = false;

  send(events: readonly OutgoingEvent[]): Promise<void> {
    if (this.failing) return Promise.reject(new Error("openpanel down"));
    this.sent.push(...events);
    return Promise.resolve();
  }
}

interface Setup {
  readonly sink: RecordingSink;
  readonly consenting: Set<number>;
  readonly lookups: number[];
  readonly service: AnalyticsService;
  advance(ms: number): void;
}

function setup(options: { enabled?: boolean } = {}): Setup {
  const sink = new RecordingSink();
  const consenting = new Set<number>();
  const lookups: number[] = [];
  let now = NOW.getTime();
  const service = new AnalyticsService({
    sink: options.enabled === false ? null : sink,
    pseudonyms: { profileIdOf: (userId) => `p${String(userId).padStart(31, "0")}` },
    allowsAnalytics: (userId) => {
      lookups.push(userId);
      return Promise.resolve(consenting.has(userId));
    },
    environment: "staging",
    clock: () => new Date(now),
    consentTtlMs: 60_000,
  });
  return { sink, consenting, lookups, service, advance: (ms) => (now += ms) };
}

const flush = (): Promise<void> => new Promise((resolve) => setTimeout(resolve, 0));
const ios = { platform: "ios" as const, appVersion: "1.0.0+3" };

describe("client events", () => {
  test("without consent nothing is sent, and the caller is told none was accepted", async () => {
    const { sink, service } = setup();
    expect(await service.recordClientEvents(42, ios, [{ name: "app_opened" }])).toBe(0);
    await flush();
    expect(sink.sent).toEqual([]);
  });

  test("with consent: pseudonymous profile, common properties, the device time kept", async () => {
    const { sink, consenting, service } = setup();
    consenting.add(42);
    const accepted = await service.recordClientEvents(42, ios, [
      { name: "screen_viewed", properties: { screen: "discover" }, at: "2026-10-26T11:58:00Z" },
      { name: "religion_selected", properties: {} },
    ]);
    await flush();
    expect(accepted).toBe(1);
    expect(sink.sent).toEqual([
      {
        profileId: "p0000000000000000000000000000042",
        name: "screen_viewed",
        properties: { screen: "discover", platform: "ios", app_version: "1.0.0+3", env: "staging" },
        at: new Date("2026-10-26T11:58:00Z"),
        platform: "ios",
      },
    ]);
    expect(JSON.stringify(sink.sent)).not.toContain('"42"');
  });

  test("a withdrawal is honoured at once: the cached consent is forgotten", async () => {
    const { sink, consenting, service } = setup();
    consenting.add(42);
    await service.recordClientEvents(42, ios, [{ name: "app_opened" }]);
    consenting.delete(42);
    service.forgetConsent(42);
    expect(await service.recordClientEvents(42, ios, [{ name: "app_opened" }])).toBe(0);
    await flush();
    expect(sink.sent).toHaveLength(1);
  });

  test("the consent is looked up again once its cache has expired", async () => {
    const { consenting, lookups, service, advance } = setup();
    consenting.add(42);
    await service.recordClientEvents(42, ios, [{ name: "app_opened" }]);
    await service.recordClientEvents(42, ios, [{ name: "app_opened" }]);
    expect(lookups).toEqual([42]);
    advance(61_000);
    await service.recordClientEvents(42, ios, [{ name: "app_opened" }]);
    expect(lookups).toEqual([42, 42]);
  });

  test("OpenPanel failing never fails the member's request", async () => {
    const { sink, consenting, service } = setup();
    consenting.add(42);
    sink.failing = true;
    expect(await service.recordClientEvents(42, ios, [{ name: "app_opened" }])).toBe(1);
    await flush();
  });

  test("disabled (no OpenPanel configured): nothing sent, no consent lookup", async () => {
    const { lookups, service } = setup({ enabled: false });
    expect(await service.recordClientEvents(42, ios, [{ name: "app_opened" }])).toBe(0);
    expect(lookups).toEqual([]);
  });
});

describe("server events", () => {
  test("sent only for a consenting member, tagged server", async () => {
    const { sink, consenting, service } = setup();
    consenting.add(1);
    service.recordServerEvent(1, serverEvents.matchCreated("like", "initiator", NOW));
    service.recordServerEvent(2, serverEvents.matchCreated("like", "receiver", NOW));
    service.recordServerEvent(1, null);
    await flush();
    await flush();
    expect(sink.sent.map((event) => [event.profileId, event.name, event.properties.role, event.properties.platform])).toEqual([
      ["p0000000000000000000000000000001", "match_created", "initiator", "server"],
    ]);
  });

  test("a failing consent lookup drops the event without throwing", async () => {
    const sink = new RecordingSink();
    const service = new AnalyticsService({
      sink,
      pseudonyms: { profileIdOf: () => "p" },
      allowsAnalytics: () => Promise.reject(new Error("db down")),
      environment: "production",
      clock: () => NOW,
    });
    service.recordServerEvent(1, serverEvents.messageSent(NOW));
    await flush();
    await flush();
    expect(sink.sent).toEqual([]);
  });
});
