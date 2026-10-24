import { createHash, createHmac } from "node:crypto";
import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Integration against a real server started with WEB_POW_DIFFICULTY=8, no
// WEB_ORIGIN, no GOOGLE_CLIENT_ID and no APPLE_WEB_SERVICES_ID.

const COOKIE = "__Host-mazl_web";
const WS_URL = BASE_URL.replace(/^http/, "ws") + "/ws";

// `db` is the client shared by every integration file of the run
// (media-helpers): closing it here broke the files that run after this one.

interface Pow { challenge: string; nonce: string }

function zeroBits(hex: string): number {
  let bits = 0;
  for (const char of hex) {
    const nibble = Number.parseInt(char, 16);
    if (nibble === 0) bits += 4;
    else return bits + Math.clz32(nibble) - 28;
  }
  return bits;
}

async function solvePow(): Promise<Pow> {
  const res = await fetch(`${BASE_URL}/api/web/auth/challenge`, { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" });
  const body = (await res.json()) as { success: boolean; challenge: string; difficulty: number };
  expect(body.success).toBe(true);
  for (let n = 0; ; n++) {
    const digest = createHash("sha256").update(`${body.challenge}:${n}`).digest("hex");
    if (zeroBits(digest) >= body.difficulty) return { challenge: body.challenge, nonce: String(n) };
  }
}

interface Pairing { id: string; code: string; browser_secret: string; expires_at: string }

async function openPairing(userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/130.0.0.0 Safari/537.36"): Promise<Pairing> {
  const res = await fetch(`${BASE_URL}/api/web/auth/qr`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "User-Agent": userAgent },
    body: JSON.stringify({ pow: await solvePow() }),
  });
  expect(res.status).toBe(200);
  return ((await res.json()) as { pairing: Pairing }).pairing;
}

const poll = (p: Pairing) => fetch(`${BASE_URL}/api/web/auth/qr/${p.id}`, { headers: { "X-Pairing-Secret": p.browser_secret } });
const scan = (token: string, code: string) =>
  fetch(`${BASE_URL}/api/web/pairings/scan`, { method: "POST", headers: json(token), body: JSON.stringify({ code }) });
const decide = (token: string, id: string, verb: "approve" | "deny") =>
  fetch(`${BASE_URL}/api/web/pairings/${id}/${verb}`, { method: "POST", headers: json(token) });

interface WebBrowser { cookie: string; get(path: string): Promise<Response>; send(method: string, path: string, body?: unknown): Promise<Response> }

function browserWith(cookie: string, bridged = true): WebBrowser {
  const base: Record<string, string> = { Cookie: `${COOKIE}=${cookie}` };
  if (bridged) base["X-Mazl-Web"] = "1";
  return {
    cookie,
    get: (path) => fetch(`${BASE_URL}${path}`, { headers: base }),
    send: (method, path, body) =>
      fetch(`${BASE_URL}${path}`, {
        method,
        headers: { ...base, Origin: BASE_URL, "Content-Type": "application/json" },
        body: body === undefined ? undefined : JSON.stringify(body),
      }),
  };
}

async function signInByQr(user: TestUser): Promise<{ browser: WebBrowser; setCookie: string }> {
  const pairing = await openPairing();
  expect((await scan(user.token, pairing.code)).status).toBe(200);
  expect((await decide(user.token, pairing.id, "approve")).status).toBe(200);
  const res = await poll(pairing);
  const setCookie = res.headers.get("set-cookie") ?? "";
  const value = new RegExp(`${COOKIE}=([^;]+)`).exec(setCookie)?.[1];
  if (!value) throw new Error(`no cookie in ${setCookie}`);
  return { browser: browserWith(value), setCookie };
}

