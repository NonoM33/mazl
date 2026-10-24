import { describe, expect, test } from "bun:test";
import { criterionScores, directional } from "../../src/features/matching/domain/criteria";
import { CRITERIA, DEFAULT_PARAMS, type MatchingParams } from "../../src/features/matching/domain/params";
import { profile } from "./matching-support";

const only = (criterion: (typeof CRITERIA)[number], p: MatchingParams = DEFAULT_PARAMS): MatchingParams => ({
  ...p,
  weights: { ...Object.fromEntries(CRITERIA.map((c) => [c, 0])), [criterion]: 1 } as MatchingParams["weights"],
});
const scoreOf = (criterion: (typeof CRITERIA)[number], from: ReturnType<typeof profile>, to: ReturnType<typeof profile>, d: number | null = 10, p = DEFAULT_PARAMS) => {
  const found = criterionScores(from, to, p, d).find((s) => s.criterion === criterion);
  if (!found) throw new Error("critere manquant");
  return found;
};

describe("criterionScores", () => {
  test("one entry per criterion, in CRITERIA order", () => {
    const scores = criterionScores(profile(), profile({ userId: 2 }), DEFAULT_PARAMS, 5);
    expect(scores.map((s) => s.criterion)).toEqual([...CRITERIA]);
  });
  test("weights are normalised and contributions are score x weight", () => {
    const scores = criterionScores(profile(), profile({ userId: 2, denomination: "Habad" }), DEFAULT_PARAMS, 5);
    const sum = Object.values(DEFAULT_PARAMS.weights).reduce((a, b) => a + b, 0);
    for (const s of scores) {
      expect(s.weight).toBeCloseTo(DEFAULT_PARAMS.weights[s.criterion] / sum, 12);
      expect(s.contribution).toBeCloseTo(s.score * s.weight, 12);
      expect(s.detail.length).toBeGreaterThan(0);
    }
    expect(scores.reduce((a, s) => a + s.weight, 0)).toBeCloseTo(1, 12);
  });
  test("all weights zero: weights and total are 0", () => {
    const zero = { ...DEFAULT_PARAMS, weights: Object.fromEntries(CRITERIA.map((c) => [c, 0])) as MatchingParams["weights"] };
    const d = directional(profile(), profile({ userId: 2 }), zero, 3);
    expect(d.total).toBe(0);
    expect(d.criteria.every((s) => s.weight === 0)).toBe(true);
  });
  test("ordinal: same rank 1, gap of half tolerance 0.5, beyond tolerance 0", () => {
    // denomination tolerance 3: laique(0) vs massorti(2) -> 1 - 2/3
    expect(scoreOf("denomination", profile({ denomination: "Massorti" }), profile({ denomination: "Traditionaliste" })).score).toBe(1);
    expect(scoreOf("denomination", profile({ denomination: "Laïque" }), profile({ denomination: "Massorti" })).score).toBeCloseTo(1 / 3, 12);
    expect(scoreOf("denomination", profile({ denomination: "Laïque" }), profile({ denomination: "Habad" })).score).toBe(0);
    // kashrut tolerance 2: non(0) vs a_la_maison(1) -> 0.5
    expect(scoreOf("kashrut", profile({ kashrut: "Non" }), profile({ kashrut: "À la maison" })).score).toBeCloseTo(0.5, 12);
    // shabbat tolerance 2, intention tolerance 2
    expect(scoreOf("shabbat", profile({ shabbat: "Observant" }), profile({ shabbat: "Non observant" })).score).toBe(0);
    expect(scoreOf("intention", profile({ intention: "Serious" }), profile({ intention: "Marriage" })).score).toBeCloseTo(0.5, 12);
  });
  test("ordinal: unknown, free text or missing answer -> unknownScore", () => {
    const p = { ...DEFAULT_PARAMS, religion: { ...DEFAULT_PARAMS.religion, unknownScore: 0.25 } };
    expect(scoreOf("denomination", profile({ denomination: null }), profile(), 1, p).score).toBe(0.25);
    expect(scoreOf("kashrut", profile(), profile({ kashrut: "Autre" }), 1, p).score).toBe(0.25);
    expect(scoreOf("shabbat", profile({ shabbat: "Séfarade" }), profile(), 1, p).score).toBe(0.25);
    expect(scoreOf("denomination", profile({ denomination: null }), profile(), 1, p).detail).toContain("Non renseigné");
  });
  test("age: centre 1, edge edgeScore, outside 0, unknown unknownScore", () => {
    const from = profile({ ageMin: 28, ageMax: 36 }); // centre 32, half 4
    expect(scoreOf("age", from, profile({ age: 32 })).score).toBe(1);
    expect(scoreOf("age", from, profile({ age: 28 })).score).toBeCloseTo(0.6, 12);
    expect(scoreOf("age", from, profile({ age: 36 })).score).toBeCloseTo(0.6, 12);
    expect(scoreOf("age", from, profile({ age: 30 })).score).toBeCloseTo(0.8, 12);
    expect(scoreOf("age", from, profile({ age: 37 })).score).toBe(0);
    expect(scoreOf("age", from, profile({ age: 27 })).score).toBe(0);
    expect(scoreOf("age", from, profile({ age: null })).score).toBe(0.5);
    expect(scoreOf("age", from, profile({ age: 31 })).detail).toBe("Âge 31 dans 28–36");
  });
  test("age: zero-width range scores 1 only on equality", () => {
    const from = profile({ ageMin: 30, ageMax: 30 });
    expect(scoreOf("age", from, profile({ age: 30 })).score).toBe(1);
    expect(scoreOf("age", from, profile({ age: 31 })).score).toBe(0);
  });
  test("distance: 1/(1+d/half), unknown -> unknownScore", () => {
    expect(scoreOf("distance", profile(), profile(), 0).score).toBe(1);
    expect(scoreOf("distance", profile(), profile(), 25).score).toBeCloseTo(0.5, 12);
    expect(scoreOf("distance", profile(), profile(), 75).score).toBeCloseTo(0.25, 12);
    expect(scoreOf("distance", profile(), profile(), null).score).toBe(0.5);
    expect(scoreOf("distance", profile(), profile(), 12.4).detail).toBe("12 km");
  });
  test("profile completeness of the target", () => {
    expect(scoreOf("profile", profile(), profile({ photoCount: 4, hasBio: true, promptCount: 3 })).score).toBe(1);
    expect(scoreOf("profile", profile(), profile({ photoCount: 9, hasBio: true, promptCount: 9 })).score).toBe(1);
    expect(scoreOf("profile", profile(), profile({ photoCount: 0, hasBio: false, promptCount: 0 })).score).toBe(0);
    expect(scoreOf("profile", profile(), profile({ photoCount: 2, hasBio: false, promptCount: 0 })).score).toBeCloseTo(1 / 6, 12);
  });
  test("verification of the target", () => {
    expect(scoreOf("verification", profile(), profile({ verification: "none" })).score).toBe(0);
    expect(scoreOf("verification", profile(), profile({ verification: "selfie" })).score).toBe(0.7);
    expect(scoreOf("verification", profile(), profile({ verification: "identity" })).score).toBe(1);
  });
});

describe("directional", () => {
  test("total is the sum of contributions", () => {
    const d = directional(profile(), profile({ userId: 2, denomination: "Orthodoxe" }), DEFAULT_PARAMS, 7);
    expect(d.total).toBeCloseTo(d.criteria.reduce((a, s) => a + s.contribution, 0), 12);
    expect(d.total).toBeGreaterThanOrEqual(0);
    expect(d.total).toBeLessThanOrEqual(1);
  });
  test("a perfect match on a single weighted criterion scores 1", () => {
    expect(directional(profile(), profile({ userId: 2 }), only("verification"), 3).total).toBe(1);
  });
  test("is directional: age depends on the viewer's range", () => {
    const a = profile({ userId: 1, age: 40, ageMin: 20, ageMax: 30 });
    const b = profile({ userId: 2, age: 25, ageMin: 38, ageMax: 45 });
    const p = only("age");
    expect(directional(a, b, p, null).total).toBe(1);
    expect(directional(b, a, p, null).total).toBeCloseTo(0.6 + 0.4 * (1 - Math.abs(40 - 41.5) / 3.5), 12);
  });
});
