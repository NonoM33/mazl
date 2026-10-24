import { formatDate, formatEuros } from "../../shared/lib/format";
import type { RelationshipStatus } from "../../shared/api/types";
import type { Activity, CoupleEvent, DailyQuestion } from "./couple-api";

// Wording of the couple screens, from the app (mobile/lib/.../couple).

export const STATUS_OPTIONS: readonly { readonly key: RelationshipStatus; readonly label: string }[] = [
  { key: "dating", label: "En couple depuis peu" },
  { key: "in_relationship", label: "En couple" },
  { key: "engaged", label: "Fiancés" },
  { key: "married", label: "Mariés" },
];

export const statusLabel = (status: RelationshipStatus): string => STATUS_OPTIONS.find((option) => option.key === status)?.label ?? "En couple";

const DAY_MS = 86_400_000;
const startOfDay = (date: Date): number => new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();

export function daysTogether(startedAt: string | null, now: Date = new Date()): number | null {
  if (!startedAt) return null;
  return Math.max(0, Math.floor((startOfDay(now) - startOfDay(new Date(startedAt))) / DAY_MS));
}

export const togetherSince = (startedAt: string | null): string | null => (startedAt ? `Ensemble depuis le ${formatDate(startedAt)}` : null);

// `type` is what the server records (checkAndRecordMilestones); it records
// nothing for two years, which stays computed from the days together.
export const MILESTONES: readonly { readonly days: number; readonly label: string; readonly type: string | null }[] = [
  { days: 7, label: "1 semaine", type: "first_week" },
  { days: 30, label: "1 mois", type: "first_month" },
  { days: 90, label: "3 mois", type: "three_months" },
  { days: 180, label: "6 mois", type: "six_months" },
  { days: 365, label: "1 an", type: "first_year" },
  { days: 730, label: "2 ans", type: null },
];

export interface MilestoneState { readonly label: string; readonly days: number; readonly reached: boolean; readonly remaining: number; readonly achievedAt: string | null }

// `recorded`: milestone type → date the server recorded it.
export function milestoneStates(daysSoFar: number | null, recorded: Readonly<Record<string, string>> = {}): readonly MilestoneState[] {
  const elapsed = daysSoFar ?? 0;
  return MILESTONES.map(({ days, label, type }) => {
    const achievedAt = type === null ? null : recorded[type] ?? null;
    return { days, label, reached: elapsed >= days || achievedAt !== null, remaining: Math.max(0, days - elapsed), achievedAt };
  });
}

// A calendar day written YYYY-MM-DD (a trailing time is ignored), as a local date.
export function parseDay(value: string): Date | null {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  if (year === undefined || month === undefined || day === undefined) return null;
  return new Date(year, month - 1, day);
}

// The next time a date falls on or after `from`: yearly for a recurring date,
// otherwise the date itself (null once it is behind us).
export function nextOccurrence(isoDate: string, recurring: boolean, from: Date): Date | null {
  const original = parseDay(isoDate);
  if (!original) return null;
  const today = startOfDay(from);
  if (original.getTime() >= today) return original;
  if (!recurring) return null;
  const thisYear = new Date(from.getFullYear(), original.getMonth(), original.getDate());
  return thisYear.getTime() >= today ? thisYear : new Date(from.getFullYear() + 1, original.getMonth(), original.getDate());
}

export interface Answers { readonly mine: string | null; readonly partner: string | null; readonly both: boolean }

// user1 is the member with the lower id (createCouple). The partner's answer
// is only given once both have answered: the API sends the whole row, so the
// screen has to hold it back.
export function answersOf(question: DailyQuestion, myId: number, partnerId: number): Answers {
  const iAmFirst = myId < partnerId;
  const mine = iAmFirst ? question.user1_answer : question.user2_answer;
  const theirs = iAmFirst ? question.user2_answer : question.user1_answer;
  const both = mine !== null && theirs !== null;
  return { mine, partner: both ? theirs : null, both };
}

export const num = (value: string | number | null | undefined): number => Number(value) || 0;

export const ACTIVITY_CATEGORIES: readonly { readonly key: string | null; readonly label: string }[] = [
  { key: null, label: "Tout" },
  { key: "wellness", label: "Bien-être" },
  { key: "gastronomy", label: "Gastro" },
  { key: "culture", label: "Culture" },
  { key: "sport", label: "Sport" },
  { key: "romantic", label: "Romantique" },
  { key: "travel", label: "Voyage" },
  { key: "spiritual", label: "Spirituel" },
];

export const categoryLabel = (key: string | null): string => ACTIVITY_CATEGORIES.find((entry) => entry.key !== null && entry.key === key)?.label ?? "Activité";

export const EVENT_CATEGORIES: readonly { readonly key: string | null; readonly label: string }[] = [
  { key: null, label: "Tout" },
  { key: "dinner", label: "Dîner" },
  { key: "tasting", label: "Dégustation" },
  { key: "party", label: "Soirée" },
  { key: "workshop", label: "Atelier" },
  { key: "brunch", label: "Brunch" },
  { key: "spiritual", label: "Spirituel" },
  { key: "travel", label: "Week-end" },
];

const EXTRA_EVENT_CATEGORIES: Readonly<Record<string, string>> = { concert: "Concert", game: "Jeux" };

export function eventCategoryLabel(key: string | null): string {
  if (key === null) return "Événement";
  return EVENT_CATEGORIES.find((entry) => entry.key === key)?.label ?? EXTRA_EVENT_CATEGORIES[key] ?? "Événement";
}

export function centsLabel(cents: number | null): string | null {
  if (cents === null) return null;
  return cents > 0 ? formatEuros(cents) : "Gratuit";
}

export function durationLabel(minutes: number | null): string | null {
  if (!minutes || minutes <= 0) return null;
  if (minutes >= 1440) return `${Math.round(minutes / 1440)} j`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  if (hours === 0) return `${rest} min`;
  return rest === 0 ? `${hours} h` : `${hours} h ${String(rest).padStart(2, "0")}`;
}

export const activityPrice = (activity: Activity): string | null => centsLabel(activity.price_cents);

export function coupleSpotsLeft(event: CoupleEvent): number | null {
  if (event.max_couples === null) return null;
  return Math.max(0, event.max_couples - (event.current_couples ?? 0));
}

export function coupleSpotsLabel(event: CoupleEvent): string | null {
  const left = coupleSpotsLeft(event);
  if (left === null) return null;
  if (left === 0) return "Complet";
  return left === 1 ? "1 place" : `${left} places`;
}
