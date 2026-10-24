import { describe, expect, test } from "bun:test";

// Short-lived member tokens (web sessions, docs/web/adr/W02): the lifetime is
// read from the token itself, decoded here without the server's helpers.
process.env.JWT_SECRET ||= "test-secret-for-jwt-ttl";
const { generateJWT, verifyJWT } = await import("../../src/auth");

const member = { id: 42, email: "jeanne@example.com", provider: "google" as const, providerId: "g-42" };
const claims = (token: string) => JSON.parse(Buffer.from(token.split(".")[1] ?? "", "base64url").toString("utf8")) as { iat: number; exp: number };

describe("member token lifetime", () => {
  test("defaults to 30 days", () => {
    const { iat, exp } = claims(generateJWT(member));
    expect(exp - iat).toBe(30 * 24 * 3600);
  });

  test("a web bridge token lives the requested seconds and still verifies", () => {
    const token = generateJWT(member, 60);
    const { iat, exp } = claims(token);
    expect(exp - iat).toBe(60);
    expect(verifyJWT(token)?.sub).toBe("42");
  });
});
