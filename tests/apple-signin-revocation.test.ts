import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Subprocess } from "bun";
import { join } from "node:path";
import { db } from "./media-helpers";
import { open } from "../src/shared/crypto/secret-box";
import { FakeApple, appleEnv, testSigningKey, verifyEs256 } from "./support/fake-apple";

// App Store rule 5.1.1(v), docs/launch/V1-CONTRAT.md §4: signing in with Apple
// keeps the member's refresh token (encrypted); deleting the account revokes it.
// This boots a second server on the test database with the three Apple
// variables pointing at a fake Apple, then plays the real HTTP flow: sign in
// (identity token signed by the fake's key), delete the account.

const PORT = 3000 + Math.floor(Math.random() * 900) + 5200;
const BASE = `http://127.0.0.1:${PORT}`;
const key = testSigningKey();
// The Services ID Apple's web sign-in uses (site and Android app).
const SERVICES_ID = "app.mazl.signin.test";
const apple = new FakeApple();
let server: Subprocess | null = null;

beforeAll(async () => {
  apple.start();
  const env = { ...(process.env as Record<string, string>), PORT: String(PORT), ...appleEnv(key, apple.url), APPLE_WEB_SERVICES_ID: SERVICES_ID };
  server = Bun.spawn(["bun", join(import.meta.dir, "../src/index.ts")], { env, stdout: "ignore", stderr: "ignore" });
  for (let i = 0; i < 150; i++) {
    try {
      if ((await fetch(`${BASE}/api/health`)).ok) return;
    } catch {
      // not listening yet
    }
    await Bun.sleep(100);
  }
  throw new Error("second server did not start");
}, 30_000);

afterAll(async () => {
  server?.kill();
  await server?.exited;
  await apple.stop();
});

interface SignedIn {
  readonly id: number;
  readonly token: string;
}

let counter = 0;
async function signInWithApple(body: Record<string, unknown> = {}): Promise<SignedIn> {
  counter += 1;
  const sub = `apple-sub-${Date.now()}-${counter}`;
  const response = await fetch(`${BASE}/api/auth/apple`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ identityToken: apple.identityToken({ sub, email: `${sub}@example.com` }), fullName: "Jeanne Exemple", ...body }),
  });
  const data = (await response.json()) as { success: boolean; token?: string; user?: { id: number } };
  if (response.status !== 200 || data.token === undefined || data.user === undefined) throw new Error(`sign-in refused: ${response.status} ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

const deleteAccount = (member: SignedIn) =>
  fetch(`${BASE}/api/users/me`, { method: "DELETE", headers: { authorization: `Bearer ${member.token}`, "content-type": "application/json" }, body: JSON.stringify({ reason: "test" }) });

const storedToken = async (userId: number): Promise<string | null> => {
  const rows = await db<{ refresh_token: Buffer }[]>`SELECT refresh_token FROM apple_sign_in_tokens WHERE user_id = ${userId}`;
  const sealed = rows[0]?.refresh_token;
  return sealed === undefined ? null : open(sealed, `apple-refresh-token:${userId}`).toString("utf8");
};
const rows = async (userId: number): Promise<number> =>
  Number((await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM apple_sign_in_tokens WHERE user_id = ${userId}`)[0]?.n);

describe("sign in with Apple", () => {
  test("exchanges the authorization code and keeps the refresh token encrypted", async () => {
    const before = apple.requestsTo("/auth/token").length;
    const member = await signInWithApple({ authorizationCode: "code-keep" });

    const exchange = apple.requestsTo("/auth/token").slice(before);
    expect(exchange).toHaveLength(1);
    expect(exchange[0]?.form.code).toBe("code-keep");
    await verifyEs256(exchange[0]?.form.client_secret ?? "", key.publicKey);

    expect(await storedToken(member.id)).toBe("r-code-keep");
    const [raw] = await db<{ refresh_token: Buffer }[]>`SELECT refresh_token FROM apple_sign_in_tokens WHERE user_id = ${member.id}`;
    expect(raw?.refresh_token.includes("r-code-keep")).toBe(false);
  });

  test("without a code (an older app) the sign-in still works and nothing is exchanged", async () => {
    const before = apple.requestsTo("/auth/token").length;
    const member = await signInWithApple();
    expect(apple.requestsTo("/auth/token").length).toBe(before);
    expect(await rows(member.id)).toBe(0);
  });

  test("Apple refusing the code does not fail the sign-in", async () => {
    apple.tokenAnswer = { status: 400, body: { error: "invalid_grant" } };
    try {
      const member = await signInWithApple({ authorizationCode: "code-expired" });
      expect(await rows(member.id)).toBe(0);
    } finally {
      apple.tokenAnswer = null;
    }
  });
});

