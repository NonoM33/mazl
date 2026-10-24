import { describe, expect, test } from "bun:test";
import { parsePagination } from "../../src/features/admin/admin.pagination";

// Spec: limit is an integer in 1..100 (default 50), offset an integer >= 0 (default 0).
// Garbage never throws: NaN falls back to the default, out-of-range values are clamped.
describe("parsePagination", () => {
  test("uses the defaults when nothing is given", () => {
    expect(parsePagination(undefined, undefined)).toEqual({ limit: 50, offset: 0 });
  });

  test("accepts valid values", () => {
    expect(parsePagination("10", "20")).toEqual({ limit: 10, offset: 20 });
  });

  test("falls back to the defaults on NaN and on non-integers", () => {
    expect(parsePagination("abc", "xyz")).toEqual({ limit: 50, offset: 0 });
    expect(parsePagination("", "")).toEqual({ limit: 50, offset: 0 });
    expect(parsePagination("1.5", "2.5")).toEqual({ limit: 50, offset: 0 });
    expect(parsePagination("10abc", "5abc")).toEqual({ limit: 50, offset: 0 });
  });

  test("clamps limit to 1..100", () => {
    expect(parsePagination("100000", "0").limit).toBe(100);
    expect(parsePagination("0", "0").limit).toBe(1);
    expect(parsePagination("-7", "0").limit).toBe(1);
  });

  test("clamps a negative offset to 0", () => {
    expect(parsePagination("10", "-5").offset).toBe(0);
  });

  test("clamps an absurd offset so it still fits a Postgres integer", () => {
    expect(parsePagination("10", "99999999999999999999").offset).toBeLessThanOrEqual(2_147_483_647);
  });
});
