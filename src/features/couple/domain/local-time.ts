// Wall-clock arithmetic in an IANA time zone, without a date library.

export interface LocalParts {
  readonly year: number;
  readonly month: number; // 1-12
  readonly day: number;
  readonly hour: number;
  readonly minute: number;
  // 0 = Sunday.
  readonly weekday: number;
}

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatterFor(timeZone: string): Intl.DateTimeFormat {
  const cached = formatters.get(timeZone);
  if (cached !== undefined) return cached;
  const created = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
  formatters.set(timeZone, created);
  return created;
}

export function weekdayOf(year: number, month: number, day: number): number {
  return new Date(Date.UTC(year, month - 1, day)).getUTCDay();
}

export function localParts(instant: Date, timeZone: string): LocalParts {
  const values = new Map<string, number>();
  for (const part of formatterFor(timeZone).formatToParts(instant)) {
    if (part.type !== "literal") values.set(part.type, Number(part.value));
  }
  const year = values.get("year") ?? 1970;
  const month = values.get("month") ?? 1;
  const day = values.get("day") ?? 1;
  return { year, month, day, hour: values.get("hour") ?? 0, minute: values.get("minute") ?? 0, weekday: weekdayOf(year, month, day) };
}

function offsetMs(instant: Date, timeZone: string): number {
  const p = localParts(instant, timeZone);
  return Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute) - Math.floor(instant.getTime() / 60_000) * 60_000;
}

// The instant at which the wall clock of `timeZone` reads this date and time.
export function zonedInstant(year: number, month: number, day: number, hour: number, minute: number, timeZone: string): Date {
  const guess = Date.UTC(year, month - 1, day, hour, minute);
  const first = guess - offsetMs(new Date(guess), timeZone);
  return new Date(guess - offsetMs(new Date(first), timeZone));
}

export interface CalendarDay {
  readonly year: number;
  readonly month: number;
  readonly day: number;
}

export function addDays(day: CalendarDay, days: number): CalendarDay {
  const moved = new Date(Date.UTC(day.year, day.month - 1, day.day + days));
  return { year: moved.getUTCFullYear(), month: moved.getUTCMonth() + 1, day: moved.getUTCDate() };
}

export function dayKey(day: CalendarDay): string {
  return `${String(day.year).padStart(4, "0")}-${String(day.month).padStart(2, "0")}-${String(day.day).padStart(2, "0")}`;
}

export function daysBetween(from: CalendarDay, to: CalendarDay): number {
  return Math.round((Date.UTC(to.year, to.month - 1, to.day) - Date.UTC(from.year, from.month - 1, from.day)) / 86_400_000);
}

export const DEFAULT_TIME_ZONE = "Europe/Paris";

// The time zone of a place, from its coordinates, for the few regions the
// members live in. Anywhere else: Paris.
export function timeZoneFor(latitude: number | null, longitude: number | null): string {
  if (latitude === null || longitude === null) return DEFAULT_TIME_ZONE;
  if (latitude >= 29 && latitude <= 34 && longitude >= 34 && longitude <= 36) return "Asia/Jerusalem";
  if (latitude >= 24 && latitude <= 50 && longitude >= -85 && longitude <= -66) return "America/New_York";
  if (latitude >= 30 && latitude <= 50 && longitude >= -125 && longitude <= -114) return "America/Los_Angeles";
  if (latitude >= 50.2 && latitude <= 59 && longitude >= -8 && longitude <= 1.8) return "Europe/London";
  return DEFAULT_TIME_ZONE;
}
