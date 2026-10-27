// Dates de la vitrine : tout est saisi et affiché à l'heure de Paris, stocké en UTC (ISO 8601). Fonctions pures.

export const PARIS = "Europe/Paris";
const MINUTE = 60_000;
const DAY = 86_400_000;

const PARTS = new Intl.DateTimeFormat("en-GB", { timeZone: PARIS, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" });
const FULL = new Intl.DateTimeFormat("fr-FR", { timeZone: PARIS, day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
const DAY_LONG = new Intl.DateTimeFormat("fr-FR", { timeZone: PARIS, day: "numeric", month: "long" });
const DAY_SHORT = new Intl.DateTimeFormat("fr-FR", { timeZone: PARIS, day: "numeric", month: "short" });

export interface ParisParts {
  readonly year: number;
  readonly month: number; // 1..12
  readonly day: number;
  readonly hour: number;
  readonly minute: number;
}

export function parisParts(instant: number | Date): ParisParts {
  const values: Record<string, number> = {};
  for (const part of PARTS.formatToParts(instant)) {
    if (part.type !== "literal") values[part.type] = Number(part.value);
  }
  return { year: values["year"] ?? 0, month: values["month"] ?? 0, day: values["day"] ?? 0, hour: values["hour"] ?? 0, minute: values["minute"] ?? 0 };
}

const pad = (value: number): string => String(value).padStart(2, "0");

/** « 2027-02-14T00:00 » pour un champ `datetime-local`, à l'heure de Paris. */
export function isoToParisLocal(iso: string): string {
  const time = Date.parse(iso);
  if (Number.isNaN(time)) return "";
  const p = parisParts(time);
  return `${p.year}-${pad(p.month)}-${pad(p.day)}T${pad(p.hour)}:${pad(p.minute)}`;
}

const LOCAL = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/;

/** Heure de Paris saisie (« 2027-02-14T00:00 ») → instant ISO en UTC ; null si la saisie n'est pas une date réelle. */
export function parisLocalToIso(local: string): string | null {
  const match = LOCAL.exec(local);
  if (match === null) return null;
  const [year, month, day, hour, minute] = match.slice(1).map(Number) as [number, number, number, number, number];
  const wall = Date.UTC(year, month - 1, day, hour, minute);
  const check = new Date(wall);
  if (check.getUTCFullYear() !== year || check.getUTCMonth() !== month - 1 || check.getUTCDate() !== day || hour > 23 || minute > 59) return null;
  let guess = wall;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const p = parisParts(guess);
    const shown = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute);
    const drift = shown - wall;
    if (drift === 0) break;
    guess -= drift;
  }
  return new Date(guess).toISOString();
}

export function formatParis(iso: string): string {
  const time = Date.parse(iso);
  return Number.isNaN(time) ? "—" : `${FULL.format(time)} (Paris)`;
}

/** Dernier jour d'affichage d'une campagne : une fin à minuit pile appartient au jour suivant, qui n'en fait plus partie. */
export function lastDayInstant(endsAtIso: string): number {
  const end = Date.parse(endsAtIso);
  const p = parisParts(end);
  return p.hour === 0 && p.minute === 0 ? end - MINUTE : end;
}

/** « 14 février » : le dernier jour de la campagne, pour « jusqu'au 14 février ». */
export function formatLastDay(endsAtIso: string): string {
  return Number.isNaN(Date.parse(endsAtIso)) ? "—" : DAY_LONG.format(lastDayInstant(endsAtIso));
}

export function formatDayShort(iso: string): string {
  const time = Date.parse(iso);
  return Number.isNaN(time) ? "—" : DAY_SHORT.format(time);
}

/** Jour civil de Paris sous forme d'un nombre de jours depuis le 1er janvier de `year` (négatif avant). */
export function parisDayOfYear(instant: number, year: number): number {
  const p = parisParts(instant);
  return Math.round((Date.UTC(p.year, p.month - 1, p.day) - Date.UTC(year, 0, 1)) / DAY);
}

/** AAAA-MM-JJ du jour courant à Paris. */
export function parisToday(now: Date = new Date()): string {
  const p = parisParts(now);
  return `${p.year}-${pad(p.month)}-${pad(p.day)}`;
}

export function daysBetween(startIso: string, endIso: string): number {
  return (Date.parse(endIso) - Date.parse(startIso)) / DAY;
}

/** Durée lisible : « 3 j 4 h », « 5 h 12 min », « 12 min ». */
export function formatSpan(ms: number): string {
  const total = Math.max(0, Math.floor(ms / MINUTE));
  const days = Math.floor(total / 1440);
  const hours = Math.floor((total % 1440) / 60);
  const minutes = total % 60;
  if (days > 0) return hours > 0 ? `${days} j ${hours} h` : `${days} j`;
  if (hours > 0) return minutes > 0 ? `${hours} h ${minutes} min` : `${hours} h`;
  return `${Math.max(1, minutes)} min`;
}
