import { describe, expect, test } from "bun:test";
import { blackFriday, calendarForYear, easterSunday, frenchMothersDay, themeDates } from "../../../src/features/storefront/domain/calendar";
import { formatParis, parisDay, parisMidnight } from "../../../src/features/storefront/domain/paris-time";
import { THEMES, themeById, type ThemeId } from "../../../src/features/storefront/domain/themes";

// Every expected date below was checked outside the code under test:
//  - Jewish dates: ICU's independent Hebrew calendar (Intl "en-u-ca-hebrew") and
//    the published holiday tables (Hebcal); a Jewish day starts at sundown, so a
//    holiday "begins the evening of" the day before its Gregorian date.
//  - Easter / Pentecost: Easter 2009 and 2020 were both on 12 April, 2015 and 2026
//    on 5 April, 2027 on 28 March; Pentecost is 49 days later.
//  - Mothers' Day in France: last Sunday of May, moved to the first Sunday of June
//    when it is Pentecost (7 June 2009 and 7 June 2020 were the moved ones).
//  - Black Friday is the day after the American Thanksgiving (4th Thursday of
//    November): 29 Nov 2024, 28 Nov 2025, 27 Nov 2026, 26 Nov 2027.

const dates = (id: ThemeId, year: number) => themeDates(themeById(id), year);
const instant = (date: Date): string => date.toISOString();

describe("Jewish holidays", () => {
  test("Rosh Hashana 5787 is 12 September 2026 (it begins the evening of the 11th)", () => {
    const d = dates("rosh_hashana", 2026);
    expect([d.eventStart, d.eventEnd]).toEqual(["2026-09-12", "2026-09-13"]);
  });

  test("Rosh Hashana 5786 is 23 September 2025 and 5788 is 2 October 2027", () => {
    expect(dates("rosh_hashana", 2025).eventStart).toBe("2025-09-23");
    expect(dates("rosh_hashana", 2027).eventStart).toBe("2027-10-02");
  });

  test("Hanukkah 2026 begins the evening of 4 December: 25 Kislev is 5 December, eight days", () => {
    const d = dates("hanukkah", 2026);
    expect([d.eventStart, d.eventEnd]).toEqual(["2026-12-05", "2026-12-12"]);
    expect(dates("hanukkah", 2025).eventStart).toBe("2025-12-15");
  });

  test("Purim 2027 is 23 March 2027 (Adar II, 5787 is a leap year) and Purim 2026 is 3 March 2026 (Adar)", () => {
    expect(dates("purim", 2027).eventStart).toBe("2027-03-23");
    expect(dates("purim", 2026).eventStart).toBe("2026-03-03");
  });

  test("Passover 2027 is 22 April 2027 for seven days; 2026 is 2 April", () => {
    const d = dates("passover", 2027);
    expect([d.eventStart, d.eventEnd]).toEqual(["2027-04-22", "2027-04-28"]);
    expect(dates("passover", 2026).eventStart).toBe("2026-04-02");
  });

  test("Tu BeAv 2026 is 29 July 2026 (15 Av 5786, six days after Tisha BeAv, 23 July)", () => {
    expect(dates("tu_bav", 2026).eventStart).toBe("2026-07-29");
  });

  test("the window of a Jewish holiday opens one day earlier than the theme's own count", () => {
    // Hanukkah: window [2, 0] → 5 Dec minus 2, minus 1 for the eve = 2 Dec; ends after 12 Dec.
    const d = dates("hanukkah", 2026);
    expect(instant(d.startsAt)).toBe("2026-12-01T23:00:00.000Z"); // 2 Dec 00:00 Paris (CET)
    expect(instant(d.endsAt)).toBe("2026-12-12T23:00:00.000Z"); // 13 Dec 00:00 Paris
    // Rosh Hashana: window [7, 0] → 12 Sep minus 8 = 4 Sep (CEST, UTC+2).
    expect(instant(dates("rosh_hashana", 2026).startsAt)).toBe("2026-09-03T22:00:00.000Z");
    expect(instant(dates("rosh_hashana", 2026).endsAt)).toBe("2026-09-13T22:00:00.000Z"); // 14 Sep 00:00 Paris
  });
});

