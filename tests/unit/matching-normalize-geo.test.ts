import { describe, expect, test } from "bun:test";
import { distanceKm } from "../../src/features/matching/domain/geo";
import { answerKey, rankOf } from "../../src/features/matching/domain/normalize";

describe("answerKey", () => {
  test("lowercases, strips accents, maps spaces and dashes to underscores", () => {
    expect(answerKey("  Orthodoxe Moderne ")).toBe("orthodoxe_moderne");
    expect(answerKey("Laïque")).toBe("laique");
    expect(answerKey("Kasher-à la maison")).toBe("kasher_a_la_maison");
    expect(answerKey("Très observant")).toBe("tres_observant");
    expect(answerKey("ÉÈÊËÎÏÔÙÛÂÇ")).toBe("eeeeiiouuac");
  });
  test("empty stays empty", () => {
    expect(answerKey("   ")).toBe("");
  });
});

describe("rankOf", () => {
  const scale = { laique: 0, massorti: 2, orthodoxe: 4 };
  test("finds a rank through normalisation", () => {
    expect(rankOf(scale, "Massorti")).toBe(2);
    expect(rankOf(scale, "LAÏQUE")).toBe(0);
  });
  test("null for empty, unknown, or autre", () => {
    expect(rankOf(scale, null)).toBeNull();
    expect(rankOf(scale, "")).toBeNull();
    expect(rankOf(scale, "Séfarade")).toBeNull();
    expect(rankOf(scale, "Autre")).toBeNull();
  });
  test("does not leak prototype members", () => {
    expect(rankOf(scale, "constructor")).toBeNull();
    expect(rankOf(scale, "toString")).toBeNull();
  });
});

describe("distanceKm", () => {
  test("zero for the same point", () => {
    expect(distanceKm({ latitude: 48.85, longitude: 2.35 }, { latitude: 48.85, longitude: 2.35 })).toBe(0);
  });
  test("Paris to Lyon is about 392 km", () => {
    const d = distanceKm({ latitude: 48.8566, longitude: 2.3522 }, { latitude: 45.764, longitude: 4.8357 });
    expect(Math.abs(d - 392)).toBeLessThan(3);
  });
  test("one degree of latitude is 111.19 km with R = 6371", () => {
    const d = distanceKm({ latitude: 0, longitude: 0 }, { latitude: 1, longitude: 0 });
    expect(d).toBeCloseTo(111.19, 1);
  });
  test("symmetric", () => {
    const a = { latitude: 43.7, longitude: 7.26 };
    const b = { latitude: 50.63, longitude: 3.06 };
    expect(distanceKm(a, b)).toBeCloseTo(distanceKm(b, a), 9);
  });
});
