// French formats used across the screens (24 h clock, like the app).

const TIME = new Intl.DateTimeFormat("fr-FR", { hour: "2-digit", minute: "2-digit" });
const DAY = new Intl.DateTimeFormat("fr-FR", { weekday: "short", day: "numeric", month: "short" });
const DATE = new Intl.DateTimeFormat("fr-FR", { day: "numeric", month: "long", year: "numeric" });
const MONEY = new Intl.NumberFormat("fr-FR", { style: "currency", currency: "EUR" });

export const formatTime = (iso: string | Date): string => TIME.format(new Date(iso));
export const formatDate = (iso: string | Date): string => DATE.format(new Date(iso));
export const formatEuros = (cents: number): string => MONEY.format(cents / 100);

function startOfDay(date: Date): number {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

// Day labels of the chat (CHAT.md): « Aujourd'hui », « Hier », « mar. 21 oct. ».
export function dayLabel(iso: string | Date, now: Date = new Date()): string {
  const days = Math.round((startOfDay(now) - startOfDay(new Date(iso))) / 86_400_000);
  if (days === 0) return "Aujourd'hui";
  if (days === 1) return "Hier";
  return DAY.format(new Date(iso));
}

// Conversation list: time today, otherwise the day.
export function shortWhen(iso: string | null, now: Date = new Date()): string {
  if (!iso) return "";
  return dayLabel(iso, now) === "Aujourd'hui" ? formatTime(iso) : dayLabel(iso, now);
}

export function ageLabel(age: number | null | undefined): string {
  return typeof age === "number" && Number.isFinite(age) ? `${Math.floor(age)} ans` : "";
}

export function displayName(name: string | null | undefined): string {
  const trimmed = name?.trim() ?? "";
  return trimmed.length > 0 ? trimmed : "Membre MAZL";
}

// « 10+ », « 25+ », « 50+ », « 99+ » above ten, like the app's likes counter.
export function likesCount(count: number): string {
  if (count <= 10) return String(count);
  for (const step of [99, 50, 25, 10]) if (count > step) return `${step}+`;
  return String(count);
}