describe("fixed and computed dates", () => {
  test("Valentine's Day 2027: 7 to 14 February, the campaign ends at 00:00 on the 15th (Paris, winter time)", () => {
    const d = dates("valentine", 2027);
    expect([d.eventStart, d.eventEnd]).toEqual(["2027-02-14", "2027-02-14"]);
    expect(instant(d.startsAt)).toBe("2027-02-06T23:00:00.000Z");
    expect(instant(d.endsAt)).toBe("2027-02-14T23:00:00.000Z");
    expect(formatParis(d.endsAt)).toBe("2027-02-15T00:00:00+01:00");
  });

  test("New Year 2027 opens on 28 December 2026", () => {
    const d = dates("new_year", 2027);
    expect(d.eventStart).toBe("2027-01-01");
    expect(parisDay(d.startsAt)).toBe("2026-12-28");
    expect(parisDay(d.endsAt)).toBe("2027-01-04");
  });

  test("Christmas 2026 runs from 15 to 26 December", () => {
    const d = dates("christmas", 2026);
    expect(parisDay(d.startsAt)).toBe("2026-12-15");
    expect(parisDay(new Date(d.endsAt.getTime() - 1))).toBe("2026-12-26");
  });

  test("Mothers' Day in France 2027 is 30 May 2027", () => {
    expect(frenchMothersDay(2027)).toBe("2027-05-30");
    expect(dates("mothers_day", 2027).eventStart).toBe("2027-05-30");
  });

  test("Mothers' Day: last Sunday of May, except when it is Pentecost", () => {
    expect(frenchMothersDay(2025)).toBe("2025-05-25");
    expect(frenchMothersDay(2026)).toBe("2026-05-31");
    expect(frenchMothersDay(2015)).toBe("2015-05-31");
    // Pentecost fell on 31 May in 2009 and 2020: the day moved to the first Sunday of June.
    expect(frenchMothersDay(2009)).toBe("2009-06-07");
    expect(frenchMothersDay(2020)).toBe("2020-06-07");
  });

  test("Easter dates", () => {
    expect(easterSunday(2009)).toBe("2009-04-12");
    expect(easterSunday(2020)).toBe("2020-04-12");
    expect(easterSunday(2026)).toBe("2026-04-05");
    expect(easterSunday(2027)).toBe("2027-03-28");
  });

  test("Black Friday is the day after the fourth Thursday, not the fourth Friday", () => {
    expect(blackFriday(2024)).toBe("2024-11-29"); // the 4th Friday would be the 22nd
    expect(blackFriday(2025)).toBe("2025-11-28");
    expect(blackFriday(2026)).toBe("2026-11-27");
    expect(blackFriday(2027)).toBe("2027-11-26");
    const d = dates("black_friday", 2027);
    expect([d.eventStart, d.eventEnd]).toEqual(["2027-11-26", "2027-11-29"]);
  });

  test("summer: 1 to 14 July", () => {
    const d = dates("summer", 2027);
    expect([d.eventStart, d.eventEnd]).toEqual(["2027-07-01", "2027-07-14"]);
    expect(instant(d.startsAt)).toBe("2027-06-30T22:00:00.000Z");
  });
});

describe("Paris time", () => {
  test("midnight on the day the clocks change is still winter time (28 March 2027)", () => {
    expect(instant(parisMidnight("2027-03-28"))).toBe("2027-03-27T23:00:00.000Z");
    expect(instant(parisMidnight("2027-03-29"))).toBe("2027-03-28T22:00:00.000Z");
    expect(instant(parisMidnight("2026-10-25"))).toBe("2026-10-24T22:00:00.000Z");
    expect(instant(parisMidnight("2026-10-26"))).toBe("2026-10-25T23:00:00.000Z");
  });

  test("formatParis writes the Paris offset", () => {
    expect(formatParis(new Date("2027-07-01T10:30:00Z"))).toBe("2027-07-01T12:30:00+02:00");
    expect(formatParis(new Date("2027-01-01T10:30:00Z"))).toBe("2027-01-01T11:30:00+01:00");
  });
});

describe("every theme, every year", () => {
  test("a window is valid and at most 45 days, for ten years", () => {
    for (let year = 2026; year <= 2035; year += 1) {
      const all = calendarForYear(year);
      expect(all).toHaveLength(THEMES.length);
      for (const d of all) {
        const days = (d.endsAt.getTime() - d.startsAt.getTime()) / 86_400_000;
        expect(days).toBeGreaterThan(0);
        expect(days).toBeLessThanOrEqual(45);
        expect(d.eventStart <= d.eventEnd).toBe(true);
        expect(parisDay(d.startsAt) <= d.eventStart).toBe(true);
        expect(parisDay(parisMidnight(parisDay(d.startsAt)))).toBe(parisDay(d.startsAt));
        if (d.themeId !== "new_year") expect(d.eventStart.startsWith(String(year))).toBe(true);
      }
    }
  });
});
