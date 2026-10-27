import { ComplexZmanimCalendar, GeoLocation } from "kosher-zmanim";
import type { CalendarDay } from "../domain/local-time";
import type { CandleLighting } from "../domain/reminders";

// Candle lighting time of a place (kosher-zmanim): 18 minutes before sunset,
// 40 in Jerusalem. The calendar is built once for the place and reused.
export function candleLightingFor(latitude: number, longitude: number, timeZone: string): CandleLighting {
  const location = new GeoLocation("couple", latitude, longitude, 0, timeZone);
  const calendar = new ComplexZmanimCalendar(location);
  calendar.setCandleLightingOffset(timeZone === "Asia/Jerusalem" ? 40 : 18);
  return (day: CalendarDay) => {
    calendar.setDate(calendar.getDate().set({ year: day.year, month: day.month, day: day.day }));
    const lighting = calendar.getCandleLighting();
    return lighting === null ? null : lighting.toJSDate();
  };
}

// Paris, the place of a couple whose creator never gave one.
export const PARIS = { latitude: 48.8566, longitude: 2.3522 } as const;
