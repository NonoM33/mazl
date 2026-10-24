import { describe, expect, test } from "bun:test";
import { createHmac } from "node:crypto";
import { createTokenSigner, MissingStaffKeyError, resolveStaffKey } from "../../src/features/staff/domain/session-token";

const KEY = "unit-test-staff-key";

function forge(payload: Record<string, unknown>, key = KEY, header: Record<string, unknown> = { alg: "HS256", typ: "JWT" }): string {
  const head = Buffer.from(JSON.stringify(header)).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = createHmac("sha256", key).update(`${head}.${body}`).digest("base64url");
  return `${head}.${body}.${signature}`;
}

const NOW = new Date("2026-10-24T10:00:00.000Z");
const nowSeconds = Math.floor(NOW.getTime() / 1000);
const valid = (extra: Record<string, unknown> = {}) => ({
  email: "jeanne@example.com",
  mfa: true,
  aud: "mazl-staff",
  ver: 1,
  iat: nowSeconds,
  exp: nowSeconds + 60,
  ...extra,
});

describe("staff session token", () => {
  test("round-trips email and mfa flag", () => {
    const signer = createTokenSigner(KEY, () => NOW);
    expect(signer.verifySession(signer.signSession({ email: "jeanne@example.com", mfa: false }))).toEqual({
      email: "jeanne@example.com",
      mfa: false,
    });
  });

  test("carries aud mazl-staff, ver 1 and a 12 hour lifetime", () => {
    const token = createTokenSigner(KEY, () => NOW).signSession({ email: "a@example.com", mfa: true });
    const claims = JSON.parse(Buffer.from(token.split(".")[1] ?? "", "base64url").toString("utf8"));
    expect(claims).toMatchObject({ aud: "mazl-staff", ver: 1, mfa: true, iat: nowSeconds, exp: nowSeconds + 12 * 3600 });
  });

  test("expires", () => {
    let current = NOW;
    const signer = createTokenSigner(KEY, () => current);
    const token = signer.signSession({ email: "a@example.com", mfa: true });
    current = new Date(NOW.getTime() + 12 * 3600 * 1000 - 1000);
    expect(signer.verifySession(token)).not.toBeNull();
    current = new Date(NOW.getTime() + 12 * 3600 * 1000);
    expect(signer.verifySession(token)).toBeNull();
  });

  test("refuses another key, a tampered body and garbage", () => {
    const signer = createTokenSigner(KEY, () => NOW);
    expect(signer.verifySession(forge(valid(), "other-key"))).toBeNull();
    const [head, , sig] = forge(valid()).split(".");
    const swapped = Buffer.from(JSON.stringify(valid({ email: "root@example.com" }))).toString("base64url");
    expect(signer.verifySession(`${head}.${swapped}.${sig}`)).toBeNull();
    for (const junk of ["", "a.b", "a.b.c", "a.b.c.d", "not a token"]) expect(signer.verifySession(junk)).toBeNull();
  });

  test("refuses alg none and other header algorithms", () => {
    const signer = createTokenSigner(KEY, () => NOW);
    expect(signer.verifySession(forge(valid(), KEY, { alg: "none", typ: "JWT" }))).toBeNull();
    const head = Buffer.from(JSON.stringify({ alg: "none" })).toString("base64url");
    const body = Buffer.from(JSON.stringify(valid())).toString("base64url");
    expect(signer.verifySession(`${head}.${body}.`)).toBeNull();
  });

  test("refuses a wrong version, a missing mfa flag and a non-numeric exp", () => {
    const signer = createTokenSigner(KEY, () => NOW);
    expect(signer.verifySession(forge(valid({ ver: 2 })))).toBeNull();
    expect(signer.verifySession(forge(valid({ ver: undefined })))).toBeNull();
    expect(signer.verifySession(forge(valid({ mfa: "true" })))).toBeNull();
    expect(signer.verifySession(forge(valid({ exp: "9999999999" })))).toBeNull();
  });
});

describe("audiences never cross", () => {
  const signer = createTokenSigner(KEY, () => NOW);

  test("an admin token (aud mazl-admin), even signed with the staff key, is no staff token", () => {
    const adminLike = forge({ email: "renaudlemagicien@gmail.com", role: "admin", aud: "mazl-admin", ver: 2, iat: nowSeconds, exp: nowSeconds + 60 });
    expect(signer.verifySession(adminLike)).toBeNull();
    expect(signer.verifySession(forge({ ...valid(), aud: "mazl-admin" }))).toBeNull();
  });

  test("an admin token signed with the admin key is refused", () => {
    expect(signer.verifySession(forge({ ...valid(), aud: "mazl-admin", ver: 2, role: "admin" }, "admin-key"))).toBeNull();
  });

  test("a member token (sub, no audience) is refused", () => {
    expect(signer.verifySession(forge({ sub: "12", iat: nowSeconds, exp: nowSeconds + 60 }, "member-key"))).toBeNull();
    expect(signer.verifySession(forge({ sub: "12", email: "jeanne@example.com", mfa: true, exp: nowSeconds + 60 }))).toBeNull();
  });

  test("a challenge is no session and a session is no challenge", () => {
    const challenge = signer.signChallenge("a@example.com");
    const session = signer.signSession({ email: "a@example.com", mfa: true });
    expect(signer.verifySession(challenge)).toBeNull();
    expect(signer.verifyChallenge(session)).toBeNull();
  });
});

describe("MFA challenge token", () => {
  test("round-trips the email, aud mazl-staff-mfa, 5 minutes", () => {
    let current = NOW;
    const signer = createTokenSigner(KEY, () => current);
    const token = signer.signChallenge("a@example.com");
    const claims = JSON.parse(Buffer.from(token.split(".")[1] ?? "", "base64url").toString("utf8"));
    expect(claims).toMatchObject({ aud: "mazl-staff-mfa", ver: 1, exp: nowSeconds + 300 });
    expect(claims.mfa).toBeUndefined();
    expect(signer.verifyChallenge(token)).toBe("a@example.com");
    current = new Date(NOW.getTime() + 299_000);
    expect(signer.verifyChallenge(token)).toBe("a@example.com");
    current = new Date(NOW.getTime() + 300_000);
    expect(signer.verifyChallenge(token)).toBeNull();
  });

  test("refuses another key", () => {
    expect(createTokenSigner(KEY, () => NOW).verifyChallenge(forge({ ...valid(), aud: "mazl-staff-mfa" }, "other"))).toBeNull();
  });
});

describe("signing key", () => {
  test("STAFF_JWT_SECRET wins", () => {
    expect(resolveStaffKey({ STAFF_JWT_SECRET: "dedicated", JWT_SECRET: "member" })).toBe("dedicated");
  });

  test("otherwise HMAC-SHA256(JWT_SECRET, 'mazl:staff-jwt') in hex, distinct from the member secret", () => {
    const expected = createHmac("sha256", "member").update("mazl:staff-jwt").digest("hex");
    expect(resolveStaffKey({ JWT_SECRET: "member" })).toBe(expected);
    expect(expected).not.toBe("member");
  });

  test("throws when neither is set", () => {
    expect(() => resolveStaffKey({})).toThrow(MissingStaffKeyError);
    expect(() => resolveStaffKey({ STAFF_JWT_SECRET: "" })).toThrow(MissingStaffKeyError);
  });
});
