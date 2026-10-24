import { describe, expect, test } from "bun:test";
import { rankCandidates } from "../../src/features/matching/domain/engine";
import { DEFAULT_PARAMS, type MatchingParams } from "../../src/features/matching/domain/params";
import { context, NOW, profile } from "./matching-support";

const calm: MatchingParams = { ...DEFAULT_PARAMS, exploration: { epsilon: 0, minScore: 0 } };
const viewer = profile({ userId: 1 });
const woman = (userId: number, o = {}) => profile({ userId, gender: "female", lookingFor: "male", ...o });

describe("rankCandidates", () => {
  test("lists exclusions and never ranks them", () => {
    const candidates = [woman(2), woman(3, { gender: "male" }), woman(4, { age: 60 }), woman(5), viewer];
    const r = rankCandidates(viewer, candidates, context([5]), calm, 1);
    expect(r.ranked.map((c) => c.userId)).toEqual([2]);
    expect(r.exclusions).toEqual([
      { userId: 3, reason: "gender" },
      { userId: 4, reason: "age" },
      { userId: 5, reason: "excluded" },
      { userId: 1, reason: "excluded" },
    ]);
  });
  test("score = reciprocal x product of multipliers; ranks 1..n; sorted desc", () => {
    const candidates = [woman(2, { denomination: "Habad" }), woman(3), woman(4, { openReports90d: 3 })];
    const r = rankCandidates(viewer, candidates, context(), calm, 1);
    r.ranked.forEach((c, i) => {
      expect(c.rank).toBe(i + 1);
      expect(c.score).toBeCloseTo(c.reciprocal * c.multipliers.reduce((a, m) => a * m.factor, 1), 12);
      expect(c.explored).toBe(false);
    });
    for (let i = 1; i < r.ranked.length; i++) expect(r.ranked[i - 1]!.score).toBeGreaterThanOrEqual(r.ranked[i]!.score);
    expect(r.ranked[0]!.userId).toBe(3);
  });
  test("ties are broken by ascending userId", () => {
    const r = rankCandidates(viewer, [woman(9), woman(4), woman(7)], context(), calm, 1);
    expect(r.ranked.map((c) => c.userId)).toEqual([4, 7, 9]);
  });
  test("empty input", () => {
    expect(rankCandidates(viewer, [], context(), calm, 1)).toEqual({ ranked: [], exclusions: [] });
  });
  test("a boost raises the score of an otherwise equal candidate", () => {
    const boosted = woman(8, { boostedUntil: new Date(Date.parse(NOW) + 1e6).toISOString() });
    const r = rankCandidates(viewer, [woman(2), boosted], context(), calm, 1);
    expect(r.ranked[0]!.userId).toBe(8);
  });
});

describe("exploration", () => {
  // 10 strong candidates, then weak but plausible ones (older, far less compatible).
  const strong = Array.from({ length: 10 }, (_, i) => woman(100 + i));
  const weak = Array.from({ length: 20 }, (_, i) => woman(200 + i, { denomination: "Habad", kashrut: "Glatt", shabbat: "Tres observant", intention: "Open", photoCount: 0, hasBio: false, promptCount: 0, verification: "none", age: 35 }));
  const everyone = [...strong, ...weak];
  const params = (epsilon: number, minScore: number): MatchingParams => ({ ...DEFAULT_PARAMS, exploration: { epsilon, minScore } });

  test("epsilon 0: nothing explored", () => {
    const r = rankCandidates(viewer, everyone, context(), params(0, 0), 5, 10);
    expect(r.ranked.some((c) => c.explored)).toBe(false);
  });
  test("fills floor(epsilon x page) places from the end of the page with plausible out-of-page candidates", () => {
    const r = rankCandidates(viewer, everyone, context(), params(0.3, 0), 5, 10);
    const explored = r.ranked.filter((c) => c.explored);
    expect(explored.length).toBe(3);
    expect(r.ranked.slice(7, 10).every((c) => c.explored)).toBe(true);
    expect(r.ranked.slice(0, 7).every((c) => !c.explored)).toBe(true);
    expect(explored.every((c) => c.userId >= 200)).toBe(true);
    expect(r.ranked.map((c) => c.rank)).toEqual(r.ranked.map((_, i) => i + 1));
    expect(new Set(r.ranked.map((c) => c.userId)).size).toBe(r.ranked.length);
    expect(r.ranked.length).toBe(30);
  });
  test("fewer places when not enough plausible candidates", () => {
    const high = params(0.3, 0.999);
    const r = rankCandidates(viewer, everyone, context(), high, 5, 10);
    expect(r.ranked.filter((c) => c.explored).length).toBe(0);
  });
  test("seed changes who is explored, same seed does not", () => {
    const a = rankCandidates(viewer, everyone, context(), params(0.3, 0), 1, 10);
    const b = rankCandidates(viewer, everyone, context(), params(0.3, 0), 1, 10);
    expect(a).toEqual(b);
    const picks = new Set<string>();
    for (let seed = 0; seed < 10; seed++) {
      const r = rankCandidates(viewer, everyone, context(), params(0.3, 0), seed, 10);
      picks.add(r.ranked.filter((c) => c.explored).map((c) => c.userId).join(","));
    }
    expect(picks.size).toBeGreaterThan(1);
  });
  test("no limit: page is everyone, so nothing lies beyond it", () => {
    const r = rankCandidates(viewer, everyone, context(), params(0.3, 0), 1);
    expect(r.ranked.some((c) => c.explored)).toBe(false);
  });
});
