import { describe, expect, test } from "bun:test";
import { createGoogleVerifier, type TokenInfoFetch } from "../../src/features/auth/google-token";

// Google tokeninfo answers, written from Google's documentation
// (https://developers.google.com/identity/sign-in/web/backend-auth and
// https://www.googleapis.com/oauth2/v3/tokeninfo): every field is a string,
// exp and email_verified included.

const WEB = "1111-web.apps.googleusercontent.com";
const IOS = "2222-ios.apps.googleusercontent.com";
const NOW = 1_800_000_000;

function idTokenInfo(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    iss: "https://accounts.google.com",
    azp: WEB,
    aud: WEB,
    sub: "110169484474386276334",
    email: "jeanne.exemple@example.com",
    email_verified: "true",
    name: "Jeanne Exemple",
    iat: String(NOW - 60),
    exp: String(NOW + 3000),
    alg: "RS256",
    ...overrides,
  };
}

function accessTokenInfo(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    azp: WEB,
    aud: WEB,
    sub: "110169484474386276334",
    scope: "openid https://www.googleapis.com/auth/userinfo.email",
    exp: String(NOW + 3000),
    expires_in: "3000",
    email: "jeanne.exemple@example.com",
    email_verified: "true",
    access_type: "online",
    ...overrides,
  };
}

interface Recorder { readonly fetch: TokenInfoFetch; readonly urls: string[] }

function answering(status: number, body: unknown): Recorder {
  const urls: string[] = [];
  return {
    urls,
    fetch: async (url) => {
      urls.push(url);
      return new Response(typeof body === "string" ? body : JSON.stringify(body), { status });
    },
  };
}

function verifier(recorder: Recorder, audiences: readonly string[] = [WEB, IOS]) {
  return createGoogleVerifier({ audiences, fetch: recorder.fetch, now: () => NOW });
}

describe("Google ID token", () => {
  test("a token issued to one of our clients, verified and not expired, gives its identity", async () => {
    const google = answering(200, idTokenInfo({ aud: IOS }));
    const identity = await verifier(google).verifyIdToken("id.token.value");
    expect(identity).toEqual({ sub: "110169484474386276334", email: "jeanne.exemple@example.com", name: "Jeanne Exemple", picture: undefined });
    expect(google.urls).toEqual(["https://oauth2.googleapis.com/tokeninfo?id_token=id.token.value"]);
  });

  test("the token is URL-encoded, so it cannot add query parameters", async () => {
    const google = answering(200, idTokenInfo());
    await verifier(google).verifyIdToken("a&access_token=b");
    expect(google.urls[0]).toBe("https://oauth2.googleapis.com/tokeninfo?id_token=a%26access_token%3Db");
  });

  test("a token issued to another application is refused", async () => {
    const google = answering(200, idTokenInfo({ aud: "9999-other.apps.googleusercontent.com" }));
    expect(await verifier(google).verifyIdToken("t")).toBeNull();
  });

  test("an email Google has not verified is refused", async () => {
    for (const email_verified of ["false", false, undefined, "yes", 1]) {
      const google = answering(200, idTokenInfo({ email_verified }));
      expect(await verifier(google).verifyIdToken("t")).toBeNull();
    }
  });

  test("a boolean true is accepted like the string Google sends", async () => {
    const google = answering(200, idTokenInfo({ email_verified: true }));
    expect(await verifier(google).verifyIdToken("t")).not.toBeNull();
  });

  test("an expired token is refused, and so is one without a usable expiry", async () => {
    for (const exp of [String(NOW - 1), String(NOW), undefined, "soon", ""]) {
      const google = answering(200, idTokenInfo({ exp }));
      expect(await verifier(google).verifyIdToken("t")).toBeNull();
    }
  });

  test("a token from another issuer is refused", async () => {
    const google = answering(200, idTokenInfo({ iss: "https://evil.example.com" }));
    expect(await verifier(google).verifyIdToken("t")).toBeNull();
  });

  test("a token without subject or email is refused", async () => {
    expect(await verifier(answering(200, idTokenInfo({ sub: undefined }))).verifyIdToken("t")).toBeNull();
    expect(await verifier(answering(200, idTokenInfo({ email: undefined }))).verifyIdToken("t")).toBeNull();
    expect(await verifier(answering(200, idTokenInfo({ email: "" }))).verifyIdToken("t")).toBeNull();
  });

  test("Google refusing the token, an answer that is not JSON, or a network failure all refuse", async () => {
    expect(await verifier(answering(400, { error: "invalid_token" })).verifyIdToken("t")).toBeNull();
    expect(await verifier(answering(200, "<html>")).verifyIdToken("t")).toBeNull();
    expect(await verifier(answering(200, ["not", "an", "object"])).verifyIdToken("t")).toBeNull();
    const failing = createGoogleVerifier({ audiences: [WEB], fetch: async () => { throw new Error("offline"); }, now: () => NOW });
    expect(await failing.verifyIdToken("t")).toBeNull();
  });

  test("with no client id configured, nothing is accepted and Google is not even asked", async () => {
    // An unset GOOGLE_CLIENT_ID used to make "" a valid audience.
    const google = answering(200, idTokenInfo({ aud: "" }));
    expect(await verifier(google, ["", ""]).verifyIdToken("t")).toBeNull();
    expect(google.urls).toEqual([]);
  });

  test("an empty or oversized token is refused without asking Google", async () => {
    const google = answering(200, idTokenInfo());
    expect(await verifier(google).verifyIdToken("")).toBeNull();
    expect(await verifier(google).verifyIdToken("x".repeat(8193))).toBeNull();
    expect(google.urls).toEqual([]);
  });
});

describe("Google access token (admin pop-up flow)", () => {
  test("an access token granted to our web client gives its identity", async () => {
    const google = answering(200, accessTokenInfo());
    const identity = await verifier(google, [WEB]).verifyAccessToken("ya29.value");
    expect(identity?.email).toBe("jeanne.exemple@example.com");
    expect(google.urls).toEqual(["https://oauth2.googleapis.com/tokeninfo?access_token=ya29.value"]);
  });

  test("an access token granted to another application is refused: its holder is not our user", async () => {
    const google = answering(200, accessTokenInfo({ aud: "9999-other.apps.googleusercontent.com", azp: "9999-other.apps.googleusercontent.com" }));
    expect(await verifier(google, [WEB]).verifyAccessToken("t")).toBeNull();
  });

  test("an unverified email or an expired grant is refused", async () => {
    expect(await verifier(answering(200, accessTokenInfo({ email_verified: "false" })), [WEB]).verifyAccessToken("t")).toBeNull();
    expect(await verifier(answering(200, accessTokenInfo({ exp: String(NOW - 5) })), [WEB]).verifyAccessToken("t")).toBeNull();
  });
});