describe("sign in with Apple on Android (Apple's web page)", () => {
  test("accepts a token issued to the Services ID, without exchanging its code", async () => {
    const before = apple.requestsTo("/auth/token").length;
    const sub = `apple-android-${Date.now()}`;
    const response = await fetch(`${BASE}/api/auth/apple`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ identityToken: apple.identityToken({ sub, email: `${sub}@example.com`, aud: SERVICES_ID }), authorizationCode: "code-web" }),
    });
    expect(response.status).toBe(200);
    // The web code belongs to the Services ID: the app's secret cannot exchange it.
    expect(apple.requestsTo("/auth/token").length).toBe(before);
  });

  test("still refuses a token issued to anyone else", async () => {
    const response = await fetch(`${BASE}/api/auth/apple`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ identityToken: apple.identityToken({ sub: "intruder", aud: "com.example.other" }) }),
    });
    expect(response.status).toBe(401);
  });

  test("hands Apple's answer back to the app through its intent link", async () => {
    const response = await fetch(`${BASE}/api/auth/apple/android-callback`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ code: "c-1", id_token: "h.p.s", state: "st" }),
      redirect: "manual",
    });
    expect(response.status).toBe(303);
    const target = response.headers.get("location") ?? "";
    expect(target.startsWith("intent://callback?")).toBe(true);
    expect(target.endsWith("#Intent;package=com.mazl.app;scheme=signinwithapple;end")).toBe(true);
    expect(new URLSearchParams(target.split("?")[1]?.split("#")[0]).get("id_token")).toBe("h.p.s");
  });

  test("refuses an answer that is not Apple's", async () => {
    const response = await fetch(`${BASE}/api/auth/apple/android-callback`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ nothing: "here" }),
      redirect: "manual",
    });
    expect(response.status).toBe(400);
  });
});

describe("DELETE /api/users/me", () => {
  test("revokes the Apple refresh token, then the member and the stored token are gone", async () => {
    const member = await signInWithApple({ authorizationCode: "code-revoke" });
    const before = apple.requestsTo("/auth/revoke").length;

    const response = await deleteAccount(member);
    expect(response.status).toBe(200);

    const revocation = apple.requestsTo("/auth/revoke").slice(before);
    expect(revocation).toHaveLength(1);
    expect(revocation[0]?.form.token).toBe("r-code-revoke");
    expect(revocation[0]?.form.token_type_hint).toBe("refresh_token");
    await verifyEs256(revocation[0]?.form.client_secret ?? "", key.publicKey);

    expect(Number((await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM users WHERE id = ${member.id}`)[0]?.n)).toBe(0);
    expect(await rows(member.id)).toBe(0);
  });

  test("a member who never signed in with the code is deleted without calling Apple", async () => {
    const member = await signInWithApple();
    const before = apple.requestsTo("/auth/revoke").length;
    expect((await deleteAccount(member)).status).toBe(200);
    expect(apple.requestsTo("/auth/revoke").length).toBe(before);
  });

  test("Apple refusing the revocation does not stop the deletion", async () => {
    const member = await signInWithApple({ authorizationCode: "code-refused" });
    apple.revokeAnswer = { status: 500, body: { error: "server_error" } };
    try {
      expect((await deleteAccount(member)).status).toBe(200);
    } finally {
      apple.revokeAnswer = null;
    }
    expect(Number((await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM users WHERE id = ${member.id}`)[0]?.n)).toBe(0);
  });
});