describe("QR sign-in", () => {
  test("browser asks, phone scans and approves, cookie opens the API (and only with X-Mazl-Web)", async () => {
    const user = await makeUser("qr");
    const pairing = await openPairing();
    expect(new Date(pairing.expires_at).getTime() - Date.now()).toBeGreaterThan(100_000);

    expect(((await (await poll(pairing)).json()) as { status: string }).status).toBe("pending");

    const scanned = (await (await scan(user.token, pairing.code)).json()) as { pairing: { id: string; browser: string } };
    expect(scanned.pairing.id).toBe(pairing.id);
    expect(scanned.pairing.browser).toBe("Chrome sur macOS");
    expect(((await (await poll(pairing)).json()) as { status: string }).status).toBe("scanned");

    expect((await decide(user.token, pairing.id, "approve")).status).toBe(200);
    const res = await poll(pairing);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { status: string; user: { id: number } };
    expect(body.status).toBe("approved");
    expect(body.user.id).toBe(user.id);

    const setCookie = res.headers.get("set-cookie") ?? "";
    for (const attribute of ["HttpOnly", "Secure", "SameSite=Strict", "Path=/"]) expect(setCookie).toContain(attribute);
    expect(setCookie).not.toContain("Domain");
    expect(setCookie.startsWith(`${COOKIE}=`)).toBe(true);
    const maxAge = Number(/Max-Age=(\d+)/.exec(setCookie)?.[1]);
    expect(maxAge).toBeGreaterThan(7 * 86400 - 60);
    expect(maxAge).toBeLessThanOrEqual(7 * 86400);

    const cookie = new RegExp(`${COOKIE}=([^;]+)`).exec(setCookie)?.[1] ?? "";
    expect((await browserWith(cookie).get("/api/matches")).status).toBe(200);
    expect((await browserWith(cookie, false).get("/api/matches")).status).toBe(401);

    const me = (await (await browserWith(cookie).get("/api/web/session")).json()) as {
      session: { browser: string; method: string }; user: { id: number };
    };
    expect(me.session).toMatchObject({ browser: "Chrome sur macOS", method: "qr" });
    expect(me.user.id).toBe(user.id);
    expect((await browserWith(cookie, false).get("/api/web/session")).status).toBe(401);

    // Single use: a second read finds nothing to sign in with.
    expect(((await (await poll(pairing)).json()) as { status: string }).status).toBe("expired");
  });

  test("a wrong secret or unknown id is a 404", async () => {
    const pairing = await openPairing();
    const wrong = await fetch(`${BASE_URL}/api/web/auth/qr/${pairing.id}`, { headers: { "X-Pairing-Secret": "nope" } });
    expect(wrong.status).toBe(404);
    expect(((await wrong.json()) as { error: string }).error).toBe("not_found");
    expect((await fetch(`${BASE_URL}/api/web/auth/qr/${pairing.id}`)).status).toBe(404);
    const unknown = await fetch(`${BASE_URL}/api/web/auth/qr/not-a-uuid`, { headers: { "X-Pairing-Secret": pairing.browser_secret } });
    expect(unknown.status).toBe(404);
  });

  test("a refusal is visible to the browser and gives no cookie", async () => {
    const user = await makeUser("deny");
    const pairing = await openPairing();
    await scan(user.token, pairing.code);
    expect((await decide(user.token, pairing.id, "deny")).status).toBe(200);
    const res = await poll(pairing);
    expect(((await res.json()) as { status: string }).status).toBe("denied");
    expect(res.headers.get("set-cookie")).toBeNull();
  });

  test("another member cannot approve, and a pairing must be scanned first", async () => {
    const owner = await makeUser("owner");
    const stranger = await makeUser("stranger");
    const pairing = await openPairing();
    expect((await decide(owner.token, pairing.id, "approve")).status).toBe(404);
    await scan(owner.token, pairing.code);
    expect((await decide(stranger.token, pairing.id, "approve")).status).toBe(404);
    expect((await scan(stranger.token, pairing.code)).status).toBe(404);
    expect((await decide(owner.token, pairing.id, "approve")).status).toBe(200);
  });

  test("an expired pairing reads as expired and cannot be scanned or approved", async () => {
    const user = await makeUser("expiry");
    const scannedLate = await openPairing();
    await scan(user.token, scannedLate.code);
    const neverScanned = await openPairing();
    await db`UPDATE web_pairings SET expires_at = NOW() - INTERVAL '1 second' WHERE id IN (${scannedLate.id}, ${neverScanned.id})`;

    expect(((await (await poll(scannedLate)).json()) as { status: string }).status).toBe("expired");
    const approve = await decide(user.token, scannedLate.id, "approve");
    expect(approve.status).toBe(409);
    expect(((await approve.json()) as { error: string }).error).toBe("pairing_not_pending");
    const late = await scan(user.token, neverScanned.code);
    expect(late.status).toBe(404);
    expect(((await late.json()) as { error: string }).error).toBe("pairing_not_found");
  });

  test("an approval read after the deadline gives no session", async () => {
    const user = await makeUser("late");
    const pairing = await openPairing();
    await scan(user.token, pairing.code);
    await decide(user.token, pairing.id, "approve");
    await db`UPDATE web_pairings SET expires_at = NOW() - INTERVAL '1 second' WHERE id = ${pairing.id}`;
    const res = await poll(pairing);
    expect(((await res.json()) as { status: string }).status).toBe("expired");
    expect(res.headers.get("set-cookie")).toBeNull();
  });

  test("scanning needs a code in the body", async () => {
    const user = await makeUser("badscan");
    const res = await fetch(`${BASE_URL}/api/web/pairings/scan`, { method: "POST", headers: json(user.token), body: "{}" });
    expect(res.status).toBe(400);
    expect((await fetch(`${BASE_URL}/api/web/pairings/scan`, { method: "POST", body: "{}" })).status).toBe(401);
  });
});

