// When to launch a Boost (docs/premium/MONETISATION.md section 8): the hour of
// the week when the most members of the city open Discover. Counts only, never
// who: the table holds a number per city, weekday and hour (UTC).

// Below this many sessions a city is too quiet for its figures to mean anything
// (and to be shown without singling out its few members).
export const MIN_SESSIONS_FOR_A_CITY = 50;
// A Boost must be programmed at least this far ahead (the sweep runs every minute).
export const MIN_LEAD_MINUTES = 2;
export const MAX_LEAD_DAYS = 7;

export interface HourCount {
  // 0 = Sunday … 6 = Saturday, UTC (JavaScript's getUTCDay).
  readonly dow: number;
  readonly hour: number;
  readonly sessions: number;
}

export interface Slot {
  readonly dow: number;
  readonly hour: number;
}

export function totalSessions(counts: readonly HourCount[]): number {
  return counts.reduce((sum, count) => sum + count.sessions, 0);
}

// The busiest hour of the week; the earliest one in the week on a tie. Null when
// the city does not have enough sessions.
export function busiestSlot(counts: readonly HourCount[], minimum: number = MIN_SESSIONS_FOR_A_CITY): Slot | null {
  if (totalSessions(counts) < minimum) return null;
  let best: HourCount | null = null;
  for (const count of counts) {
    if (count.sessions <= 0) continue;
    if (best === null || count.sessions > best.sessions || (count.sessions === best.sessions && weekHour(count) < weekHour(best))) best = count;
  }
  return best === null ? null : { dow: best.dow, hour: best.hour };
}

const weekHour = (slot: Slot): number => slot.dow * 24 + slot.hour;

// The next time the slot comes round, at least `leadMinutes` after `from`.
export function nextOccurrence(slot: Slot, from: Date, leadMinutes: number = MIN_LEAD_MINUTES): Date {
  const earliest = from.getTime() + leadMinutes * 60_000;
  const candidate = new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate(), slot.hour));
  candidate.setUTCDate(candidate.getUTCDate() + ((slot.dow - candidate.getUTCDay() + 7) % 7));
  while (candidate.getTime() < earliest) candidate.setUTCDate(candidate.getUTCDate() + 7);
  return candidate;
}

// 1 = Monday … 7 = Sunday, as the app reads it.
export const isoWeekday = (date: Date): number => ((date.getUTCDay() + 6) % 7) + 1;

export type ScheduleVerdict = { readonly ok: true; readonly at: Date } | { readonly ok: false };

export function checkScheduleTime(raw: Date, now: Date): ScheduleVerdict {
  const ahead = raw.getTime() - now.getTime();
  if (Number.isNaN(ahead) || ahead < MIN_LEAD_MINUTES * 60_000 || ahead > MAX_LEAD_DAYS * 24 * 3_600_000) return { ok: false };
  return { ok: true, at: raw };
}

// The city of a profile's free-text location: « Paris, France » -> « paris ».
export function cityKeyOf(location: string | null): string | null {
  const first = (location ?? "").split(",")[0]?.trim().toLowerCase().replace(/\s+/g, " ") ?? "";
  return first === "" || first.length > 80 ? null : first;
}
