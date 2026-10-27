// Dates de la conciergerie, à l'heure de Paris. Fonctions pures, horloge injectable.
import { PARIS, parisLocalToIso } from "../storefront/paris-time";

const DAY_LABEL = new Intl.DateTimeFormat("fr-FR", { timeZone: "UTC", weekday: "short", day: "numeric", month: "short" });
const DAY_LONG = new Intl.DateTimeFormat("fr-FR", { timeZone: "UTC", weekday: "long", day: "numeric", month: "long" });
const STAMP = new Intl.DateTimeFormat("fr-FR", { timeZone: PARIS, day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });

const DAY_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

/** Midi UTC du jour calendaire : formaté en UTC, le jour ne glisse jamais. */
function calendarNoon(day: string): number | null {
  const match = DAY_ONLY.exec(day);
  if (match === null) return null;
  const [year, month, date] = match.slice(1).map(Number) as [number, number, number];
  const noon = Date.UTC(year, month - 1, date, 12);
  const check = new Date(noon);
  return check.getUTCMonth() === month - 1 && check.getUTCDate() === date ? noon : null;
}

/** « jeu. 29 oct. » pour une date souhaitée `YYYY-MM-DD` ; « — » quand il n'y en a pas. */
export function formatWantedDay(day: string | null): string {
  if (day === null) return "—";
  const noon = calendarNoon(day);
  return noon === null ? "—" : DAY_LABEL.format(noon);
}

/** « jeudi 29 octobre ». */
export function formatWantedDayLong(day: string | null): string {
  if (day === null) return "Pas de date précise";
  const noon = calendarNoon(day);
  return noon === null ? "Pas de date précise" : DAY_LONG.format(noon);
}

/** « 27 oct., 14:05 » à l'heure de Paris (heure d'été ou d'hiver selon la date). */
export function formatStamp(iso: string): string {
  const time = Date.parse(iso);
  return Number.isNaN(time) ? "—" : STAMP.format(time);
}

/** Début du jour souhaité (minuit à Paris) : l'échéance retenue pour l'urgence. */
export function wantedDeadline(day: string | null): number | null {
  if (day === null || calendarNoon(day) === null) return null;
  const iso = parisLocalToIso(`${day}T00:00`);
  return iso === null ? null : Date.parse(iso);
}

/** « 8 mois », « 2 ans », « 2 ans et 3 mois ». */
export function formatCoupleDuration(months: number): string {
  if (!Number.isFinite(months) || months < 0) return "—";
  const whole = Math.floor(months);
  if (whole < 1) return "moins d'un mois";
  if (whole < 12) return `${whole} mois`;
  const years = Math.floor(whole / 12);
  const rest = whole % 12;
  const yearText = `${years} an${years > 1 ? "s" : ""}`;
  return rest === 0 ? yearText : `${yearText} et ${rest} mois`;
}