describe("a web session cannot approve sign-ins", () => {
  test("scan, approve and deny answer 403 web_session_forbidden", async () => {
    const user = await makeUser("forbidden");
    const { browser } = await signInByQr(user);
    const pairing = await openPairing();
    await scan(user.token, pairing.code);

    for (const [path, body] of [
      ["/api/web/pairings/scan", { code: pairing.code }],
      [`/api/web/pairings/${pairing.id}/approve`, undefined],
      [`/api/web/pairings/${pairing.id}/deny`, undefined],
    ] as const) {
      const res = await browser.send("POST", path, body);
      expect(res.status).toBe(403);
      expect(((await res.json()) as { error: string }).error).toBe("web_session_forbidden");
    }
    // The pairing is untouched and the phone can still approve it.
    expect((await decide(user.token, pairing.id, "approve")).status).toBe(200);
  });

  test("a forged internal header from outside does not unlock or lock anything", async () => {
    const user = await makeUser("spoof");
    const pairing = await openPairing();
    await scan(user.token, pairing.code);
    const res = await fetch(`${BASE_URL}/api/web/pairings/${pairing.id}/approve`, {
      method: "POST",
      headers: { ...json(user.token), "X-Mazl-Web-Session": "11111111-1111-4111-8111-111111111111" },
    });
    expect(res.status).toBe(200);
    const asWeb = await fetch(`${BASE_URL}/api/web/session`, { headers: { "X-Mazl-Web-Session": "11111111-1111-4111-8111-111111111111" } });
    expect(asWeb.status).toBe(401);
  });
});

describe("cross-site protection", () => {
  test("a POST from another origin is not bridged", async () => {
    const { browser } = await signInByQr(await makeUser("csrf"));
    const res = await fetch(`${BASE_URL}/api/web/auth/logout`, {
      method: "POST",
      headers: { Cookie: `${COOKIE}=${browser.cookie}`, "X-Mazl-Web": "1", Origin: "https://evil.example.net", "Content-Type": "application/json" },
      body: "{}",
    });
    expect(res.status).toBe(403);
    // The cross-site logout did nothing: the session still works.
    expect((await browser.get("/api/matches")).status).toBe(200);
  });
});

// Resolves "open" if the socket opened, "refused" if the upgrade was refused.
function socketOutcome(token: string): Promise<"open" | "refused"> {
  return new Promise((resolve) => {
    const socket = new WebSocket(`${WS_URL}?token=${encodeURIComponent(token)}`);
    socket.onopen = () => { socket.close(); resolve("open"); };
    socket.onerror = () => resolve("refused");
  });
}

