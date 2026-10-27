import { JewishCalendar, JewishDate } from "kosher-zmanim";
import { addDays, isoDay, parisMidnight, weekday, type IsoDay } from "./paris-time";
import { THEMES, type HebrewMonthName, type Theme, type ThemeId, type ThemeRule } from "./themes";

// Dates of the seasonal themes (docs/storefront/themes.json), Europe/Paris.

export interface ThemeDates {
  readonly themeId: ThemeId;
  // First and last civil day of the event itself (a Jewish holiday starts the evening before its first day).
  readonly eventStart: IsoDay;
  readonly eventEnd: IsoDay;
  // The campaign window: [startsAt, endsAt) with endsAt the midnight after the last day.
  readonly startsAt: Date;
  readonly endsAt: Date;
}

// Years 3, 6, 8, 11, 14, 17 and 19 of the 19-year cycle have an Adar I and an Adar II.
function isHebrewLeapYear(hebrewYear: number): boolean {
  return (7 * hebrewYear + 1) % 19 < 7;
}

function hebrewMonthNumber(month: HebrewMonthName, hebrewYear: number): number {
  switch (month) {
    case "tishrei":
      return JewishDate.TISHREI;
    case "kislev":
      return JewishDate.KISLEV;
    case "av":
      return JewishDate.AV;
    case "nisan":
      return JewishDate.NISSAN;
    case "adar":
      return isHebrewLeapYear(hebrewYear) ? JewishDate.ADAR_II : JewishDate.ADAR;
  }
}

// The Gregorian day of a Hebrew date that falls in the Gregorian `year`.
function hebrewDay(year: number, month: HebrewMonthName, day: number): IsoDay {
  for (const hebrewYear of [year + 3760, year + 3761]) {
    const date = new JewishCalendar(hebrewYear, hebrewMonthNumber(month, hebrewYear), day);
    // kosher-zmanim counts Gregorian months from 0, like Date.
    if (date.getGregorianYear() === year) return isoDay(year, date.getGregorianMonth() + 1, date.getGregorianDayOfMonth());
  }
  throw new Error(`No ${month} ${String(day)} in ${String(year)}`);
}

// Western Easter Sunday (Meeus/Jones/Butcher).
export function easterSunday(year: number): IsoDay {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return isoDay(year, month, day);
}

// Last Sunday of May, or the first Sunday of June when that Sunday is Pentecost.
export function frenchMothersDay(year: number): IsoDay {
  let lastSunday = isoDay(year, 5, 31);
  while (weekday(lastSunday) !== 0) lastSunday = addDays(lastSunday, -1);
  const pentecost = addDays(easterSunday(year), 49);
  return lastSunday === pentecost ? addDays(lastSunday, 7) : lastSunday;
}

// The day after the fourth Thursday of November (the American Thanksgiving).
export function blackFriday(year: number): IsoDay {
  let thursday = isoDay(year, 11, 1);
  while (weekday(thursday) !== 4) thursday = addDays(thursday, 1);
  return addDays(thursday, 21 + 1);
}

function eventStartOf(rule: ThemeRule, year: number): IsoDay {
  switch (rule.type) {
    case "fixed":
      return isoDay(year, rule.month, rule.day);
    case "hebrew":
      return hebrewDay(year, rule.month, rule.day);
    case "fr_mothers_day":
      return frenchMothersDay(year);
    case "black_friday":
      return blackFriday(year);
  }
}

export function themeDates(theme: Theme, year: number): ThemeDates {
  const eventStart = eventStartOf(theme.rule, year);
  const eventEnd = addDays(eventStart, theme.rule.days - 1);
  // A Jewish holiday begins at sundown: the window opens the day before.
  const before = theme.window[0] + (theme.rule.type === "hebrew" ? 1 : 0);
  return {
    themeId: theme.id,
    eventStart,
    eventEnd,
    startsAt: parisMidnight(addDays(eventStart, -before)),
    endsAt: parisMidnight(addDays(eventEnd, theme.window[1] + 1)),
  };
}

export function calendarForYear(year: number): readonly ThemeDates[] {
  return THEMES.map((theme) => themeDates(theme, year));
}
