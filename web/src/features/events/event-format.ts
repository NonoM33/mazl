import type { EventRow } from "../../shared/api/types";
import { formatEuros } from "../../shared/lib/format";

// Wording of the event screens, taken from the app
// (mobile/lib/presentation/features/events/screens).

export const EVENT_TYPES: readonly { readonly key: string | null; readonly label: string }[] = [
  { key: null, label: "Tous" },
  { key: "shabbat_dinner", label: "Shabbat" },
  { key: "speed_dating", label: "Speed Dating" },
  { key: "holiday", label: "Fêtes" },
  { key: "lecture", label: "Cours" },
  { key: "social", label: "Social" },
];

export function eventTypeLabel(type: string | null): string {
  return EVENT_TYPES.find((entry) => entry.key !== null && entry.key === type)?.label ?? "Événement";
}

export const attendees = (event: EventRow): number => Number(event.attendee_count) || 0;

// null: no limit announced, so nothing to count down.
export function spotsLeft(event: EventRow): number | null {
  if (event.max_attendees === null) return null;
  return Math.max(0, event.max_attendees - attendees(event));
}

// French agrees with zero in the singular: « 0 inscrit », « 1 inscrit », « 2 inscrits ».
export const attendeesLabel = (event: EventRow): string => (attendees(event) < 2 ? `${attendees(event)} inscrit` : `${attendees(event)} inscrits`);

export const isFull = (event: EventRow): boolean => spotsLeft(event) === 0;

// Announced, but registrations are not open yet.
export const isComingSoon = (event: EventRow): boolean => event.availability === "coming_soon";

export const COMING_SOON = "Bientôt disponible";

// What the card says about the seats: « Bientôt disponible » before the opening.
export const cardStatusLabel = (event: EventRow): string | null => (isComingSoon(event) ? COMING_SOON : spotsLabel(event));

export function spotsLabel(event: EventRow): string | null {
  const left = spotsLeft(event);
  if (left === null) return null;
  if (left === 0) return "Complet";
  return left === 1 ? "1 place restante" : `${left} places restantes`;
}

// `price` is a decimal in euros (« 35.00 »), not cents.
export function priceLabel(event: EventRow): string {
  const euros = Number(event.price);
  if (!Number.isFinite(euros) || euros <= 0) return "Gratuit";
  const currency = event.currency ?? "EUR";
  if (currency === "EUR") return formatEuros(Math.round(euros * 100));
  return new Intl.NumberFormat("fr-FR", { style: "currency", currency }).format(euros);
}

// « 19:30:00 » → « 19:30 »
export const clock = (time: string | null): string | null => (time && /^\d{2}:\d{2}/.test(time) ? time.slice(0, 5) : null);

const DAY = new Intl.DateTimeFormat("fr-FR", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });
const LONG_DAY = new Intl.DateTimeFormat("fr-FR", { weekday: "long", day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });

// The API sends a calendar day; the day is read as written, never shifted by
// the time zone of the browser.
function calendarDay(value: string): Date {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  return new Date(Date.UTC(year ?? 1970, (month ?? 1) - 1, day ?? 1));
}

export const shortDay = (value: string): string => DAY.format(calendarDay(value));
export const longDay = (value: string): string => LONG_DAY.format(calendarDay(value));

export function whenLabel(event: EventRow): string {
  const start = clock(event.time);
  return start ? `${shortDay(event.date)} · ${start}` : shortDay(event.date);
}

// Wording of the errors of POST /api/events/:id/rsvp.
export function rsvpErrorMessage(code: string): string {
  if (code === "Event is full") return "Complet";
  if (code === "Event is over") return "Événement passé";
  if (code === "Event not found") return "Événement introuvable";
  if (code === "Registrations for this event are not open yet") return COMING_SOON;
  return "L'inscription n'a pas abouti. Réessayez.";
}