function signedToken(claims: Record<string, unknown>): string {
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(claims)).toString("base64url");
  const secret = process.env.JWT_SECRET ?? "";
  return `${header}.${body}.${createHmac("sha256", secret).update(`${header}.${body}`).digest("base64url")}`;
}

describe("sign-in cannot be forged from another site (security review M1)", () => {
  // A cross-site HTML form may POST text/plain with any body: Hono would read it
  // as JSON. And a request that says it comes from another origin is refused.
  const post = (path: string, body: string, headers: Record<string, string>) =>
    fetch(`${BASE_URL}${path}`, { method: "POST", headers: { "x-forwarded-for": `198.51.100.${Math.floor(Math.random() * 200) + 1}`, ...headers }, body });

  test("a sign-in sent as text/plain, like a form of another site, is refused", async () => {
    const pow = await solvePow();
    for (const path of ["/api/web/auth/google", "/api/web/auth/apple", "/api/web/auth/qr"]) {
      const res = await post(path, JSON.stringify({ idToken: "x", identityToken: "x", pow }), { "Content-Type": "text/plain" });
      expect(res.status).toBe(415);
      expect(((await res.json()) as { error: string }).error).toBe("json_required");
    }
  });

  test("a sign-in whose Origin is another site is refused", async () => {
    const pow = await solvePow();
    for (const path of ["/api/web/auth/google", "/api/web/auth/qr", "/api/web/auth/challenge", "/api/web/auth/logout"]) {
      const res = await post(path, JSON.stringify({ idToken: "x", pow }), { "Content-Type": "application/json", Origin: "https://evil.example" });
      expect(res.status).toBe(403);
      expect(((await res.json()) as { error: string }).error).toBe("wrong_origin");
    }
  });

  test("the site's own JSON requests still go through", async () => {
    const res = await post("/api/web/auth/challenge", "{}", { "Content-Type": "application/json", Origin: BASE_URL });
    expect(res.status).toBe(200);
  });
});

describe("the phone sees where the request comes from (security review B6)", () => {
  test("the scan answers the browser and its masked address", async () => {
    const user = await makeUser("ip-hint");
    const res = await fetch(`${BASE_URL}/api/web/auth/qr`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Forwarded-For": "198.51.100.42" },
      body: JSON.stringify({ pow: await solvePow() }),
    });
    const { pairing } = (await res.json()) as { pairing: Pairing };
    const scan = await fetch(`${BASE_URL}/api/web/pairings/scan`, { method: "POST", headers: json(user.token), body: JSON.stringify({ code: pairing.code }) });
    expect(((await scan.json()) as { pairing: { address: string | null } }).pairing.address).toBe("198.51.100.x");
  });
});

describe("socket tickets are not API tokens (security review H1)", () => {
  test("a ticket used as a Bearer token is refused, so it cannot approve a sign-in", async () => {
    const user = await makeUser("ticket-bearer");
    const { browser } = await signInByQr(user);
    const { token } = (await (await browser.send("POST", "/api/web/socket-ticket")).json()) as { token: string };
    const victimPairing = await openPairing();
    const scan = await fetch(`${BASE_URL}/api/web/pairings/scan`, { method: "POST", headers: json(token), body: JSON.stringify({ code: victimPairing.code }) });
    expect(scan.status).toBe(401);
    expect((await fetch(`${BASE_URL}/api/matches`, { headers: auth(token) })).status).toBe(401);
  });

  test("a ticket opens one socket, once", async () => {
    const user = await makeUser("ticket-once");
    const { browser } = await signInByQr(user);
    const { token } = (await (await browser.send("POST", "/api/web/socket-ticket")).json()) as { token: string };
    expect(await socketOutcome(token)).toBe("open");
    expect(await socketOutcome(token)).toBe("refused");
  });

  test("a token minted for the web bridge cannot scan nor approve a pairing", async () => {
    const user = await makeUser("bridge-aud");
    const bridgeToken = signedToken({ sub: String(user.id), email: "x@example.com", exp: Math.floor(Date.now() / 1000) + 60, aud: "web-bridge", sid: crypto.randomUUID() });
    expect((await fetch(`${BASE_URL}/api/matches`, { headers: auth(bridgeToken) })).status).toBe(200);
    const pairing = await openPairing();
    const scan = await fetch(`${BASE_URL}/api/web/pairings/scan`, { method: "POST", headers: json(bridgeToken), body: JSON.stringify({ code: pairing.code }) });
    expect(scan.status).toBe(403);
    expect(((await scan.json()) as { error: string }).error).toBe("web_session_forbidden");
  });
});

