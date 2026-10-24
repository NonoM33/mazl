import { describe, expect, test } from "bun:test";
import { dueLabel, formatHours, formatNumber, groupBy4, relativeTime } from "../../console/src/shared/format";

const NOW = new Date("2026-10-24T12:00:00Z");
const at = (ms: number): string => new Date(NOW.getTime() + ms).toISOString();
const H = 3_600_000;

describe("relativeTime", () => {
  test("passé en minutes, heures, jours", () => {
    expect(relativeTime(at(-5 * 60_000), NOW)).toBe("il y a 5 min");
    expect(relativeTime(at(-3 * H), NOW)).toBe("il y a 3 h");
    expect(relativeTime(at(-50 * H), NOW)).toBe("il y a 2 j");
  });
  test("futur et instant", () => {
    expect(relativeTime(at(2 * H), NOW)).toBe("dans 2 h");
    expect(relativeTime(at(-20_000), NOW)).toBe("à l'instant");
  });
  test("au-delà de 30 jours : une date, et une date invalide est signalée", () => {
    expect(relativeTime(at(-40 * 24 * H), NOW)).toMatch(/2026/);
    expect(relativeTime("pas une date", NOW)).toBe("date inconnue");
  });
});

describe("dueLabel", () => {
  test("échéance à venir", () => {
    expect(dueLabel(at(3 * H), NOW)).toEqual({ text: "dans 3 h", late: false });
  });
  test("échéance dépassée = en retard", () => {
    expect(dueLabel(at(-2 * H), NOW)).toEqual({ text: "en retard de 2 h", late: true });
  });
});

describe("formatHours", () => {
  test("minutes, heures, jours, absence", () => {
    expect(formatHours(0.5)).toBe("30 min");
    expect(formatHours(5.25)).toBe("5,3 h");
    expect(formatHours(72)).toBe("3 j");
    expect(formatHours(null)).toBe("—");
  });
});

describe("nombres et clés", () => {
  test("séparateur français des milliers", () => {
    expect(formatNumber(12345).replace(/\s/g, " ")).toBe("12 345");
  });
  test("clé groupée par 4", () => {
    expect(groupBy4("JBSWY3DPEHPK3PXP")).toBe("JBSW Y3DP EHPK 3PXP");
    expect(groupBy4("abcde")).toBe("abcd e");
  });
});
