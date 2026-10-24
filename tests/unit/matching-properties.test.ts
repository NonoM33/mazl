import { describe, expect, test } from "bun:test";
import { criterionScores, directional } from "../../src/features/matching/domain/criteria";
import { rankCandidates } from "../../src/features/matching/domain/engine";
import { distanceKm } from "../../src/features/matching/domain/geo";
import { CRITERIA, DEFAULT_PARAMS, RECIPROCITY_MODES, type MatchingParams } from "../../src/features/matching/domain/params";
import type { MatchProfile } from "../../src/features/matching/domain/profile";
import { syntheticNow, syntheticPopulation } from "../../src/features/matching/domain/synthetic";
import { context, referenceKm } from "./matching-support";

const SEEDS = Array.from({ length: 20 }, (_, i) => i + 1);
const SIZE = 120;
const noExploration = (p: MatchingParams): MatchingParams => ({ ...p, exploration: { ...p.exploration, epsilon: 0 } });

// Viewers sampled across the population (every 12th).
function* scenes(): Generator<{ seed: number; viewer: MatchProfile; all: readonly MatchProfile[]; now: string }> {
  for (const seed of SEEDS) {
    const { profiles } = syntheticPopulation(seed, SIZE);
    for (let i = 0; i < profiles.length; i += 12) yield { seed, viewer: profiles[i]!, all: profiles, now: syntheticNow(seed) };
  }
}

const accepts = (looking: MatchProfile["lookingFor"], gender: MatchProfile["gender"]) => looking === null || looking === "all" || gender === null || looking === gender;
const inRange = (age: number | null, min: number, max: number) => age === null || (age >= min && age <= max);
function referenceAllows(v: MatchProfile, c: MatchProfile, p: MatchingParams): boolean {
  if (!accepts(v.lookingFor, c.gender) || !accepts(c.lookingFor, v.gender)) return false;
  if (!inRange(c.age, v.ageMin, v.ageMax)) return false;
  if (p.filters.mutualAge && !inRange(v.age, c.ageMin, c.ageMax)) return false;
  if (v.location && c.location) {
    const d = referenceKm(v.location.latitude, v.location.longitude, c.location.latitude, c.location.longitude);
    if (v.distanceMaxKm !== null && d > v.distanceMaxKm) return false;
    if (p.filters.mutualDistance && c.distanceMaxKm !== null && d > c.distanceMaxKm) return false;
  }
  return true;
}

