import { describe, expect, test } from "bun:test";
import { dayLabel, displayName, likesCount } from "../../web/src/shared/lib/format";

describe("formats", () => {
  test("likes are counted exactly up to ten, then by steps like the app", () => {
    expect([0, 7, 10, 11, 26, 51, 100, 4000].map(likesCount)).toEqual(["0", "7", "10", "10+", "25+", "50+", "99+", "99+"]);
  });

  test("chat days read Aujourd'hui, Hier, then the date", () => {
    const now = new Date(2026, 9, 24, 15);
    expect(dayLabel(new Date(2026, 9, 24, 1), now)).toBe("Aujourd'hui");
    expect(dayLabel(new Date(2026, 9, 23, 23), now)).toBe("Hier");
    expect(dayLabel(new Date(2026, 9, 20, 12), now)).toMatch(/^mar\.? 20 oct\.?$/);
  });

  test("a member without a name is never shown as blank", () => {
    expect(displayName("  ")).toBe("Membre MAZL");
    expect(displayName(null)).toBe("Membre MAZL");
    expect(displayName(" Léa ")).toBe("Léa");
  });
});
