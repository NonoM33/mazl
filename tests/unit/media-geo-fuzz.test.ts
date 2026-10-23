import { describe, expect, test } from "bun:test";
import { createHash } from "node:crypto";
import {
  MAX_OFFSET_KM,
  fuzzCoordinates,
  clampDistanceMax,
  MIN_DISTANCE_MAX_KM,
  type Coordinates,
} from "../../src/features/media/domain/geo-fuzz";

// Expected behaviour from CONTRAT.md §2.2: grid of ~1 km, then a fixed
// per-user offset of at most 1 km; distance_max never below 5.

function haversineKm(a: Coordinates, b: Coordinates): number {
  const rad = (d: number): number => (d * Math.PI) / 180;
  const dLat = rad(b.latitude - a.latitude);
  const dLon = rad(b.longitude - a.longitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(h));
}

function seedOf(byte: number): Uint8Array {
  return new Uint8Array(32).fill(byte);
}

function randomSeed(n: number): Uint8Array {
  return new Uint8Array(createHash("sha256").update(`seed-${n}`).digest());
}

const PARIS: Coordinates = { latitude: 48.85837, longitude: 2.29448 };

describe("location fuzzing (contract 2.2)", () => {
  test("the exact position is never returned", () => {
    for (let n = 0; n < 50; n++) {
      const out = fuzzCoordinates(PARIS, randomSeed(n));
      expect(out.latitude === PARIS.latitude && out.longitude === PARIS.longitude).toBe(false);
    }
  });

  test("result stays within grid half-diagonal + 1 km of the exact point", () => {
    const worst = Math.SQRT1_2 + MAX_OFFSET_KM + 0.05; // 0.707 km snap + 1 km offset
    const spots: Coordinates[] = [PARIS, { latitude: -33.8688, longitude: 151.2093 }, { latitude: 64.1466, longitude: -21.9426 }, { latitude: 0.001, longitude: -0.001 }];
    for (const spot of spots) {
      for (let n = 0; n < 200; n++) {
        const out = fuzzCoordinates(spot, randomSeed(n));
        expect(haversineKm(spot, out)).toBeLessThanOrEqual(worst);
      }
    }
  });

  test("the offset itself never exceeds 1 km", () => {
    // Two points on the same grid node give the same snapped position, so the
    // distance between fuzzed results of two seeds is at most 2 km.
    const a = fuzzCoordinates(PARIS, randomSeed(1));
    for (let n = 2; n < 300; n++) {
      const b = fuzzCoordinates(PARIS, randomSeed(n));
      expect(haversineKm(a, b)).toBeLessThanOrEqual(2 * MAX_OFFSET_KM + 0.01);
    }
  });

  test("deterministic for a given seed (fixed per-user offset)", () => {
    expect(fuzzCoordinates(PARIS, seedOf(9))).toEqual(fuzzCoordinates(PARIS, seedOf(9)));
  });

  test("different users get different offsets", () => {
    const distinct = new Set<string>();
    for (let n = 0; n < 20; n++) {
      const o = fuzzCoordinates(PARIS, randomSeed(n));
      distinct.add(`${o.latitude.toFixed(6)},${o.longitude.toFixed(6)}`);
    }
    expect(distinct.size).toBeGreaterThan(15);
  });

  test("nearby points share the same grid cell, so moving 100 m does not move the result much", () => {
    const seed = randomSeed(3);
    const base = { latitude: 48.8566, longitude: 2.3522 };
    const near = { latitude: 48.8571, longitude: 2.3529 }; // about 80 m away
    const a = fuzzCoordinates(base, seed);
    const b = fuzzCoordinates(near, seed);
    // Either identical (same cell) or neighbouring cells (about 1 km apart).
    expect(haversineKm(a, b)).toBeLessThanOrEqual(1.6);
  });

  test("handles poles and the antimeridian without leaving valid ranges", () => {
    const edges: Coordinates[] = [
      { latitude: 89.99, longitude: 10 },
      { latitude: -89.99, longitude: -10 },
      { latitude: 10, longitude: 179.999 },
      { latitude: 10, longitude: -179.999 },
    ];
    for (const e of edges) {
      for (let n = 0; n < 50; n++) {
        const o = fuzzCoordinates(e, randomSeed(n));
        expect(Math.abs(o.latitude)).toBeLessThanOrEqual(90);
        expect(Math.abs(o.longitude)).toBeLessThanOrEqual(180);
        expect(Number.isFinite(o.latitude) && Number.isFinite(o.longitude)).toBe(true);
      }
    }
  });

  test("distance_max is raised to 5 km minimum", () => {
    expect(MIN_DISTANCE_MAX_KM).toBe(5);
    expect(clampDistanceMax(1)).toBe(5);
    expect(clampDistanceMax(4.9)).toBe(5);
    expect(clampDistanceMax(5)).toBe(5);
    expect(clampDistanceMax(100)).toBe(100);
  });
});
