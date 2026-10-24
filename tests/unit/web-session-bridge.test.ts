import { beforeEach, describe, expect, test } from "bun:test";
import { readConfig } from "../../src/features/web-session/application/config";
import { SessionService } from "../../src/features/web-session/application/session-service";
import { SocketRegistry } from "../../src/features/web-session/application/socket-registry";
import { createBridge } from "../../src/features/web-session/presentation/bridge";
import { ALICE, FakeClock, InMemoryMembers, InMemorySessions } from "./support/web-session-fakes";

const ORIGIN = "https://app.example.com";
let clock: FakeClock;
let sessions: SessionService;
let cookie: string;
let sessionId: string;

function bridgeFor(env: Record<string, string> = {}) {
  return createBridge({
    sessions,
    config: readConfig(env),
    sign: (member, ttl, claims) => `signed-${member.id}-${ttl}-${claims.aud}-${claims.sid}`,
  });
}

function request(path: string, headers: Record<string, string> = {}, method = "GET"): Request {
  return new Request(`${ORIGIN}${path}`, { method, headers: { host: "app.example.com", ...headers } });
}

const web = (extra: Record<string, string> = {}) => ({ cookie: `__Host-mazl_web=${cookie}`, "x-mazl-web": "1", ...extra });

beforeEach(async () => {
  clock = new FakeClock();
  const members = new InMemoryMembers();
  sessions = new SessionService(new InMemorySessions(members), new SocketRegistry(clock.now), clock.now);
  const opened = await sessions.open(ALICE, "qr", "Chrome sur macOS");
  cookie = opened.token;
  sessionId = opened.session.id;
});

describe("bridge", () => {
  test("turns a valid cookie plus X-Mazl-Web into a 60 s bearer for the bridge audience, and the session header", async () => {
    const req = request("/api/matches", web());
    await bridgeFor()(req);
    expect(req.headers.get("authorization")).toBe(`Bearer signed-1-60-web-bridge-${sessionId}`);
    expect(req.headers.get("x-mazl-web-session")).toBe(sessionId);
  });

  test("ignores the cookie without X-Mazl-Web (CSRF)", async () => {
    const req = request("/api/matches", { cookie: `__Host-mazl_web=${cookie}` });
    await bridgeFor()(req);
    expect(req.headers.get("authorization")).toBeNull();
    expect(req.headers.get("x-mazl-web-session")).toBeNull();
  });

  test("ignores paths outside /api/", async () => {
    const req = request("/app/connexion", web());
    await bridgeFor()(req);
    expect(req.headers.get("authorization")).toBeNull();
  });

  test("a spoofed internal header is always removed", async () => {
    for (const headers of [{ "x-mazl-web-session": "forged" }, web({ "x-mazl-web-session": "forged" })]) {
      const req = request("/api/web/pairings/x/approve", headers);
      await bridgeFor()(req);
      expect(req.headers.get("x-mazl-web-session")).not.toBe("forged");
    }
    const noCookie = request("/api/matches", { "x-mazl-web-session": "forged" });
    await bridgeFor()(noCookie);
    expect(noCookie.headers.get("x-mazl-web-session")).toBeNull();
  });

  test("leaves an existing Authorization untouched", async () => {
    const req = request("/api/matches", web({ authorization: "Bearer mobile-token" }));
    await bridgeFor()(req);
    expect(req.headers.get("authorization")).toBe("Bearer mobile-token");
    expect(req.headers.get("x-mazl-web-session")).toBeNull();
  });

  test("a POST needs the site's own Origin", async () => {
    const wrong = request("/api/swipes", web({ origin: "https://evil.example.net" }), "POST");
    await bridgeFor()(wrong);
    expect(wrong.headers.get("authorization")).toBeNull();
    const missing = request("/api/swipes", web(), "POST");
    await bridgeFor()(missing);
    expect(missing.headers.get("authorization")).toBeNull();
    const right = request("/api/swipes", web({ origin: ORIGIN }), "POST");
    await bridgeFor()(right);
    expect(right.headers.get("authorization")).toBe(`Bearer signed-1-60-web-bridge-${sessionId}`);
  });

  test("with WEB_ORIGIN, Origin must equal it and the Host must match", async () => {
    const env = { WEB_ORIGIN: ORIGIN };
    const ok = request("/api/swipes", web({ origin: ORIGIN }), "DELETE");
    await bridgeFor(env)(ok);
    expect(ok.headers.get("authorization")).not.toBeNull();
    const otherHost = request("/api/matches", web({ host: "mazl.app" }));
    await bridgeFor(env)(otherHost);
    expect(otherHost.headers.get("authorization")).toBeNull();
  });

  test("a revoked, expired or unknown session gets no bearer", async () => {
    await sessions.revoke(ALICE.id, sessionId);
    const revoked = request("/api/matches", web());
    await bridgeFor()(revoked);
    expect(revoked.headers.get("authorization")).toBeNull();
    const unknown = request("/api/matches", { cookie: "__Host-mazl_web=unknown", "x-mazl-web": "1" });
    await bridgeFor()(unknown);
    expect(unknown.headers.get("authorization")).toBeNull();
  });

  test("an idle session gets no bearer", async () => {
    clock.advance(4 * 60 * 60_000 + 1);
    const req = request("/api/matches", web());
    await bridgeFor()(req);
    expect(req.headers.get("authorization")).toBeNull();
  });
});
