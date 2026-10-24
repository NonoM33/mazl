import { describe, expect, test } from "bun:test";
import { isMfaRequired } from "../../src/features/staff/application/mfa-policy";

describe("STAFF_MFA_REQUIRED policy", () => {
  test("defaults to required in production, optional elsewhere", () => {
    expect(isMfaRequired({ NODE_ENV: "production" })).toBe(true);
    expect(isMfaRequired({ NODE_ENV: "development" })).toBe(false);
    expect(isMfaRequired({ NODE_ENV: "test" })).toBe(false);
    expect(isMfaRequired({})).toBe(false);
  });

  test("an explicit setting wins over the environment", () => {
    expect(isMfaRequired({ NODE_ENV: "production", STAFF_MFA_REQUIRED: "false" })).toBe(false);
    expect(isMfaRequired({ NODE_ENV: "development", STAFF_MFA_REQUIRED: "true" })).toBe(true);
    expect(isMfaRequired({ NODE_ENV: "production", STAFF_MFA_REQUIRED: " TRUE " })).toBe(true);
  });

  test("anything else falls back to the default", () => {
    expect(isMfaRequired({ NODE_ENV: "production", STAFF_MFA_REQUIRED: "maybe" })).toBe(true);
    expect(isMfaRequired({ NODE_ENV: "test", STAFF_MFA_REQUIRED: "" })).toBe(false);
  });
});
