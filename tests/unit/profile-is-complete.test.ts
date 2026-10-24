import { describe, expect, test } from "bun:test";
import { isProfileComplete } from "../../src/features/profile/domain/profile-completeness";

// The one rule behind profiles.is_complete: display name, birthdate (18+),
// gender and looking_for, present and valid.

const NOW = new Date("2026-10-24T12:00:00Z");

const COMPLETE = {
  display_name: "Jeanne",
  birthdate: new Date("1995-06-15T00:00:00Z"),
  gender: "female",
  looking_for: "male",
};

describe("isProfileComplete", () => {
  test("true when every required field is present and valid", () => {
    expect(isProfileComplete(COMPLETE, NOW)).toBe(true);
  });

  test("accepts a birthdate given as an ISO string", () => {
    expect(isProfileComplete({ ...COMPLETE, birthdate: "1995-06-15" }, NOW)).toBe(true);
  });

  test("false without a profile", () => {
    expect(isProfileComplete(null, NOW)).toBe(false);
    expect(isProfileComplete(undefined, NOW)).toBe(false);
  });

  test("false when the display name is missing or blank", () => {
    for (const display_name of [null, undefined, "", "   "]) {
      expect(isProfileComplete({ ...COMPLETE, display_name }, NOW)).toBe(false);
    }
  });

  test("false when the birthdate is missing or unreadable", () => {
    for (const birthdate of [null, undefined, "not a date", 42]) {
      expect(isProfileComplete({ ...COMPLETE, birthdate }, NOW)).toBe(false);
    }
  });

  test("false for gender or looking_for missing or unknown", () => {
    for (const value of [null, undefined, "", "other"]) {
      expect(isProfileComplete({ ...COMPLETE, gender: value }, NOW)).toBe(false);
      expect(isProfileComplete({ ...COMPLETE, looking_for: value }, NOW)).toBe(false);
    }
    expect(isProfileComplete({ ...COMPLETE, gender: "all" }, NOW)).toBe(false);
  });

  test("looking for « all » is a complete answer", () => {
    expect(isProfileComplete({ ...COMPLETE, looking_for: "all" }, NOW)).toBe(true);
  });

  test("the 18th birthday is the threshold, to the day", () => {
    const day = (iso: string) => ({ ...COMPLETE, birthdate: new Date(iso) });
    expect(isProfileComplete(day("2008-10-24T00:00:00Z"), NOW)).toBe(true); // 18 today
    expect(isProfileComplete(day("2008-10-25T00:00:00Z"), NOW)).toBe(false); // 18 tomorrow
    expect(isProfileComplete(day("2010-01-01T00:00:00Z"), NOW)).toBe(false); // 16
  });
});
