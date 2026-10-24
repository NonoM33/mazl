// Formats français (fr-FR) : dates relatives, durées, nombres. Fonctions pures, horloge injectable.

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

const NUMBER = new Intl.NumberFormat("fr-FR");
const DECIMAL = new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 1 });
const DATE = new Intl.DateTimeFormat("fr-FR", { day: "numeric", month: "short", year: "numeric" });
const DATE_TIME = new Intl.DateTimeFormat("fr-FR", {
  day: "numeric",
  month: "short",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});
const DAY_MONTH = new Intl.DateTimeFormat("fr-FR", { day: "numeric", month: "short" });
const TIME = new Intl.DateTimeFormat("fr-FR", { hour: "2-digit", minute: "2-digit" });

export function formatNumber(value: number): string {
  return NUMBER.format(value);
}

export function formatDecimal(value: number): string {
  return DECIMAL.format(value);
}

export function formatPercent(ratio: number): string {
  return `${DECIMAL.format(ratio * 100)} %`;
}

function parse(iso: string): number {
  return Date.parse(iso);
}

/** « il y a 3 h », « dans 2 j », « à l'instant ». Au-delà de 30 jours : la date. */
export function relativeTime(iso: string, now: Date = new Date()): string {
  const target = parse(iso);
  if (Number.isNaN(target)) return "date inconnue";
  const diff = target - now.getTime();
  const abs = Math.abs(diff);
  if (abs < MINUTE) return "à l'instant";
  if (abs >= 30 * DAY) return DATE.format(target);
  const unit = abs < HOUR ? `${Math.floor(abs / MINUTE)} min` : abs < DAY ? `${Math.floor(abs / HOUR)} h` : `${Math.floor(abs / DAY)} j`;
  return diff < 0 ? `il y a ${unit}` : `dans ${unit}`;
}

/** Durée en heures → « 45 min », « 5,2 h », « 3,5 j ». */
export function formatHours(hours: number | null): string {
  if (hours === null) return "—";
  if (hours < 1) return `${Math.max(1, Math.round(hours * 60))} min`;
  if (hours < 48) return `${DECIMAL.format(hours)} h`;
  return `${DECIMAL.format(hours / 24)} j`;
}

/** Échéance d'un signalement : « dans 3 h » ou « en retard de 2 h ». */
export function dueLabel(dueIso: string, now: Date = new Date()): { readonly text: string; readonly late: boolean } {
  const diff = parse(dueIso) - now.getTime();
  if (Number.isNaN(diff)) return { text: "—", late: false };
  const abs = Math.abs(diff);
  const unit = abs < HOUR ? `${Math.max(1, Math.floor(abs / MINUTE))} min` : abs < DAY ? `${Math.floor(abs / HOUR)} h` : `${Math.floor(abs / DAY)} j`;
  return diff < 0 ? { text: `en retard de ${unit}`, late: true } : { text: `dans ${unit}`, late: false };
}

export function formatDate(iso: string): string {
  const t = parse(iso);
  return Number.isNaN(t) ? "—" : DATE.format(t);
}

export function formatDateTime(iso: string): string {
  const t = parse(iso);
  return Number.isNaN(t) ? "—" : DATE_TIME.format(t);
}

export function formatDayMonth(iso: string): string {
  const t = parse(iso);
  return Number.isNaN(t) ? "—" : DAY_MONTH.format(t);
}

export function formatTime(iso: string): string {
  const t = parse(iso);
  return Number.isNaN(t) ? "—" : TIME.format(t);
}

/** Ancienneté d'un compte en jours → « 12 jours », « 3 mois », « 2 ans ». */
export function formatAccountAge(days: number): string {
  if (days < 1) return "moins d'un jour";
  if (days < 60) return `${days} jour${days > 1 ? "s" : ""}`;
  if (days < 730) return `${Math.floor(days / 30)} mois`;
  return `${Math.floor(days / 365)} ans`;
}

/** Groupe une clé par blocs de 4 : « JBSW Y3DP EHPK 3PXP ». */
export function groupBy4(secret: string): string {
  return secret.replace(/\s+/g, "").replace(/(.{4})(?=.)/g, "$1 ");
}

export function pluralize(count: number, singular: string, plural: string): string {
  return `${formatNumber(count)} ${count > 1 ? plural : singular}`;
}

export function memberName(member: { readonly id: number; readonly displayName: string | null }): string {
  return member.displayName !== null && member.displayName.trim() !== "" ? member.displayName : `Membre n°\u00A0${member.id}`;
}
