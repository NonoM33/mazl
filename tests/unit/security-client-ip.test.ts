import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { clientIp } from "../../src/shared/http/client-ip";

// Behind Coolify, Traefik is the TCP peer and appends the real client to
// X-Forwarded-For. Whatever the client wrote in that header comes BEFORE the
// proxy's entry, so only the last `hops` entries can be trusted.

function appWith(hops: number) {
  const app = new Hono();
  app.get("/ip", (c) => c.text(clientIp(c, hops)));
  return app;
}

const ip = async (hops: number, headers: Record<string, string>, env?: unknown) =>
  (await appWith(hops).request("/ip", { headers }, env as never)).text();

describe("client address", () => {
  test("one proxy: the entry it appended is the client, a forged prefix is ignored", async () => {
    expect(await ip(1, { "x-forwarded-for": "203.0.113.9" })).toBe("203.0.113.9");
    expect(await ip(1, { "x-forwarded-for": "1.2.3.4, 203.0.113.9" })).toBe("203.0.113.9");
    expect(await ip(1, { "x-forwarded-for": " 6.6.6.6 ,7.7.7.7,  203.0.113.9 " })).toBe("203.0.113.9");
  });

  test("two proxies: the client is the second entry from the right", async () => {
    expect(await ip(2, { "x-forwarded-for": "6.6.6.6, 203.0.113.9, 10.0.0.2" })).toBe("203.0.113.9");
  });

  test("a chain shorter than the proxies falls back to its first entry", async () => {
    expect(await ip(2, { "x-forwarded-for": "203.0.113.9" })).toBe("203.0.113.9");
  });

  test("X-Real-IP and other client-controlled headers are never trusted", async () => {
    expect(await ip(1, { "x-real-ip": "6.6.6.6", "x-forwarded-for": "203.0.113.9" })).toBe("203.0.113.9");
    expect(await ip(0, { "x-real-ip": "6.6.6.6", "x-forwarded-for": "6.6.6.6" })).toBe("unknown");
  });

  test("with no trusted proxy the socket peer is used, never the header", async () => {
    const server = { requestIP: () => ({ address: "198.51.100.4", family: "IPv4", port: 5555 }) };
    expect(await ip(0, { "x-forwarded-for": "6.6.6.6" }, { server })).toBe("198.51.100.4");
  });

  test("no header and no peer gives one shared bucket rather than a crash", async () => {
    expect(await ip(1, {})).toBe("unknown");
  });
});
