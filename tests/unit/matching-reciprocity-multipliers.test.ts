import { describe, expect, test } from "bun:test";
import { multipliers } from "../../src/features/matching/domain/multipliers";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { fuse } from "../../src/features/matching/domain/reciprocity";
import { NOW, profile } from "./matching-support";

describe("fuse", () => {
  test("harmonic", () => {
    expect(fuse(0.5, 1, "harmonic")).toBeCloseTo(2 / 3, 12);
    expect(fuse(0, 0, "harmonic")).toBe(0);
    expect(fuse(0, 1, "harmonic")).toBe(0);
  });
  test("geometric, min, forward_only", () => {
    expect(fuse(0.25, 1, "geometric")).toBeCloseTo(0.5, 12);
    expect(fuse(0.3, 0.9, "min")).toBe(0.3);
    expect(fuse(0.9, 0.3, "min")).toBe(0.3);
    expect(fuse(0.9, 0.3, "forward_only")).toBe(0.9);
  });
});

const factor = (key: string, c: ReturnType<typeof profile>, p = DEFAULT_PARAMS) => {
  const m = multipliers(c, p, NOW).find((x) => x.key === key);
  if (!m) throw new Error("multiplicateur manquant");
  return m;
};
const daysAgo = (n: number) => new Date(Date.parse(NOW) - n * 86_400_000).toISOString();

describe("multipliers", () => {
  test("always the five, in order", () => {
    expect(multipliers(profile(), DEFAULT_PARAMS, NOW).map((m) => m.key)).toEqual(["freshness", "newcomer", "boost", "exposure", "safety"]);
  });
  test("freshness halves every halfLifeDays, floors, null -> floor", () => {
    expect(factor("freshness", profile({ lastActiveAt: NOW })).factor).toBe(1);
    expect(factor("freshness", profile({ lastActiveAt: daysAgo(14) })).factor).toBeCloseTo(0.5, 9);
    expect(factor("freshness", profile({ lastActiveAt: daysAgo(7) })).factor).toBeCloseTo(Math.SQRT1_2, 9);
    expect(factor("freshness", profile({ lastActiveAt: daysAgo(300) })).factor).toBe(0.3);
    expect(factor("freshness", profile({ lastActiveAt: null })).factor).toBe(0.3);
    expect(factor("freshness", profile({ lastActiveAt: daysAgo(3) })).detail).toBe("Actif il y a 3 j");
  });
  test("newcomer fades linearly; days 0 disables", () => {
    expect(factor("newcomer", profile({ createdAt: NOW })).factor).toBeCloseTo(1.2, 12);
    expect(factor("newcomer", profile({ createdAt: daysAgo(7) })).factor).toBeCloseTo(1.1, 12);
    expect(factor("newcomer", profile({ createdAt: daysAgo(14) })).factor).toBe(1);
    expect(factor("newcomer", profile({ createdAt: daysAgo(100) })).factor).toBe(1);
    const off = { ...DEFAULT_PARAMS, newcomer: { bonus: 0.2, days: 0 } };
    expect(factor("newcomer", profile({ createdAt: NOW }), off).factor).toBe(1);
  });
  test("boost only while running", () => {
    expect(factor("boost", profile({ boostedUntil: null })).factor).toBe(1);
    expect(factor("boost", profile({ boostedUntil: daysAgo(-1) })).factor).toBe(1.5);
    expect(factor("boost", profile({ boostedUntil: daysAgo(1) })).factor).toBe(1);
    expect(factor("boost", profile({ boostedUntil: NOW })).factor).toBe(1);
    expect(factor("boost", profile({ boostedUntil: daysAgo(-1) })).detail).toBe("Boost en cours");
  });
  test("exposure damps above the popularity cap", () => {
    expect(factor("exposure", profile({ likesReceived7d: 60 })).factor).toBe(1);
    expect(factor("exposure", profile({ likesReceived7d: 0 })).factor).toBe(1);
    // 120 likes, cap 60 -> 1 / (1 + 0.5 * 1)
    expect(factor("exposure", profile({ likesReceived7d: 120 })).factor).toBeCloseTo(2 / 3, 12);
  });
  test("safety compounds per report and floors", () => {
    expect(factor("safety", profile({ openReports90d: 0 })).factor).toBe(1);
    expect(factor("safety", profile({ openReports90d: 2 })).factor).toBeCloseTo(0.85 ** 2, 12);
    expect(factor("safety", profile({ openReports90d: 50 })).factor).toBe(0.4);
  });
  test("every factor carries a French detail", () => {
    for (const m of multipliers(profile(), DEFAULT_PARAMS, NOW)) expect(m.detail.length).toBeGreaterThan(0);
  });
});
