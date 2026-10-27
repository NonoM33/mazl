import { z } from "zod";

// The monthly check-in of the couple (docs/couple/ESPACE-COUPLE.md section 6):
// each member rates three themes from 1 to 5, alone. The couple only ever sees a
// summary once both answered, never a note of the other.

export const THEMES = ["talk", "time", "close"] as const;
export type Theme = (typeof THEMES)[number];
export type Ratings = Readonly<Record<Theme, number>>;

const note = z.number().int().min(1).max(5);
export const checkinBody = z.object({ talk: note, time: note, close: note }).strict();

export interface CheckinSummary {
  readonly aligned: 0 | 1 | 2 | 3;
  readonly lowest: Theme;
  readonly trend: "up" | "down" | "same" | null;
}

// Two notes agree when they differ by at most one point.
export function alignedThemes(a: Ratings, b: Ratings): 0 | 1 | 2 | 3 {
  return THEMES.filter((theme) => Math.abs(a[theme] - b[theme]) <= 1).length as 0 | 1 | 2 | 3;
}

// The theme with the lowest combined note; the first of talk, time, close on a tie.
export function lowestTheme(a: Ratings, b: Ratings): Theme {
  let lowest: Theme = "talk";
  for (const theme of THEMES) if (a[theme] + b[theme] < a[lowest] + b[lowest]) lowest = theme;
  return lowest;
}

function mean(a: Ratings, b: Ratings): number {
  return THEMES.reduce((sum, theme) => sum + a[theme] + b[theme], 0) / (THEMES.length * 2);
}

// Against the previous month's complete check-in: a mean that moves by 0.3 or
// more is a trend. Null without a previous complete month.
export function trendOf(now: readonly [Ratings, Ratings], previous: readonly [Ratings, Ratings] | null): CheckinSummary["trend"] {
  if (previous === null) return null;
  const delta = mean(now[0], now[1]) - mean(previous[0], previous[1]);
  if (delta >= 0.3) return "up";
  if (delta <= -0.3) return "down";
  return "same";
}

export function summarize(now: readonly [Ratings, Ratings], previous: readonly [Ratings, Ratings] | null): CheckinSummary {
  return { aligned: alignedThemes(now[0], now[1]), lowest: lowestTheme(now[0], now[1]), trend: trendOf(now, previous) };
}

// "2026-11" for a local month, and the month before it.
export function periodOf(year: number, month: number): string {
  return `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}`;
}

export function previousPeriod(year: number, month: number): string {
  return month === 1 ? periodOf(year - 1, 12) : periodOf(year, month - 1);
}
