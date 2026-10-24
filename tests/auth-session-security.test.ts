import { describe, expect, test } from "bun:test";
import { createHash, createHmac } from "node:crypto";
import { THROWAWAY_CREDENTIAL } from "./throwaway-credential";
import { BASE_URL, auth, db, makeUser } from "./media-helpers";

// Attacks on member sessions, replayed against a running server
// (TEST_API_URL) that shares JWT_SECRET with this process and its database
// (TEST_DATABASE_URL).

const WS_URL = process.env.TEST_WS_URL ?? `${BASE_URL.replace(/^http/, "ws")}/ws`;
const JWT_SECRET = process.env.JWT_SECRET ?? "";
const PROTECTED = `${BASE_URL}/api/matches`;

const protectedStatus = async (token: string) => (await fetch(PROTECTED, { headers: auth(token) })).status;

function memberToken(claims: Record<string, unknown>): string {
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(claims)).toString("base64url");
  return `${header}.${body}.${createHmac("sha256", JWT_SECRET).update(`${header}.${body}`).digest("base64url")}`;
}

// Resolves with the close code, or "open" if the socket opened and stayed up.
function connect(token: string): Promise<{ socket: WebSocket | null; outcome: "open" | "refused" }> {
  return new Promise((resolve) => {
    const socket = new WebSocket(`${WS_URL}?token=${encodeURIComponent(token)}`);
    socket.onopen = () => resolve({ socket, outcome: "open" });
    socket.onerror = () => resolve({ socket: null, outcome: "refused" });
  });
}

const closed = (socket: WebSocket) =>
  new Promise<number>((resolve) => {
    socket.onclose = (event) => resolve(event.code);
  });

let addressSeed = Math.floor(Math.random() * 200) + 1;
const freshAddress = () => ({ "x-forwarded-for": `203.0.113.${(addressSeed++ % 250) + 1}` });

describe("a token outlives nothing", () => {
  test("after the member deletes their account, their token opens nothing", async () => {
    const member = await makeUser("deleted");
    expect(await protectedStatus(member.token)).toBe(200);
    const deleted = await fetch(`${BASE_URL}/api/users/me`, {
      method: "DELETE",
      headers: { ...auth(member.token), "Content-Type": "application/json" },
      body: JSON.stringify({ reason: "test" }),
    });
    expect(deleted.status).toBe(200);
    expect(await protectedStatus(member.token)).toBe(401);
    expect((await connect(member.token)).outcome).toBe("refused");
  });

  test("a banned (deactivated) member's token is refused on HTTP and on the socket", async () => {
    const member = await makeUser("banned");
    await db`UPDATE users SET is_active = false WHERE id = ${member.id}`;
    const res = await fetch(PROTECTED, { headers: auth(member.token) });
    expect(res.status).toBe(401);
    expect(((await res.json()) as { error: string }).error).toBe("account_disabled");
    expect((await connect(member.token)).outcome).toBe("refused");
    // Unbanned, the same token works again.
    await db`UPDATE users SET is_active = true WHERE id = ${member.id}`;
    expect(await protectedStatus(member.token)).toBe(200);
  });

  test("a subject that is not a plain user id is refused even when signed", async () => {
    const member = await makeUser("subject");
    const exp = Math.floor(Date.now() / 1000) + 3600;
    for (const sub of [`${member.id}abc`, ` ${member.id}`, `0${member.id}`, "-1", "1e3"]) {
      expect(await protectedStatus(memberToken({ sub, email: "x@example.com", exp }))).toBe(401);
    }
    expect(await protectedStatus(memberToken({ sub: String(member.id), email: "x@example.com", exp }))).toBe(200);
  });

  test("an expired token is refused, and so is one without expiry", async () => {
    const member = await makeUser("expired");
    expect(await protectedStatus(memberToken({ sub: String(member.id), email: "x@example.com", exp: Math.floor(Date.now() / 1000) - 1 }))).toBe(401);
    expect(await protectedStatus(memberToken({ sub: String(member.id), email: "x@example.com" }))).toBe(401);
  });

  test("a socket whose token expires is closed on its next frame", async () => {
    const member = await makeUser("wsexpiry");
    const shortLived = memberToken({ sub: String(member.id), email: "x@example.com", exp: Math.floor(Date.now() / 1000) + 2 });
    const { socket, outcome } = await connect(shortLived);
    expect(outcome).toBe("open");
    await Bun.sleep(2500);
    const code = closed(socket as WebSocket);
    (socket as WebSocket).send(JSON.stringify({ type: "ping" }));
    expect(await code).toBe(4001);
  });

  test("an oversized frame closes the socket instead of being parsed", async () => {
    const member = await makeUser("wsbig");
    const { socket, outcome } = await connect(member.token);
    expect(outcome).toBe("open");
    const code = closed(socket as WebSocket);
    (socket as WebSocket).send(JSON.stringify({ type: "chat:send", payload: { content: "x".repeat(200_000) } }));
    expect(await code).not.toBe(1000);
  });
});

describe("names outside Latin-1", () => {
  test("a member named in Hebrew gets a working token", async () => {
    const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: `hebrew-${Date.now()}@mazl.app`, password: THROWAWAY_CREDENTIAL, name: "דוד כהן" }),
    });
    expect(res.status).toBe(200);
    const { token } = (await res.json()) as { token: string };
    expect(await protectedStatus(token)).toBe(200);
  });
});