describe("proprietes du moteur sur populations synthetiques", () => {
  test("a. les filtres durs ne sont jamais violes, et rien d'admissible n'est exclu a tort", () => {
    for (const { seed, viewer, all, now } of scenes()) {
      const r = rankCandidates(viewer, all, context([], now), DEFAULT_PARAMS, seed);
      for (const c of r.ranked) expect(referenceAllows(viewer, all[c.userId - 1]!, DEFAULT_PARAMS)).toBe(true);
      for (const e of r.exclusions) if (e.reason !== "excluded") expect(referenceAllows(viewer, all[e.userId - 1]!, DEFAULT_PARAMS)).toBe(false);
      expect(r.ranked.length + r.exclusions.length).toBe(all.length);
    }
  });
  test("a. meme avec les filtres reciproques coupes", () => {
    const loose: MatchingParams = { ...DEFAULT_PARAMS, filters: { mutualAge: false, mutualDistance: false } };
    for (const { seed, viewer, all, now } of scenes()) {
      const r = rankCandidates(viewer, all, context([], now), loose, seed);
      for (const c of r.ranked) expect(referenceAllows(viewer, all[c.userId - 1]!, loose)).toBe(true);
    }
  });
  test("b. jamais un exclu ni le viewer, sans doublon", () => {
    for (const { seed, viewer, all, now } of scenes()) {
      const blocked = all.filter((p) => p.userId % 5 === 0).map((p) => p.userId);
      const r = rankCandidates(viewer, all, context(blocked, now), DEFAULT_PARAMS, seed, 20);
      const ids = r.ranked.map((c) => c.userId);
      expect(ids).not.toContain(viewer.userId);
      for (const id of blocked) expect(ids).not.toContain(id);
      expect(new Set(ids).size).toBe(ids.length);
    }
  });
  test("c. determinisme, et ordre independant de la seed sans exploration", () => {
    const p = noExploration(DEFAULT_PARAMS);
    for (const { seed, viewer, all, now } of scenes()) {
      const ctx = context([], now);
      expect(rankCandidates(viewer, all, ctx, DEFAULT_PARAMS, seed, 30)).toEqual(rankCandidates(viewer, all, ctx, DEFAULT_PARAMS, seed, 30));
      const a = rankCandidates(viewer, all, ctx, p, seed, 30);
      const b = rankCandidates(viewer, all, ctx, p, seed + 1000, 30);
      expect(a).toEqual(b);
    }
  });
  test("d. reciprocite symetrique en harmonic/geometric/min", () => {
    for (const mode of RECIPROCITY_MODES) {
      let asymmetric = 0;
      for (const { seed, all } of [...scenes()].slice(0, 40)) {
        const a = all[(seed * 7) % all.length]!;
        const b = all[(seed * 13 + 5) % all.length]!;
        if (a.userId === b.userId) continue;
        const p = noExploration({ ...DEFAULT_PARAMS, reciprocity: { mode }, filters: { mutualAge: false, mutualDistance: false } });
        const now = syntheticNow(seed);
        const ab = rankCandidates(a, [b], context([], now), { ...p, filters: { mutualAge: false, mutualDistance: false } }, 1).ranked[0];
        const ba = rankCandidates(b, [a], context([], now), p, 1).ranked[0];
        if (!ab || !ba) continue;
        if (mode === "forward_only") {
          if (Math.abs(ab.reciprocal - ba.reciprocal) > 1e-12) asymmetric++;
        } else {
          expect(Math.abs(ab.reciprocal - ba.reciprocal)).toBeLessThan(1e-12);
        }
      }
      if (mode === "forward_only") expect(asymmetric).toBeGreaterThan(0);
    }
  });
  test("e. bornes des sous-scores, totaux et multiplicateurs", () => {
    const p = DEFAULT_PARAMS;
    for (const { seed, viewer, all, now } of scenes()) {
      const r = rankCandidates(viewer, all, context([], now), p, seed);
      for (const c of r.ranked) {
        for (const d of [c.forward, c.backward]) {
          expect(d.total).toBeGreaterThanOrEqual(0);
          expect(d.total).toBeLessThanOrEqual(1);
          for (const s of d.criteria) {
            expect(s.score).toBeGreaterThanOrEqual(0);
            expect(s.score).toBeLessThanOrEqual(1);
          }
        }
        expect(c.reciprocal).toBeGreaterThanOrEqual(0);
        expect(c.reciprocal).toBeLessThanOrEqual(1);
        const f = Object.fromEntries(c.multipliers.map((m) => [m.key, m.factor]));
        expect(f["freshness"]).toBeGreaterThanOrEqual(p.freshness.floor);
        expect(f["freshness"]).toBeLessThanOrEqual(1);
        expect([1, p.boost.factor]).toContain(Number(f["boost"]));
        expect(f["exposure"]).toBeGreaterThan(0);
        expect(f["exposure"]).toBeLessThanOrEqual(1);
        expect(f["safety"]).toBeGreaterThanOrEqual(p.safety.floor);
        expect(f["safety"]).toBeLessThanOrEqual(1);
        expect(f["newcomer"]).toBeGreaterThanOrEqual(1);
        expect(f["newcomer"]).toBeLessThanOrEqual(1 + p.newcomer.bonus + 1e-12);
      }
    }
  });
  test("f. monotonie : monter le poids du meilleur sous-score ne baisse jamais le total", () => {
    for (const { viewer, all } of [...scenes()].slice(0, 60)) {
      for (const to of all.slice(0, 15)) {
        if (to.userId === viewer.userId) continue;
        const d = viewer.location && to.location ? distanceKm(viewer.location, to.location) : null;
        const scores = criterionScores(viewer, to, DEFAULT_PARAMS, d);
        const best = scores.reduce((a, b) => (b.score > a.score ? b : a));
        const max = Math.max(...scores.map((s) => s.score));
        expect(best.score).toBe(max);
        const raised: MatchingParams = { ...DEFAULT_PARAMS, weights: { ...DEFAULT_PARAMS.weights, [best.criterion]: DEFAULT_PARAMS.weights[best.criterion] + 4 } };
        const before = directional(viewer, to, DEFAULT_PARAMS, d).total;
        const after = directional(viewer, to, raised, d).total;
        expect(after).toBeGreaterThanOrEqual(before - 1e-12);
      }
    }
    expect(CRITERIA.length).toBe(8);
  });
  test("g. exploration : bornee, plausible, sans doublon", () => {
    const limit = 25;
    for (const epsilon of [0, 0.1, 0.3]) {
      const p: MatchingParams = { ...DEFAULT_PARAMS, exploration: { epsilon, minScore: 0.35 } };
      for (const { seed, viewer, all, now } of scenes()) {
        const r = rankCandidates(viewer, all, context([], now), p, seed, limit);
        const explored = r.ranked.filter((c) => c.explored);
        expect(explored.length).toBeLessThanOrEqual(Math.floor(epsilon * limit));
        if (epsilon === 0) expect(explored.length).toBe(0);
        for (const c of explored) expect(c.reciprocal).toBeGreaterThanOrEqual(0.35);
        const ids = r.ranked.map((c) => c.userId);
        expect(new Set(ids).size).toBe(ids.length);
        expect(r.ranked.map((c) => c.rank)).toEqual(ids.map((_, i) => i + 1));
      }
    }
  });
  test("h. un candidat bloque tres compatible n'apparait jamais, meme booste", () => {
    for (const { seed, viewer, all, now } of scenes()) {
      const target = all.find((c) => c.userId !== viewer.userId && referenceAllows(viewer, c, DEFAULT_PARAMS));
      if (!target) continue;
      const boosted = { ...target, boostedUntil: new Date(Date.parse(now) + 86_400_000).toISOString(), lastActiveAt: now, verification: "identity" as const };
      const pool = all.map((c) => (c.userId === target.userId ? boosted : c));
      const p: MatchingParams = { ...DEFAULT_PARAMS, exploration: { epsilon: 0.3, minScore: 0 } };
      const r = rankCandidates(viewer, pool, context([target.userId], now), p, seed, 10);
      expect(r.ranked.map((c) => c.userId)).not.toContain(target.userId);
      expect(r.exclusions).toContainEqual({ userId: target.userId, reason: "excluded" });
    }
  });
});
