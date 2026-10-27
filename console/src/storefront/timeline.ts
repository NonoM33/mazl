// Frise de l'année : place chaque campagne sur douze mois, sur des lignes qui évitent les superpositions. Fonctions pures.
import { parisDayOfYear, parisParts } from "./paris-time";

export interface Span {
  readonly key: string | number;
  readonly startsAt: string;
  readonly endsAt: string;
}

export const MONTH_NAMES = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."] as const;

export const isLeapYear = (year: number): boolean => (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
export const daysInYear = (year: number): number => (isLeapYear(year) ? 366 : 365);

const MONTH_DAYS = (year: number): readonly number[] => [31, isLeapYear(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

/** Largeur de chaque mois en part de l'année (somme = 1). */
export function monthColumns(year: number): readonly { readonly index: number; readonly label: string; readonly start: number; readonly width: number }[] {
  const total = daysInYear(year);
  let offset = 0;
  return MONTH_DAYS(year).map((days, index) => {
    const column = { index, label: MONTH_NAMES[index] ?? "", start: offset / total, width: days / total };
    offset += days;
    return column;
  });
}

export interface Placed<T extends Span> {
  readonly item: T;
  /** Début et fin en part de l'année, bornés à [0, 1]. */
  readonly start: number;
  readonly end: number;
  readonly lane: number;
  /** La campagne déborde de l'année affichée (avant le 1er janvier ou après le 31 décembre). */
  readonly clippedStart: boolean;
  readonly clippedEnd: boolean;
}

/** Jour (inclus) de début et jour (exclu) de fin, en jours depuis le 1er janvier, à Paris. */
function daySpan(item: Span, year: number): { readonly first: number; readonly last: number } {
  const start = Date.parse(item.startsAt);
  const end = Date.parse(item.endsAt);
  const first = parisDayOfYear(start, year);
  const endParts = parisParts(end);
  const lastDay = parisDayOfYear(end, year);
  return { first, last: endParts.hour === 0 && endParts.minute === 0 ? lastDay : lastDay + 1 };
}

/** Vrai si les deux intervalles [début, fin[ se recouvrent. */
export const overlaps = (a: Span, b: Span): boolean => Date.parse(a.startsAt) < Date.parse(b.endsAt) && Date.parse(b.startsAt) < Date.parse(a.endsAt);

/** Pour chaque campagne, les clés de celles qui la chevauchent (absente si aucune). */
export function findOverlaps(items: readonly Span[]): ReadonlyMap<string | number, readonly (string | number)[]> {
  const result = new Map<string | number, (string | number)[]>();
  for (const a of items) {
    for (const b of items) {
      if (a.key === b.key || !overlaps(a, b)) continue;
      const list = result.get(a.key) ?? [];
      list.push(b.key);
      result.set(a.key, list);
    }
  }
  return result;
}

export function layoutYear<T extends Span>(items: readonly T[], year: number): readonly Placed<T>[] {
  const total = daysInYear(year);
  const sorted = [...items]
    .map((item) => ({ item, ...daySpan(item, year) }))
    .filter(({ first, last }) => last > 0 && first < total)
    .sort((a, b) => a.first - b.first || a.last - b.last);
  const laneEnds: number[] = [];
  return sorted.map(({ item, first, last }) => {
    const start = Math.max(0, first);
    const end = Math.min(total, last);
    let lane = laneEnds.findIndex((laneEnd) => laneEnd <= start);
    if (lane === -1) {
      lane = laneEnds.length;
      laneEnds.push(end);
    } else {
      laneEnds[lane] = end;
    }
    return { item, start: start / total, end: end / total, lane, clippedStart: first < 0, clippedEnd: last > total };
  });
}

export const laneCount = (placed: readonly Placed<Span>[]): number => placed.reduce((max, entry) => Math.max(max, entry.lane + 1), 1);
