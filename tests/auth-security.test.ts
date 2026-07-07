import { test, expect, describe, beforeAll } from "bun:test";

// Security regression: forged / tampered JWTs must be rejected on protected
// routes (the old signHS256 was a 32-bit homemade hash, trivially forgeable;
// it is now a real HMAC-SHA256). Requires a running server (TEST_API_URL).
//
// The production-only guarantees (dev endpoints → 404 when NODE_ENV=production,
// boot fails without JWT_SECRET) are checked separately by the coordinator
// because they require differently-configured server instances.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

async function realToken(): Promise<string> {
  const email = `sec-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: "Sec User" }),
  });
  const data = (await res.json()) as { token?: string };
  if (!data.token) throw new Error("no token");
  return data.token;
}

const PROTECTED = `${BASE_URL}/api/matches`;

describe("JWT forgery is rejected", () => {
  let token: string;
  beforeAll(async () => { token = await realToken(); });

  test("a valid token is accepted on a protected route", async () => {
    const r = await fetch(PROTECTED, { headers: { Authorization: `Bearer ${token}` } });
    expect(r.status).toBe(200);
  });

  test("a tampered signature is rejected (401)", async () => {
    const [h, p] = token.split(".");
    const tampered = `${h}.${p}.forged_signature_aaaaaaaaaaaa`;
    const r = await fetch(PROTECTED, { headers: { Authorization: `Bearer ${tampered}` } });
    expect(r.status).toBe(401);
  });

  test("a tampered payload (privilege change) is rejected (401)", async () => {
    const [h, , s] = token.split(".");
    // swap the sub to another user id → signature no longer matches
    const forgedPayload = Buffer.from(JSON.stringify({ sub: "999999", email: "attacker@evil.com" })).toString("base64url");
    const r = await fetch(PROTECTED, { headers: { Authorization: `Bearer ${h}.${forgedPayload}.${s}` } });
    expect(r.status).toBe(401);
  });

  test("garbage / missing token is rejected (401)", async () => {
    let r = await fetch(PROTECTED, { headers: { Authorization: "Bearer not.a.jwt" } });
    expect(r.status).toBe(401);
    r = await fetch(PROTECTED);
    expect(r.status).toBe(401);
  });
});
