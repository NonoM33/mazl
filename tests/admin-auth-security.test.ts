import { describe, expect, test } from "bun:test";
import { createHmac } from "node:crypto";
import { BASE_URL, makeUser } from "./media-helpers";

// Attacks on the admin sign-in, replayed against a running server
// (TEST_API_URL) started with the same ADMIN_EMAIL, ADMIN_PASSWORD and
// ADMIN_JWT_SECRET as this process. No Google client id is configured in the
// test environment, so no Google token can ever be accepted and Google is
// never called.

const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? "admin@example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? "";
const ADMIN_SECRET = process.env.ADMIN_JWT_SECRET ?? "";
const WHITELISTED = "renaudlemagicien@gmail.com";

type Body = { success?: boolean; token?: string; error?: string };

async function post(path: string, body: unknown, headers: Record<string, string> = {}): Promise<{ status: number; body: Body }> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: (await res.json()) as Body };
}

const adminStatus = async (headers: Record<string, string>) =>
  (await fetch(`${BASE_URL}/api/admin/pending`, { headers })).status;

// A different made-up client address per scenario, so that lockouts never
// leak into another test (or another test file sharing the server).
let addressSeed = Math.floor(Math.random() * 200) + 1;
const freshAddress = () => ({ "x-forwarded-for": `198.51.100.${(addressSeed++ % 250) + 1}` });

function sign(payload: Record<string, unknown>, secret = ADMIN_SECRET): string {
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = createHmac("sha256", secret).update(`${header}.${body}`).digest("base64url");
  return `${header}.${body}.${signature}`;
}

const inAWeek = () => Math.floor(Date.now() / 1000) + 7 * 86400;

describe("Google sign-in of the admin console", () => {
  test("an email alone, without any proof from Google, gives no admin token", async () => {
    const r = await post("/api/admin/google-login", { email: WHITELISTED }, freshAddress());
    expect(r.status).toBeGreaterThanOrEqual(400);
    expect(r.status).toBeLessThan(500);
    expect(r.body.token).toBeUndefined();
  });

  test("an email next to a made-up Google token gives no admin token either", async () => {
    for (const proof of [{ accessToken: "ya29.forged" }, { idToken: "eyJ.forged.token" }]) {
      const r = await post("/api/admin/google-login", { email: WHITELISTED, ...proof }, freshAddress());
      expect(r.status).toBe(401);
      expect(r.body.token).toBeUndefined();
    }
  });

  test("a burst of Google sign-in attempts from one address is cut off", async () => {
    const address = freshAddress();
    const statuses: number[] = [];
    for (let i = 0; i < 25; i++) statuses.push((await post("/api/admin/google-login", { idToken: "x" }, address)).status);
    expect(statuses).toContain(429);
  });
});

describe("admin tokens", () => {
  test("a token in the old format (no audience, no version) is refused, even correctly signed", async () => {
    const legacy = sign({ email: WHITELISTED, role: "admin", iat: Math.floor(Date.now() / 1000), exp: inAWeek() });
    expect(await adminStatus({ Authorization: `Bearer ${legacy}` })).toBe(401);
  });

  test("a correctly signed token for an email outside the whitelist is refused", async () => {
    const token = sign({ email: "intruder@example.com", role: "admin", aud: "mazl-admin", ver: 2, exp: inAWeek() });
    expect(await adminStatus({ Authorization: `Bearer ${token}` })).toBe(401);
  });

  test("a token without expiry is refused", async () => {
    const token = sign({ email: ADMIN_EMAIL, role: "admin", aud: "mazl-admin", ver: 2 });
    expect(await adminStatus({ Authorization: `Bearer ${token}` })).toBe(401);
  });

  test("a token signed with another secret is refused", async () => {
    const token = sign({ email: ADMIN_EMAIL, role: "admin", aud: "mazl-admin", ver: 2, exp: inAWeek() }, "another-secret");
    expect(await adminStatus({ Authorization: `Bearer ${token}` })).toBe(401);
  });

  test("a member's own JWT opens no admin route", async () => {
    const member = await makeUser("adminsec");
    expect(await adminStatus({ Authorization: `Bearer ${member.token}` })).toBe(401);
  });

  test("the password sign-in gives a token that the admin routes accept", async () => {
    const r = await post("/api/admin/login", { email: ADMIN_EMAIL, password: ADMIN_PASSWORD }, freshAddress());
    expect(r.status).toBe(200);
    expect(await adminStatus({ Authorization: `Bearer ${r.body.token}` })).toBe(200);
  });

  test("the email of the password sign-in is compared without regard to case", async () => {
    const r = await post("/api/admin/login", { email: ADMIN_EMAIL.toUpperCase(), password: ADMIN_PASSWORD }, freshAddress());
    expect(r.status).toBe(200);
  });
});

describe("password guessing", () => {
  test("after 5 wrong passwords an address is locked out, right password included", async () => {
    const address = freshAddress();
    for (let i = 0; i < 5; i++) {
      expect((await post("/api/admin/login", { email: ADMIN_EMAIL, password: `wrong-${i}` }, address)).status).toBe(401);
    }
    const locked = await post("/api/admin/login", { email: ADMIN_EMAIL, password: ADMIN_PASSWORD }, address);
    expect(locked.status).toBe(429);
    expect(locked.body.token).toBeUndefined();
    // Another address is not affected.
    expect((await post("/api/admin/login", { email: ADMIN_EMAIL, password: ADMIN_PASSWORD }, freshAddress())).status).toBe(200);
  });

  test("guessing through the x-admin-password header is locked out the same way", async () => {
    const address = freshAddress();
    for (let i = 0; i < 5; i++) expect(await adminStatus({ ...address, "x-admin-password": `wrong-${i}` })).toBe(401);
    expect(await adminStatus({ ...address, "x-admin-password": ADMIN_PASSWORD })).toBe(401);
  });

  test("a malformed body is a 400, not a 500", async () => {
    const res = await fetch(`${BASE_URL}/api/admin/login`, { method: "POST", headers: { "Content-Type": "application/json", ...freshAddress() }, body: "{" });
    expect(res.status).toBe(400);
  });
});
