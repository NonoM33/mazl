import { describe, expect, test } from "bun:test";
import { alignedThemes, lowestTheme, periodOf, previousPeriod, summarize, trendOf, type Ratings } from "../../../src/features/couple/domain/checkin";
import { CHEAP_MAX_CENTS, matchesFilter, pickFeatured, pickOfTheDay, publicOuting, type OutingCandidate } from "../../../src/features/couple/domain/outings";
import { zonedInstant } from "../../../src/features/couple/domain/local-time";

const r = (talk: number, time: number, close: number): Ratings => ({ talk, time, close });

describe("check-in alignment (contract section 6)", () => {
  test("aligned counts the themes whose notes differ by at most one", () => {
    expect(alignedThemes(r(4, 3, 5), r(5, 1, 4))).toBe(2); // 1 ok, 2 apart, 1 ok
    expect(alignedThemes(r(1, 1, 1), r(5, 5, 5))).toBe(0);
    expect(alignedThemes(r(3, 3, 3), r(3, 3, 3))).toBe(3);
    expect(alignedThemes(r(2, 2, 2), r(3, 4, 1))).toBe(2); // gaps 1, 2, 1
  });

  test("lowest is the theme with the lowest combined note, talk first on a tie", () => {
    expect(lowestTheme(r(4, 2, 5), r(4, 3, 5))).toBe("time");
    expect(lowestTheme(r(3, 3, 3), r(3, 3, 3))).toBe("talk");
  });

  test("trend compares with the previous complete month, null without one", () => {
    const now = [r(4, 4, 4), r(4, 4, 4)] as const;
    expect(trendOf(now, null)).toBeNull();
    expect(trendOf(now, [r(3, 3, 3), r(3, 3, 3)])).toBe("up");
    expect(trendOf(now, [r(5, 5, 5), r(5, 5, 5)])).toBe("down");
    expect(trendOf(now, [r(4, 4, 4), r(4, 4, 3)])).toBe("same");
  });

  test("the summary never carries a note of either member", () => {
    const summary = summarize([r(4, 3, 5), r(5, 1, 4)], null);
    expect(Object.keys(summary).sort()).toEqual(["aligned", "lowest", "trend"]);
    expect(summary).toEqual({ aligned: 2, lowest: "time", trend: null });
  });

  test("periods are YYYY-MM and January looks back to December", () => {
    expect(periodOf(2026, 11)).toBe("2026-11");
    expect(previousPeriod(2026, 1)).toBe("2025-12");
    expect(previousPeriod(2026, 11)).toBe("2026-10");
  });
});

const PARIS = "Europe/Paris";
const NOW = zonedInstant(2026, 10, 27, 15, 0, PARIS);
function outing(over: Partial<OutingCandidate>): OutingCandidate {
  return { id: 1, kind: "activity", title: "t", subtitle: "", imageUrl: null, city: "Paris", startsAt: null, priceCents: 5000, kosher: false, saved: false, partner: false, featured: false, ...over };
}

describe("outing filters (contract section 4)", () => {
  test("tonight keeps only what starts today in Paris", () => {
    const tonight = outing({ kind: "event", startsAt: zonedInstant(2026, 10, 27, 20, 0, PARIS).toISOString() });
    const tomorrow = outing({ kind: "event", startsAt: zonedInstant(2026, 10, 28, 20, 0, PARIS).toISOString() });
    expect(matchesFilter(tonight, "tonight", NOW, PARIS)).toBe(true);
    expect(matchesFilter(tomorrow, "tonight", NOW, PARIS)).toBe(false);
    expect(matchesFilter(outing({}), "tonight", NOW, PARIS)).toBe(false);
  });

  test("week keeps the next seven days inclusive", () => {
    const at = (d: number) => outing({ kind: "event", startsAt: zonedInstant(2026, 11, d, 10, 0, PARIS).toISOString() });
    expect(matchesFilter(at(3), "week", NOW, PARIS)).toBe(true); // 7 days ahead
    expect(matchesFilter(at(4), "week", NOW, PARIS)).toBe(false);
  });

  test("a late-evening event stays 'tonight' for Paris although it is already tomorrow in UTC", () => {
    const lateNight = outing({ kind: "event", startsAt: zonedInstant(2026, 10, 27, 23, 30, PARIS).toISOString() });
    expect(matchesFilter(lateNight, "tonight", NOW, PARIS)).toBe(true);
  });

  test("kosher, cheap and mazl", () => {
    expect(matchesFilter(outing({ kosher: true }), "kosher", NOW, PARIS)).toBe(true);
    expect(matchesFilter(outing({}), "kosher", NOW, PARIS)).toBe(false);
    expect(matchesFilter(outing({ priceCents: CHEAP_MAX_CENTS }), "cheap", NOW, PARIS)).toBe(true);
    expect(matchesFilter(outing({ priceCents: CHEAP_MAX_CENTS + 1 }), "cheap", NOW, PARIS)).toBe(false);
    expect(matchesFilter(outing({ priceCents: null }), "cheap", NOW, PARIS)).toBe(false);
    expect(matchesFilter(outing({ partner: true }), "mazl", NOW, PARIS)).toBe(true);
    expect(matchesFilter(outing({ kind: "event", featured: true }), "mazl", NOW, PARIS)).toBe(true);
    expect(matchesFilter(outing({}), "mazl", NOW, PARIS)).toBe(false);
  });

  test("no filter keeps everything; the public shape hides the internal flags", () => {
    expect(matchesFilter(outing({}), undefined, NOW, PARIS)).toBe(true);
    expect(Object.keys(publicOuting(outing({ partner: true, featured: true })))).not.toContain("partner");
  });

  test("the featured outing is a featured event, then a partner activity, then the first", () => {
    const plain = outing({ id: 1 });
    const partner = outing({ id: 2, partner: true });
    const event = outing({ id: 3, kind: "event", featured: true });
    expect(pickFeatured([plain, partner, event])?.id).toBe(3);
    expect(pickFeatured([plain, partner])?.id).toBe(2);
    expect(pickFeatured([plain])?.id).toBe(1);
    expect(pickFeatured([])).toBeNull();
  });

  test("the outing of the day is stable within a day and moves the next day", () => {
    const list = [1, 2, 3].map((id) => outing({ id }));
    expect(pickOfTheDay(list, 7, 100)?.id).toBe(pickOfTheDay(list, 7, 100)?.id);
    expect(pickOfTheDay(list, 7, 100)?.id).not.toBe(pickOfTheDay(list, 7, 101)?.id);
    expect(pickOfTheDay([], 7, 100)).toBeNull();
  });
});