describe("listing and revoking from the phone", () => {
  test("revoking stops the next web request and closes the session's socket with 4003", async () => {
    const user = await makeUser("revoke");
    const { browser } = await signInByQr(user);

    const list = (await (await fetch(`${BASE_URL}/api/web/sessions`, { headers: auth(user.token) })).json()) as {
      sessions: Array<{ id: string; browser: string; method: string; current: boolean }>;
    };
    expect(list.sessions).toHaveLength(1);
    expect(list.sessions[0]).toMatchObject({ browser: "Chrome sur macOS", method: "qr", current: false });
    const sessionId = list.sessions[0]?.id ?? "";
    const fromWeb = (await (await browser.get("/api/web/sessions")).json()) as { sessions: Array<{ current: boolean }> };
    expect(fromWeb.sessions[0]?.current).toBe(true);

    const ticket = (await (await browser.send("POST", "/api/web/socket-ticket")).json()) as { token: string; expires_at: string };
    expect(new Date(ticket.expires_at).getTime() - Date.now()).toBeLessThanOrEqual(60_000);
    const closed = await new Promise<{ code: number; reason: string }>((resolve, reject) => {
      const socket = new WebSocket(`${WS_URL}?token=${ticket.token}`);
      const timer = setTimeout(() => reject(new Error("socket never closed")), 8000);
      socket.onopen = () => {
        void fetch(`${BASE_URL}/api/web/sessions/${sessionId}`, { method: "DELETE", headers: auth(user.token) });
      };
      socket.onclose = (event) => {
        clearTimeout(timer);
        resolve({ code: event.code, reason: event.reason });
      };
      socket.onerror = () => reject(new Error("socket error"));
    });
    expect(closed).toEqual({ code: 4003, reason: "session_revoked" });

    const after = await browser.get("/api/matches");
    expect(after.status).toBe(401);
    expect((await browser.get("/api/web/session")).status).toBe(401);
    // A ticket opens one socket: used again, after the revocation, it opens nothing.
    expect(await socketOutcome(ticket.token)).toBe("refused");
  });

  test("a member cannot revoke someone else's session; unknown ids are 404", async () => {
    const a = await makeUser("rev-a");
    const b = await makeUser("rev-b");
    await signInByQr(a);
    const sessionId = ((await (await fetch(`${BASE_URL}/api/web/sessions`, { headers: auth(a.token) })).json()) as {
      sessions: Array<{ id: string }>;
    }).sessions[0]?.id ?? "";
    const other = await fetch(`${BASE_URL}/api/web/sessions/${sessionId}`, { method: "DELETE", headers: auth(b.token) });
    expect(other.status).toBe(404);
    expect(((await other.json()) as { error: string }).error).toBe("not_found");
    expect((await fetch(`${BASE_URL}/api/web/sessions/not-a-uuid`, { method: "DELETE", headers: auth(a.token) })).status).toBe(404);
    const stillThere = (await (await fetch(`${BASE_URL}/api/web/sessions`, { headers: auth(a.token) })).json()) as { sessions: unknown[] };
    expect(stillThere.sessions).toHaveLength(1);
  });

  test("others=true keeps the calling web session, no filter revokes all", async () => {
    const user = await makeUser("others");
    const first = (await signInByQr(user)).browser;
    const second = (await signInByQr(user)).browser;
    const third = (await signInByQr(user)).browser;

    const res = await second.send("DELETE", "/api/web/sessions?others=true");
    expect(res.status).toBe(200);
    expect((await first.get("/api/matches")).status).toBe(401);
    expect((await third.get("/api/matches")).status).toBe(401);
    expect((await second.get("/api/matches")).status).toBe(200);

    expect((await fetch(`${BASE_URL}/api/web/sessions`, { method: "DELETE", headers: auth(user.token) })).status).toBe(200);
    expect((await second.get("/api/matches")).status).toBe(401);
  });

  test("logout revokes the session and clears the cookie; without a session it still answers 200", async () => {
    const { browser } = await signInByQr(await makeUser("logout"));
    const res = await browser.send("POST", "/api/web/auth/logout");
    expect(res.status).toBe(200);
    expect(res.headers.get("set-cookie")).toContain("Max-Age=0");
    expect((await browser.get("/api/matches")).status).toBe(401);
    const bare = await fetch(`${BASE_URL}/api/web/auth/logout`, { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" });
    expect(bare.status).toBe(200);
  });
});

describe("proof of work", () => {
  test("a solved challenge works once; replay, forgery and a missing proof are refused", async () => {
    const pow = await solvePow();
    const send = (body: unknown) =>
      fetch(`${BASE_URL}/api/web/auth/qr`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });

    expect((await send({ pow })).status).toBe(200);
    const replay = await send({ pow });
    expect(replay.status).toBe(403);
    expect(((await replay.json()) as { error: string }).error).toBe("pow_invalid");

    const fresh = await solvePow();
    const [encoded, signature] = fresh.challenge.split(".") as [string, string];
    const lowered = Buffer.from(JSON.stringify({ ...JSON.parse(Buffer.from(encoded, "base64url").toString()), d: 0 })).toString("base64url");
    expect((await send({ pow: { challenge: `${lowered}.${signature}`, nonce: "0" } })).status).toBe(403);

    const bad = await send({});
    expect(bad.status).toBe(400);
    expect(((await bad.json()) as { error: string }).error).toBe("invalid_body");
  });

  test("a nonce that does not do the work is refused", async () => {
    const { challenge } = await solvePow();
    let nonce = 0;
    while (zeroBits(createHash("sha256").update(`${challenge}:${nonce}`).digest("hex")) >= 8) nonce++;
    const res = await fetch(`${BASE_URL}/api/web/auth/qr`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ pow: { challenge, nonce: String(nonce) } }),
    });
    expect(res.status).toBe(403);
  });
});

