// Europe/Paris calendar helpers. A "day" is a civil date, YYYY-MM-DD.

export type IsoDay = string;

const DAY_MS = 86_400_000;
const PARIS = "Europe/Paris";

const parts = new Intl.DateTimeFormat("en-GB", {
  timeZone: PARIS,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

function parisFields(instant: Date): { y: number; m: number; d: number; h: number; mi: number; s: number } {
  const read = (type: string): number => Number(parts.formatToParts(instant).find((p) => p.type === type)?.value);
  return { y: read("year"), m: read("month"), d: read("day"), h: read("hour"), mi: read("minute"), s: read("second") };
}

const pad = (n: number): string => String(n).padStart(2, "0");

export function isoDay(year: number, month: number, day: number): IsoDay {
  return `${String(year).padStart(4, "0")}-${pad(month)}-${pad(day)}`;
}

export function parseDay(day: IsoDay): { year: number; month: number; day: number } {
  const [y, m, d] = day.split("-").map(Number);
  return { year: y ?? 0, month: m ?? 0, day: d ?? 0 };
}

function dayToUtcMs(day: IsoDay): number {
  const { year, month, day: d } = parseDay(day);
  return Date.UTC(year, month - 1, d);
}

export function addDays(day: IsoDay, days: number): IsoDay {
  const shifted = new Date(dayToUtcMs(day) + days * DAY_MS);
  return isoDay(shifted.getUTCFullYear(), shifted.getUTCMonth() + 1, shifted.getUTCDate());
}

export function daysBetween(from: IsoDay, to: IsoDay): number {
  return Math.round((dayToUtcMs(to) - dayToUtcMs(from)) / DAY_MS);
}

// 0 = Sunday … 6 = Saturday.
export function weekday(day: IsoDay): number {
  return new Date(dayToUtcMs(day)).getUTCDay();
}

// The Paris civil date of an instant.
export function parisDay(instant: Date): IsoDay {
  const f = parisFields(instant);
  return isoDay(f.y, f.m, f.d);
}

// The instant at which a Paris civil day begins (00:00 local, DST-safe: the
// clocks never change at midnight in France).
export function parisMidnight(day: IsoDay): Date {
  const base = dayToUtcMs(day);
  for (const offsetHours of [1, 2]) {
    const candidate = new Date(base - offsetHours * 3_600_000);
    const f = parisFields(candidate);
    if (f.h === 0 && f.mi === 0 && f.s === 0 && isoDay(f.y, f.m, f.d) === day) return candidate;
  }
  throw new Error(`No Paris midnight for ${day}`);
}

// "2027-02-15T00:00:00+01:00": the instant written with its Paris offset.
export function formatParis(instant: Date): string {
  const f = parisFields(instant);
  const local = Date.UTC(f.y, f.m - 1, f.d, f.h, f.mi, f.s);
  const offsetMinutes = Math.round((local - Math.floor(instant.getTime() / 1000) * 1000) / 60_000);
  const sign = offsetMinutes >= 0 ? "+" : "-";
  const abs = Math.abs(offsetMinutes);
  return `${isoDay(f.y, f.m, f.d)}T${pad(f.h)}:${pad(f.mi)}:${pad(f.s)}${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`;
}
