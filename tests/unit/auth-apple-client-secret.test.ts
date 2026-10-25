import { describe, expect, test } from "bun:test";
import { createAppleClientSecret } from "../../src/features/auth/apple/apple-client-secret";
import { readAppleSignInConfig } from "../../src/features/auth/apple/apple-config";
import { appleEnv, testSigningKey, verifyEs256 } from "../support/fake-apple";

// Apple's rules for the client secret of Sign in with Apple (developer.apple.com,
// "Creating a client secret"): a JWT signed ES256 with the .p8 key; header kid =
// the key id; claims iss = team id, iat, exp (at most 6 months later),
// aud = https://appleid.apple.com, sub = the client id (here the app's bundle id).
const key = testSigningKey();
const config = readAppleSignInConfig(appleEnv(key));
if (!config.available) throw new Error("test configuration must be available");
const NOW = new Date("2026-10-25T10:00:00Z");
const SIX_MONTHS = 15_777_000;

describe("Apple client secret", () => {
  test("is a JWT that the public key of the .p8 verifies", async () => {
    const { header, payload } = await verifyEs256(createAppleClientSecret(config.credentials, NOW), key.publicKey);
    expect(header).toEqual({ alg: "ES256", kid: "KEY1234567" });
    expect(payload.iss).toBe("TEAM123456");
    expect(payload.sub).toBe("com.mazl.app");
    expect(payload.aud).toBe("https://appleid.apple.com");
  });

  test("is dated: issued now, expiring soon and never beyond Apple's six months", async () => {
    const { payload } = await verifyEs256(createAppleClientSecret(config.credentials, NOW), key.publicKey);
    const iat = Number(payload.iat);
    const exp = Number(payload.exp);
    expect(iat).toBe(Math.floor(NOW.getTime() / 1000));
    expect(exp).toBeGreaterThan(iat);
    expect(exp - iat).toBeLessThanOrEqual(SIX_MONTHS);
  });

  test("another key does not verify it", async () => {
    const other = testSigningKey();
    await expect(verifyEs256(createAppleClientSecret(config.credentials, NOW), other.publicKey)).rejects.toThrow();
  });

  test("carries nothing but the documented claims", async () => {
    const { payload } = await verifyEs256(createAppleClientSecret(config.credentials, NOW), key.publicKey);
    expect(Object.keys(payload).sort()).toEqual(["aud", "exp", "iat", "iss", "sub"]);
  });
});
