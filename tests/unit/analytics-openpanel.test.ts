import { describe, expect, test } from "bun:test";
import type { OutgoingEvent } from "../../src/features/analytics/application/ports";
import { HmacPseudonymizer } from "../../src/features/analytics/infra/hmac-pseudonymizer";
import { OpenPanelSink } from "../../src/features/analytics/infra/openpanel-sink";

interface Captured {
  readonly url: string;
  readonly headers: Record<string, string>;
  readonly body: { type: string; payload: { name: string; profileId: string; properties: Record<string, unknown> } };
}

function capture(status = 202): { calls: Captured[]; fetcher: typeof fetch } {
  const calls: Captured[] = [];
  const fetcher = ((url: string | URL | Request, init?: RequestInit) => {
    calls.push({
      url: String(url),
      headers: Object.fromEntries(new Headers(init?.headers).entries()),
      body: JSON.parse(String(init?.body)) as Captured["body"],
    });
    return Promise.resolve(new Response("{}", { status }));
  }) as typeof fetch;
  return { calls, fetcher };
}

const config = { apiUrl: "https://op.example.com/", clientId: "client-id-example", clientSecret: "client-secret-example" };

const event = (overrides: Partial<OutgoingEvent>): OutgoingEvent => ({
  profileId: "a".repeat(32),
  name: "app_opened",
  properties: { platform: "ios", app_version: "1.0.0", env: "production" },
  at: new Date("2026-10-26T11:58:00Z"),
  platform: "ios",
  ...overrides,
});

describe("OpenPanel sink", () => {
  test("posts a track event with the client credentials, the pseudonym and no IP", async () => {
    const { calls, fetcher } = capture();
    await new OpenPanelSink(config, fetcher).send([event({})]);
    expect(calls).toHaveLength(1);
    const [call] = calls;
    expect(call?.url).toBe("https://op.example.com/track");
    expect(call?.headers["openpanel-client-id"]).toBe("client-id-example");
    expect(call?.headers["openpanel-client-secret"]).toBe("client-secret-example");
    expect(call?.headers["user-agent"]).toContain("iPhone");
    expect(call?.headers["x-client-ip"]).toBeUndefined();
    expect(call?.body).toEqual({
      type: "track",
      payload: {
        name: "app_opened",
        profileId: "a".repeat(32),
        properties: {
          platform: "ios",
          app_version: "1.0.0",
          env: "production",
          __deviceId: "a".repeat(32),
          __timestamp: "2026-10-26T11:58:00.000Z",
          __ip: "127.0.0.1",
        },
      },
    });
  });

  test("a viewed screen becomes OpenPanel's own screen_view, so its Pages report works", async () => {
    const { calls, fetcher } = capture();
    await new OpenPanelSink(config, fetcher).send([event({ name: "screen_viewed", properties: { screen: "discover" } })]);
    expect(calls[0]?.body.payload.name).toBe("screen_view");
    expect(calls[0]?.body.payload.properties).toMatchObject({ screen: "discover", __path: "/discover", __title: "discover" });
  });

  test("a server event says so (no device, no session)", async () => {
    const { calls, fetcher } = capture();
    await new OpenPanelSink(config, fetcher).send([event({ name: "match_created", platform: "server" })]);
    expect(calls[0]?.headers["user-agent"]).toBe("mazl-api/1.0");
    expect(calls[0]?.body.payload.properties.__deviceId).toBeUndefined();
  });

  test("a refusal from OpenPanel rejects, without the secret in the message", async () => {
    const { fetcher } = capture(401);
    const attempt = new OpenPanelSink(config, fetcher).send([event({})]);
    await expect(attempt).rejects.toThrow("OpenPanel answered 401");
    await attempt.catch((error: unknown) => expect(String(error)).not.toContain("client-secret-example"));
  });
});

describe("pseudonym", () => {
  const key = "k".repeat(32);

  test("stable, 32 hex characters, never the id itself", () => {
    const pseudonyms = new HmacPseudonymizer(key);
    const id = pseudonyms.profileIdOf(42);
    expect(id).toMatch(/^[0-9a-f]{32}$/);
    expect(pseudonyms.profileIdOf(42)).toBe(id);
    expect(id).not.toContain("42");
    expect(pseudonyms.profileIdOf(43)).not.toBe(id);
  });

  test("depends on the key", () => {
    expect(new HmacPseudonymizer(key).profileIdOf(42)).not.toBe(new HmacPseudonymizer("z".repeat(32)).profileIdOf(42));
  });

  test("refuses a short key", () => {
    expect(() => new HmacPseudonymizer("short")).toThrow();
  });
});
