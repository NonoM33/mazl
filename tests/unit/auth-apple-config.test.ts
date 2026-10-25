import { describe, expect, test } from "bun:test";
import { generateKeyPairSync } from "node:crypto";
import { AppleSignInConfigError, appleApiBase, readAppleSignInConfig } from "../../src/features/auth/apple/apple-config";
import { appleEnv, testSigningKey } from "../support/fake-apple";

// docs/launch/V1-CONTRAT.md §4: APPLE_TEAM_ID, APPLE_SIGNIN_KEY_ID and
// APPLE_SIGNIN_PRIVATE_KEY (PEM). Absent: the sign-in works, the revocation is
// skipped with a warning.
const key = testSigningKey();
const complete = appleEnv(key);

describe("Sign in with Apple configuration", () => {
  test("the three variables make it available, for the app's bundle id", () => {
    const config = readAppleSignInConfig(complete);
    if (!config.available) throw new Error(`expected available: ${config.reason}`);
    expect(config.credentials.teamId).toBe("TEAM123456");
    expect(config.credentials.keyId).toBe("KEY1234567");
    expect(config.credentials.bundleId).toBe("com.mazl.app");
    expect(config.apiBase).toBe("https://appleid.apple.com");
  });

  test("no variable at all: unavailable, and the warning names all three", () => {
    const config = readAppleSignInConfig({});
    if (config.available) throw new Error("expected unavailable");
    expect(config.reason).toContain("APPLE_TEAM_ID");
    expect(config.reason).toContain("APPLE_SIGNIN_KEY_ID");
    expect(config.reason).toContain("APPLE_SIGNIN_PRIVATE_KEY");
  });

  test("one variable missing: unavailable, and the warning names that one", () => {
    const { APPLE_SIGNIN_KEY_ID: _omitted, ...rest } = complete;
    const config = readAppleSignInConfig(rest);
    if (config.available) throw new Error("expected unavailable");
    expect(config.reason).toContain("APPLE_SIGNIN_KEY_ID");
    expect(config.reason).not.toContain("APPLE_TEAM_ID");
  });

  test("blank values count as missing", () => {
    expect(readAppleSignInConfig({ ...complete, APPLE_TEAM_ID: "   " }).available).toBe(false);
  });

  test("a PEM written on one line with literal \\n (as env files do) is understood", () => {
    const oneLine = key.pem.trim().split("\n").join("\\n");
    expect(readAppleSignInConfig({ ...complete, APPLE_SIGNIN_PRIVATE_KEY: oneLine }).available).toBe(true);
  });

  test("a value that is not a P-256 PEM key is unavailable, never a crash", () => {
    const config = readAppleSignInConfig({ ...complete, APPLE_SIGNIN_PRIVATE_KEY: "not a key" });
    if (config.available) throw new Error("expected unavailable");
    expect(config.reason).toContain("APPLE_SIGNIN_PRIVATE_KEY");
    expect(config.reason).not.toContain("not a key");
  });

  test("an RSA key is not an Apple sign-in key (ES256 needs P-256)", () => {
    const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
    const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
    expect(readAppleSignInConfig({ ...complete, APPLE_SIGNIN_PRIVATE_KEY: pem }).available).toBe(false);
  });
});

describe("APPLE_API_BASE (a fake Apple for tests)", () => {
  test("is accepted outside production, without a trailing slash", () => {
    expect(appleApiBase({ APPLE_API_BASE: "http://127.0.0.1:12113/", NODE_ENV: "test" })).toBe("http://127.0.0.1:12113");
    const config = readAppleSignInConfig({ ...complete, APPLE_API_BASE: "http://127.0.0.1:12113", NODE_ENV: "development" });
    if (!config.available) throw new Error("expected available");
    expect(config.apiBase).toBe("http://127.0.0.1:12113");
  });

  test("is refused in production", () => {
    expect(() => appleApiBase({ APPLE_API_BASE: "http://127.0.0.1:12113", NODE_ENV: "production" })).toThrow(AppleSignInConfigError);
    expect(() => readAppleSignInConfig({ ...complete, APPLE_API_BASE: "http://127.0.0.1:1", NODE_ENV: "production" })).toThrow(AppleSignInConfigError);
  });

  // The key that verifies Apple identity tokens comes from this host: anything
  // but development or test (staging, a forgotten NODE_ENV) is a real server.
  test("is refused on any real deployment, NODE_ENV unset or staging included", () => {
    for (const NODE_ENV of [undefined, "", "staging", "prod"]) {
      expect(() => appleApiBase({ APPLE_API_BASE: "http://127.0.0.1:12113", NODE_ENV })).toThrow(AppleSignInConfigError);
    }
  });

  test("must be a URL", () => {
    expect(() => appleApiBase({ APPLE_API_BASE: "not a url", NODE_ENV: "test" })).toThrow(AppleSignInConfigError);
  });

  test("unset or blank: Apple's own host, in production too", () => {
    expect(appleApiBase({ NODE_ENV: "production" })).toBe("https://appleid.apple.com");
    expect(appleApiBase({ APPLE_API_BASE: "  ", NODE_ENV: "production" })).toBe("https://appleid.apple.com");
  });
});
