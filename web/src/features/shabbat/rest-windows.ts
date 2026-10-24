import { ComplexZmanimCalendar, GeoLocation, JewishCalendar } from "kosher-zmanim";

// Shabbat and Yom Tov windows, computed like the app
// (mobile/lib/core/services/jewish_calendar_service.dart, kosher_dart):
// diaspora, candle lighting 18 minutes before sunset on the eve, end at
// nightfall with the sun 8.5° below the horizon. The window opens `bufferMin`
// earlier still (the app's « Marge avant l'allumage », 0 to 30 min).

export interface Place { readonly name: string; readonly latitude: number; readonly longitude: number; readonly timeZone: string }
export interface RestOptions { readonly includeHolidays: boolean; readonly bufferMin: number }
export interface RestWindow { readonly start: Date; readonly end: Date; readonly holiday: boolean }

export const PARIS: Place = { name: "Paris", latitude: 48.8566, longitude: 2.3522, timeZone: "Europe/Paris" };
const CANDLE_LIGHTING_MIN = 18;
const DAY_MS = 86_400_000;

function noonOf(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12, 0, 0);
}

function isRestDay(day: Date, includeHolidays: boolean): { rest: boolean; holiday: boolean } {
  const calendar = new JewishCalendar(day);
  calendar.setInIsrael(false);
  calendar.setUseModernHolidays(true);
  const shabbat = day.getDay() === 6;
  const yomTov = calendar.isAssurBemelacha() && !shabbat;
  return { rest: shabbat || (includeHolidays && yomTov), holiday: yomTov };
}

function zmanim(day: Date, place: Place): ComplexZmanimCalendar {
  const calendar = new ComplexZmanimCalendar(new GeoLocation(place.name, place.latitude, place.longitude, 35, place.timeZone));
  calendar.setCandleLightingOffset(CANDLE_LIGHTING_MIN);
  calendar.setDate(day);
  return calendar;
}

function candleLighting(eve: Date, place: Place): Date | null {
  return zmanim(eve, place).getCandleLighting()?.toJSDate() ?? null;
}

function nightfall(day: Date, place: Place): Date | null {
  return zmanim(day, place).getTzaisGeonim8Point5Degrees()?.toJSDate() ?? null;
}

// Windows that end after `from`, looking `days` ahead (dates in the browser's
// calendar, which is the member's).
export function restWindows(from: Date, place: Place, options: RestOptions, days = 10): readonly RestWindow[] {
  const windows: RestWindow[] = [];
  let spanStart: Date | null = null;
  let holiday = false;
  for (let offset = -1; offset <= days; offset += 1) {
    const day = noonOf(new Date(from.getTime() + offset * DAY_MS));
    const state = isRestDay(day, options.includeHolidays);
    if (state.rest) {
      spanStart ??= day;
      holiday ||= state.holiday;
      continue;
    }
    if (spanStart !== null) {
      const lastDay = new Date(day.getTime() - DAY_MS);
      const start = candleLighting(new Date(spanStart.getTime() - DAY_MS), place);
      const end = nightfall(lastDay, place);
      if (start && end && end > from) windows.push({ start: new Date(start.getTime() - options.bufferMin * 60_000), end, holiday });
      spanStart = null;
      holiday = false;
    }
  }
  return windows;
}

export function activeWindow(now: Date, place: Place, options: RestOptions): RestWindow | null {
  return restWindows(now, place, options).find((window) => window.start <= now && now < window.end) ?? null;
}

export function nextWindow(now: Date, place: Place, options: RestOptions): RestWindow | null {
  return restWindows(now, place, options).find((window) => window.end > now) ?? null;
}
