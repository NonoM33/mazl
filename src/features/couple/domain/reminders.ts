import { addDays, dayKey, daysBetween, localParts, weekdayOf, zonedInstant, type CalendarDay } from "./local-time";
import type { Ritual } from "./rituals";

// Which reminders are due now (docs/couple/ESPACE-COUPLE.md section 3). Pure:
// the clock, the time zone and the candle-lighting time are given.

// Date reminders go out at this local time on their day.
export const DATE_REMINDER_HOUR = 9;
// A ritual without a time starts here.
const DEFAULT_RITUAL_TIME = "09:00";
// Past this long after its start, a ritual reminder is no longer sent.
const GRACE_AFTER_START_MS = 0;

export interface CoupleDate {
  readonly id: number;
  readonly date: string; // YYYY-MM-DD
  readonly isRecurring: boolean;
  readonly remindDaysBefore: number;
}

export type ReminderPlan =
  | { readonly source: "date"; readonly refId: number; readonly occurrence: string; readonly daysAway: number }
  | { readonly source: "ritual"; readonly refId: number; readonly occurrence: string; readonly kind: Ritual["kind"]; readonly startsAt: Date };

function parseDay(value: string): CalendarDay {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  return { year: year ?? 1970, month: month ?? 1, day: day ?? 1 };
}

// The next time the date comes round on or after `today` (the date itself when it
// is not recurring and still to come). Feb 29 falls on Mar 1 in common years.
export function nextOccurrence(date: Pick<CoupleDate, "date" | "isRecurring">, today: CalendarDay): CalendarDay | null {
  const base = parseDay(date.date);
  if (!date.isRecurring) return daysBetween(today, base) >= 0 ? base : null;
  for (const year of [today.year, today.year + 1]) {
    const leapFix = base.month === 2 && base.day === 29 && new Date(Date.UTC(year, 1, 29)).getUTCMonth() !== 1;
    const candidate: CalendarDay = leapFix ? { year, month: 3, day: 1 } : { year, month: base.month, day: base.day };
    if (daysBetween(today, candidate) >= 0) return candidate;
  }
  return null;
}

// The day before, and `remindDaysBefore` days before when that is two or more.
export function planDateReminders(dates: readonly CoupleDate[], now: Date, timeZone: string): ReminderPlan[] {
  const local = localParts(now, timeZone);
  if (local.hour < DATE_REMINDER_HOUR) return [];
  const today: CalendarDay = { year: local.year, month: local.month, day: local.day };
  const plans: ReminderPlan[] = [];
  for (const date of dates) {
    const occurrence = nextOccurrence(date, today);
    if (occurrence === null) continue;
    const away = daysBetween(today, occurrence);
    const key = dayKey(occurrence);
    if (away === 1) plans.push({ source: "date", refId: date.id, occurrence: `${key}:eve`, daysAway: 1 });
    else if (away >= 2 && away === date.remindDaysBefore) plans.push({ source: "date", refId: date.id, occurrence: `${key}:d${String(away)}`, daysAway: away });
  }
  return plans;
}

export type CandleLighting = (day: CalendarDay) => Date | null;

// The next start of a ritual on or after today (today's start counts while it
// has not begun). Shabbat starts at candle lighting.
export function nextRitualStart(ritual: Ritual, today: CalendarDay, timeZone: string, candleLighting: CandleLighting): { day: CalendarDay; at: Date } | null {
  if (ritual.weekday === null) return null;
  for (let offset = 0; offset < 8; offset += 1) {
    const day = addDays(today, offset);
    if (weekdayOf(day.year, day.month, day.day) !== ritual.weekday) continue;
    if (ritual.kind === "shabbat") {
      const at = candleLighting(day);
      return at === null ? null : { day, at };
    }
    const [hour, minute] = (ritual.time ?? DEFAULT_RITUAL_TIME).split(":").map(Number);
    return { day, at: zonedInstant(day.year, day.month, day.day, hour ?? 9, minute ?? 0, timeZone) };
  }
  return null;
}

// An enabled ritual whose reminder moment (start minus remind_minutes) has come
// and whose start has not.
export function planRitualReminders(rituals: readonly Ritual[], now: Date, timeZone: string, candleLighting: CandleLighting): ReminderPlan[] {
  const local = localParts(now, timeZone);
  const today: CalendarDay = { year: local.year, month: local.month, day: local.day };
  const plans: ReminderPlan[] = [];
  for (const ritual of rituals) {
    if (!ritual.enabled) continue;
    const start = nextRitualStart(ritual, today, timeZone, candleLighting);
    if (start === null) continue;
    const remindAt = start.at.getTime() - ritual.remindMinutes * 60_000;
    if (now.getTime() >= remindAt && now.getTime() <= start.at.getTime() + GRACE_AFTER_START_MS) {
      plans.push({ source: "ritual", refId: ritual.id, occurrence: dayKey(start.day), kind: ritual.kind, startsAt: start.at });
    }
  }
  return plans;
}
