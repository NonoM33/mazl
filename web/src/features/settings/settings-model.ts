import type { WebSessionInfo } from "../../shared/api/types";
import { formatDate, formatTime } from "../../shared/lib/format";
import type { Place, RestWindow } from "../shabbat/rest-windows";

export const BUFFER_CHOICES = [0, 5, 10, 15, 18, 20, 25, 30] as const;

const METHODS: Readonly<Record<WebSessionInfo["method"], string>> = { qr: "QR code", google: "Google", apple: "Apple" };

export const methodLabel = (method: WebSessionInfo["method"]): string => METHODS[method];

export function sessionTitle(session: WebSessionInfo): string {
  return session.current === true ? `${session.browser} · Cet ordinateur` : session.browser;
}

export function sessionDetail(session: WebSessionInfo): string {
  return `Connecté par ${methodLabel(session.method)} · dernière activité le ${formatDate(session.last_seen_at)} à ${formatTime(session.last_seen_at)}`;
}

const WEEKDAY = new Intl.DateTimeFormat("fr-FR", { weekday: "long" });
const stamp = (date: Date): string => `${WEEKDAY.format(date)} ${formatTime(date)}`;

// « Shabbat : vendredi 17:02 → samedi 18:10, Paris »
export function windowLabel(window: RestWindow | null, place: Place): string {
  if (window === null) return "Aucune fenêtre à venir.";
  return `${window.holiday ? "Yom Tov" : "Shabbat"} : ${stamp(window.start)} → ${stamp(window.end)}, ${place.name}`;
}

export const bufferLabel = (minutes: number): string => (minutes === 0 ? "Aucune marge" : `${minutes} min`);

export const others = (sessions: readonly WebSessionInfo[]): readonly WebSessionInfo[] => sessions.filter((session) => session.current !== true);

export const REASON_MAX = 500;