describe("member sign-in", () => {
  test("a made-up Google or Apple token is refused, and a malformed body is a 400", async () => {
    const headers = { "Content-Type": "application/json", ...freshAddress() };
    const google = await fetch(`${BASE_URL}/api/auth/google`, { method: "POST", headers, body: JSON.stringify({ idToken: "forged" }) });
    expect(google.status).toBe(401);
    const empty = await fetch(`${BASE_URL}/api/auth/apple`, { method: "POST", headers, body: "{" });
    expect(empty.status).toBe(400);
  });

  test("sign-in attempts from one address are cut off", async () => {
    const headers = { "Content-Type": "application/json", ...freshAddress() };
    const statuses: number[] = [];
    for (let i = 0; i < 35; i++) {
      statuses.push((await fetch(`${BASE_URL}/api/auth/google`, { method: "POST", headers, body: JSON.stringify({ idToken: "forged" }) })).status);
    }
    expect(statuses).toContain(429);
  });
});

describe("waitlist sign-up", () => {
  const subscribe = (email: string, headers: Record<string, string> = freshAddress()) =>
    fetch(`${BASE_URL}/api/subscribe`, { method: "POST", headers: { "Content-Type": "application/json", ...headers }, body: JSON.stringify({ email }) });

  test("an address carrying markup is refused before it reaches the admin console", async () => {
    const marker = `${Date.now()}`;
    const attempts = [`<img/src/onerror=alert(${marker})>@a.bc`, `"><svg/onload=${marker}>@example.com`, "a@b", "x".repeat(250) + "@example.com"];
    for (const email of attempts) {
      expect((await subscribe(email)).status).toBe(400);
    }
    const stored = await db`SELECT 1 FROM waitlist WHERE email = ANY(${attempts})`;
    expect(stored.length).toBe(0);
  });

  test("one address cannot flood sign-ups", async () => {
    const address = freshAddress();
    const statuses: number[] = [];
    for (let i = 0; i < 7; i++) statuses.push((await subscribe(`flood-${Date.now()}-${i}@example.com`, address)).status);
    expect(statuses.slice(0, 5)).toEqual([200, 200, 200, 200, 200]);
    expect(statuses.slice(5)).toEqual([429, 429]);
  });

  test("a stranger's inbox cannot be flooded from many addresses: after 3 sign-ups nothing changes, the answer stays the same", async () => {
    const email = `victim-${Date.now()}@example.com`;
    for (let i = 0; i < 3; i++) expect((await subscribe(email)).status).toBe(200);
    const [before] = await db<{ verification_token: string }[]>`SELECT verification_token FROM waitlist WHERE email = ${email}`;
    const fourth = await subscribe(email);
    expect(fourth.status).toBe(200);
    const [after] = await db<{ verification_token: string }[]>`SELECT verification_token FROM waitlist WHERE email = ${email}`;
    expect(after?.verification_token).toBe(before?.verification_token);
  });
});

describe("unsubscribe links", () => {
  const signature = (email: string) => {
    const configured = process.env.MEDIA_SIGNING_KEY;
    const key = configured ? Buffer.from(configured, "base64") : createHash("sha256").update("mazl-development-only:MEDIA_SIGNING_KEY").digest();
    return createHmac("sha256", key).update(`unsubscribe:${email.toLowerCase()}`).digest("base64url");
  };
  const unsubscribed = async (email: string) => (await db`SELECT 1 FROM email_unsubscribes WHERE email = ${email}`).length > 0;

  test("nobody can unsubscribe someone else's address without the signed link", async () => {
    const email = `keep-${Date.now()}@example.com`;
    const bare = await fetch(`${BASE_URL}/api/unsubscribe?email=${encodeURIComponent(email)}`);
    expect(bare.status).toBe(400);
    const forged = await fetch(`${BASE_URL}/api/unsubscribe?email=${encodeURIComponent(email)}&t=${signature("other@example.com")}`);
    expect(forged.status).toBe(400);
    expect(await unsubscribed(email)).toBe(false);
  });

  test("the signed link from the e-mail unsubscribes", async () => {
    const email = `leave-${Date.now()}@example.com`;
    const res = await fetch(`${BASE_URL}/api/unsubscribe?email=${encodeURIComponent(email)}&t=${signature(email)}`);
    expect(res.status).toBe(200);
    expect(await unsubscribed(email)).toBe(true);
  });
});

describe("security headers", () => {
  test("pages cannot be framed, content types are not sniffed, scripts are limited to known origins", async () => {
    for (const path of ["/admin", "/admin/dashboard", "/api/health"]) {
      const res = await fetch(`${BASE_URL}${path}`);
      expect(res.headers.get("x-content-type-options")).toBe("nosniff");
      expect(res.headers.get("x-frame-options")).toBe("SAMEORIGIN");
      const csp = res.headers.get("content-security-policy") ?? "";
      expect(csp).toContain("frame-ancestors 'none'");
      expect(csp).toContain("object-src 'none'");
      expect(csp).toContain("script-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/client");
    }
  });
});
