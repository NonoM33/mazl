import { describe, expect, test } from "bun:test";
import { DEFAULT_PARAMS, SCALES } from "../../src/features/matching/domain/params";
import { syntheticNow, syntheticPopulation } from "../../src/features/matching/domain/synthetic";

describe("syntheticPopulation", () => {
  test("deterministic and independent of the clock", async () => {
    const a = syntheticPopulation(7, 80);
    await Bun.sleep(15);
    const b = syntheticPopulation(7, 80);
    expect(a).toEqual(b);
    expect(syntheticNow(7)).toBe(syntheticNow(7));
  });
  test("different seeds give different people", () => {
    expect(syntheticPopulation(1, 50)).not.toEqual(syntheticPopulation(2, 50));
  });
  test("size and ids 1..size, labels for every id", () => {
    const { profiles, labels } = syntheticPopulation(3, 120);
    expect(profiles.map((p) => p.userId)).toEqual(Array.from({ length: 120 }, (_, i) => i + 1));
    for (const p of profiles) {
      expect(labels[p.userId]?.name.length).toBeGreaterThan(0);
      expect(labels[p.userId]?.city.length).toBeGreaterThan(0);
    }
    expect(syntheticPopulation(3, 0).profiles).toEqual([]);
  });
  test("plausible distributions", () => {
    const { profiles } = syntheticPopulation(11, 400);
    for (const p of profiles) {
      if (p.age !== null) {
        expect(p.age).toBeGreaterThanOrEqual(22);
        expect(p.age).toBeLessThanOrEqual(45);
      }
      expect(p.ageMin).toBeLessThanOrEqual(p.ageMax);
      expect(Date.parse(p.lastActiveAt ?? syntheticNow(11))).toBeLessThanOrEqual(Date.parse(syntheticNow(11)));
    }
    const men = profiles.filter((p) => p.gender === "male").length;
    expect(men).toBeGreaterThan(160);
    expect(men).toBeLessThan(240);
    const opposite = profiles.filter((p) => p.lookingFor !== null && p.lookingFor !== "all" && p.lookingFor !== p.gender).length;
    expect(opposite / profiles.length).toBeGreaterThan(0.7);
    for (const scale of SCALES) {
      const known = profiles.filter((p) => p[scale] !== null);
      expect(known.length).toBeLessThan(profiles.length);
      expect(known.length).toBeGreaterThan(profiles.length * 0.85);
      void DEFAULT_PARAMS.scales[scale];
    }
    expect(profiles.some((p) => p.boostedUntil !== null)).toBe(true);
    expect(profiles.some((p) => p.openReports90d > 0)).toBe(true);
    expect(profiles.some((p) => p.denomination === "Séfarade")).toBe(true);
    const likes = profiles.map((p) => p.likesReceived7d).sort((a, b) => a - b);
    expect(likes[likes.length - 1]!).toBeGreaterThan(likes[Math.floor(likes.length / 2)]! * 3);
  });
});
