import { afterAll, afterEach, beforeAll, describe, expect, test } from "bun:test";
import { AppleApiError, HttpAppleTokenApi } from "../../src/features/auth/apple/apple-token-api";
import { readAppleSignInConfig } from "../../src/features/auth/apple/apple-config";
import { FakeApple, appleEnv, testSigningKey, verifyEs256 } from "../support/fake-apple";

// The two Apple calls, written from Apple's documentation ("Generate and
// validate tokens", "Revoke tokens"): form-encoded POSTs to /auth/token and
// /auth/revoke carrying client_id, client_secret and the code or the token.
const key = testSigningKey();
const apple = new FakeApple();

function apiFor(overrides: { fetch?: typeof fetch; timeoutMs?: number } = {}): HttpAppleTokenApi {
  const config = readAppleSignInConfig(appleEnv(key, apple.url));
  if (!config.available) throw new Error("test configuration must be available");
  return new HttpAppleTokenApi({ credentials: config.credentials, base: config.apiBase, ...overrides });
}

beforeAll(() => {
  apple.start();
});
afterAll(() => apple.stop());
afterEach(() => {
  apple.requests.length = 0;
  apple.tokenAnswer = null;
  apple.revokeAnswer = null;
  apple.delayMs = 0;
});

describe("exchanging the authorization code", () => {
  test("posts the code with a client secret Apple can verify, and returns the refresh token", async () => {
    const refresh = await apiFor().exchangeAuthorizationCode("c-1234");
    expect(refresh).toBe("r-c-1234");

    const [request] = apple.requestsTo("/auth/token");
    expect(apple.requestsTo("/auth/token")).toHaveLength(1);
    expect(request?.method).toBe("POST");
    expect(request?.form.grant_type).toBe("authorization_code");
    expect(request?.form.code).toBe("c-1234");
    expect(request?.form.client_id).toBe("com.mazl.app");
    const { payload } = await verifyEs256(request?.form.client_secret ?? "", key.publicKey);
    expect(payload.sub).toBe("com.mazl.app");
  });

  test("Apple refusing the code (expired, already used) is a typed error", async () => {
    apple.tokenAnswer = { status: 400, body: { error: "invalid_grant", error_description: "The code has expired or has been revoked." } };
    const failure = await apiFor().exchangeAuthorizationCode("c-old").catch((error: unknown) => error);
    expect(failure).toBeInstanceOf(AppleApiError);
    expect((failure as AppleApiError).status).toBe(400);
    expect((failure as AppleApiError).appleError).toBe("invalid_grant");
  });

  test("an error never repeats the code or the secret", async () => {
    apple.tokenAnswer = { status: 400, body: { error: "invalid_client" } };
    const failure = (await apiFor().exchangeAuthorizationCode("c-secret-code").catch((error: unknown) => error)) as AppleApiError;
    expect(failure.message).not.toContain("c-secret-code");
    expect(failure.message).not.toContain("eyJ");
  });

  test("an answer with no refresh token is an error, not an empty token", async () => {
    apple.tokenAnswer = { status: 200, body: { access_token: "a", token_type: "Bearer" } };
    await expect(apiFor().exchangeAuthorizationCode("c-1")).rejects.toBeInstanceOf(AppleApiError);
  });

  test("an answer that is not JSON is an error", async () => {
    const html: typeof fetch = Object.assign(async () => new Response("<html>bad gateway</html>", { status: 200 }), { preconnect: () => undefined });
    await expect(apiFor({ fetch: html }).exchangeAuthorizationCode("c-1")).rejects.toBeInstanceOf(AppleApiError);
  });

  test("a slow Apple is given up on", async () => {
    apple.delayMs = 400;
    await expect(apiFor({ timeoutMs: 50 }).exchangeAuthorizationCode("c-1")).rejects.toBeInstanceOf(AppleApiError);
  });
});

describe("revoking the refresh token", () => {
  test("posts the token as a refresh_token with a client secret Apple can verify", async () => {
    await apiFor().revokeRefreshToken("r-abc");
    const [request] = apple.requestsTo("/auth/revoke");
    expect(apple.requestsTo("/auth/revoke")).toHaveLength(1);
    expect(request?.method).toBe("POST");
    expect(request?.form.token).toBe("r-abc");
    expect(request?.form.token_type_hint).toBe("refresh_token");
    expect(request?.form.client_id).toBe("com.mazl.app");
    await verifyEs256(request?.form.client_secret ?? "", key.publicKey);
  });

  test("Apple's empty 200 is a success", async () => {
    await expect(apiFor().revokeRefreshToken("r-abc")).resolves.toBeUndefined();
  });

  test("a refusal is a typed error", async () => {
    apple.revokeAnswer = { status: 400, body: { error: "invalid_request" } };
    const failure = await apiFor().revokeRefreshToken("r-abc").catch((error: unknown) => error);
    expect(failure).toBeInstanceOf(AppleApiError);
    expect((failure as AppleApiError).status).toBe(400);
    expect((failure as AppleApiError).message).not.toContain("r-abc");
  });

  test("an unreachable Apple is an error", async () => {
    const down: typeof fetch = Object.assign(async () => { throw new TypeError("connect ECONNREFUSED"); }, { preconnect: () => undefined });
    await expect(apiFor({ fetch: down }).revokeRefreshToken("r-abc")).rejects.toBeInstanceOf(AppleApiError);
  });
});
