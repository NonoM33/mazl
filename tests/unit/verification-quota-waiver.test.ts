import { describe, expect, test } from "bun:test";
import { isQuotaWaived, parseWaiverEnd } from "../../src/features/verification/domain/quota-waiver";

describe("the waiver of the daily verification limit", () => {
  const end = parseWaiverEnd("2026-10-28T14:00:00Z");

  test("reads an ISO date, and nothing else", () => {
    expect(end?.toISOString()).toBe("2026-10-28T14:00:00.000Z");
    expect(parseWaiverEnd(undefined)).toBeNull();
    expect(parseWaiverEnd("  ")).toBeNull();
    expect(parseWaiverEnd("dans 48 h")).toBeNull();
  });

  test("lifts the limit for an administrator until the end, never for anyone else", () => {
    const before = new Date("2026-10-27T09:00:00Z");
    const after = new Date("2026-10-28T14:00:01Z");
    expect(isQuotaWaived(true, before, end)).toBe(true);
    expect(isQuotaWaived(true, after, end)).toBe(false);
    expect(isQuotaWaived(false, before, end)).toBe(false);
    expect(isQuotaWaived(true, before, null)).toBe(false);
  });
});
