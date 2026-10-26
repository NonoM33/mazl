import { describe, expect, test } from "bun:test";
import {
  checkReviewCredentials,
  parseReviewCredentials,
  readReviewLoginConfig,
  verifyWithBun,
  type PasswordVerifier,
} from "../../src/features/auth/review/review-login";

const PASSWORD = "exemple-motdepasse";

describe("review sign-in configuration", () => {
  test("is off unless both the user name and the hash are set", () => {
    expect(readReviewLoginConfig({})).toBeNull();
    expect(readReviewLoginConfig({ REVIEW_LOGIN_USERNAME: "relecteur" })).toBeNull();
    expect(readReviewLoginConfig({ REVIEW_LOGIN_PASSWORD_HASH: "$argon2id$x" })).toBeNull();
    expect(readReviewLoginConfig({ REVIEW_LOGIN_USERNAME: "  ", REVIEW_LOGIN_PASSWORD_HASH: "$argon2id$x" })).toBeNull();
  });

  test("decodes a hash given as base64: (a hosting may interpolate the $ of a raw argon2id hash)", () => {
    const hash = "$argon2id$v=19$m=65536,t=2,p=1$abc$def";
    const encoded = `base64:${Buffer.from(hash).toString("base64")}`;
    expect(readReviewLoginConfig({ REVIEW_LOGIN_USERNAME: "relecteur", REVIEW_LOGIN_PASSWORD_HASH: encoded })?.passwordHash).toBe(hash);
    expect(readReviewLoginConfig({ REVIEW_LOGIN_USERNAME: "relecteur", REVIEW_LOGIN_PASSWORD_HASH: "base64:" })).toBeNull();
  });

  test("reads both values, trimmed", () => {
    expect(readReviewLoginConfig({ REVIEW_LOGIN_USERNAME: " relecteur ", REVIEW_LOGIN_PASSWORD_HASH: " $argon2id$x " })).toEqual({
      username: "relecteur",
      passwordHash: "$argon2id$x",
    });
  });
});

describe("review sign-in body", () => {
  test("needs two non-empty strings of at most 200 characters", () => {
    expect(parseReviewCredentials(null)).toBeNull();
    expect(parseReviewCredentials({ username: "relecteur" })).toBeNull();
    expect(parseReviewCredentials({ username: "", password: PASSWORD })).toBeNull();
    expect(parseReviewCredentials({ username: "relecteur", password: 42 })).toBeNull();
    expect(parseReviewCredentials({ username: "relecteur", password: "x".repeat(201) })).toBeNull();
  });

  test("trims the user name, never the password", () => {
    expect(parseReviewCredentials({ username: " relecteur ", password: ` ${PASSWORD}` })).toEqual({ username: "relecteur", password: ` ${PASSWORD}` });
  });
});

describe("review credentials check", () => {
  const config = { username: "relecteur", passwordHash: Bun.password.hashSync(PASSWORD) };

  test("accepts the right pair against a real argon2id hash", async () => {
    expect(await checkReviewCredentials(config, { username: "relecteur", password: PASSWORD }, verifyWithBun)).toBe(true);
  });

  test("refuses a wrong password, a wrong user name, or a user name of another case", async () => {
    expect(await checkReviewCredentials(config, { username: "relecteur", password: "autre" }, verifyWithBun)).toBe(false);
    expect(await checkReviewCredentials(config, { username: "autre", password: PASSWORD }, verifyWithBun)).toBe(false);
    expect(await checkReviewCredentials(config, { username: "Relecteur", password: PASSWORD }, verifyWithBun)).toBe(false);
  });

  test("checks the password even when the user name is wrong", async () => {
    const seen: string[] = [];
    const verify: PasswordVerifier = async (password) => {
      seen.push(password);
      return true;
    };
    expect(await checkReviewCredentials(config, { username: "autre", password: PASSWORD }, verify)).toBe(false);
    expect(seen).toEqual([PASSWORD]);
  });

  test("a hash the verifier cannot read is a refusal, not a crash", async () => {
    const broken = { username: "relecteur", passwordHash: "not-a-hash" };
    expect(await checkReviewCredentials(broken, { username: "relecteur", password: PASSWORD }, verifyWithBun)).toBe(false);
  });
});