describe("Google and Apple", () => {
  test("a fake Google token is a 401 invalid_token", async () => {
    const res = await fetch(`${BASE_URL}/api/web/auth/google`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken: "not.a.real.token", pow: await solvePow() }),
    });
    expect(res.status).toBe(401);
    expect(((await res.json()) as { error: string }).error).toBe("invalid_token");
    expect(res.headers.get("set-cookie")).toBeNull();
  });

  test("Google without a proof of work is refused before the token is looked at", async () => {
    const res = await fetch(`${BASE_URL}/api/web/auth/google`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken: "x", pow: { challenge: "a.b", nonce: "1" } }),
    });
    expect(res.status).toBe(403);
    expect(((await res.json()) as { error: string }).error).toBe("pow_invalid");
  });

  test("Apple is unavailable without APPLE_WEB_SERVICES_ID", async () => {
    const res = await fetch(`${BASE_URL}/api/web/auth/apple`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: "x", pow: await solvePow() }),
    });
    expect(res.status).toBe(503);
    expect(((await res.json()) as { error: string }).error).toBe("apple_unavailable");
  });

  test("the public config exposes the difficulty and no secret", async () => {
    const body = (await (await fetch(`${BASE_URL}/api/web/auth/config`)).json()) as Record<string, unknown>;
    expect(body).toEqual({ success: true, google_client_id: null, apple_services_id: null, pow_difficulty: 8 });
  });
});

describe("account removal", () => {
  test("sessions and pairings disappear with the account", async () => {
    const user = await makeUser("cascade");
    await signInByQr(user);
    const before = await db`SELECT count(*)::int AS n FROM web_sessions WHERE user_id = ${user.id}`;
    expect(before[0]?.n).toBe(1);
    await db`DELETE FROM users WHERE id = ${user.id}`;
    const after = await db`SELECT count(*)::int AS n FROM web_sessions WHERE user_id = ${user.id}`;
    expect(after[0]?.n).toBe(0);
  });
});
