import { addDays, daysBetween, localParts, zonedInstant, type CalendarDay } from "./local-time";
import { nextOccurrence, nextRitualStart, type CandleLighting } from "./reminders";
import type { Ritual } from "./rituals";

// "À venir" of the Today screen: the next five things on 45 days, from the
// couple's dates, their enabled rituals and their event registrations.

export const UPCOMING_DAYS = 45;
export const UPCOMING_COUNT = 5;

export interface UpcomingItem {
  readonly kind: "date" | "ritual" | "event";
  readonly title: string;
  readonly at: string;
  readonly subtitle: string;
  readonly refId: number;
}

export interface UpcomingDate {
  readonly id: number;
  readonly title: string;
  readonly type: string;
  readonly date: string;
  readonly isRecurring: boolean;
}

export interface UpcomingEvent {
  readonly id: number;
  readonly title: string;
  readonly place: string;
  readonly day: string; // YYYY-MM-DD
  readonly time: string | null; // HH:MM
}

export interface UpcomingInput {
  readonly now: Date;
  readonly timeZone: string;
  readonly dates: readonly UpcomingDate[];
  readonly rituals: readonly Ritual[];
  readonly events: readonly UpcomingEvent[];
  readonly candleLighting: CandleLighting;
}

export function buildUpcoming(input: UpcomingInput): UpcomingItem[] {
  const local = localParts(input.now, input.timeZone);
  const today: CalendarDay = { year: local.year, month: local.month, day: local.day };
  const limit = addDays(today, UPCOMING_DAYS);
  const items: UpcomingItem[] = [];

  for (const date of input.dates) {
    const occurrence = nextOccurrence(date, today);
    if (occurrence === null || daysBetween(occurrence, limit) < 0) continue;
    items.push({ kind: "date", title: date.title, at: zonedInstant(occurrence.year, occurrence.month, occurrence.day, 0, 0, input.timeZone).toISOString(), subtitle: date.type, refId: date.id });
  }
  for (const ritual of input.rituals) {
    if (!ritual.enabled) continue;
    const start = nextRitualStart(ritual, today, input.timeZone, input.candleLighting);
    if (start === null || start.at.getTime() < input.now.getTime()) continue;
    items.push({ kind: "ritual", title: ritual.title, at: start.at.toISOString(), subtitle: ritual.kind, refId: ritual.id });
  }
  for (const event of input.events) {
    const [year, month, day] = event.day.split("-").map(Number);
    const [hour, minute] = (event.time ?? "00:00").split(":").map(Number);
    const at = zonedInstant(year ?? 1970, month ?? 1, day ?? 1, hour ?? 0, minute ?? 0, input.timeZone);
    if (daysBetween(today, { year: year ?? 1970, month: month ?? 1, day: day ?? 1 }) < 0 || daysBetween({ year: year ?? 1970, month: month ?? 1, day: day ?? 1 }, limit) < 0) continue;
    items.push({ kind: "event", title: event.title, at: at.toISOString(), subtitle: event.place, refId: event.id });
  }
  return items.sort((a, b) => a.at.localeCompare(b.at)).slice(0, UPCOMING_COUNT);
}
