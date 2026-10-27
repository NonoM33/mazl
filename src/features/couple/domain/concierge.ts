import { z } from "zod";
import type { QuestionLanguage } from "./question-bank";

// The concierge (docs/couple/ESPACE-COUPLE.md section 7): an assistant proposes,
// the MAZL team confirms and books. Pure rules.

export const REQUEST_KINDS = ["table", "surprise", "gift", "weekend", "other"] as const;
export type RequestKind = (typeof REQUEST_KINDS)[number];

export const REQUEST_STATUSES = ["new", "proposed", "chosen", "booked", "closed", "cancelled"] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];

export const MESSAGE_ROLES = ["member", "assistant", "staff"] as const;
export type MessageRole = (typeof MESSAGE_ROLES)[number];

// Messages a couple may send to the assistant in a day (section 0.5).
export const DAILY_MESSAGE_LIMIT = 20;
export const MAX_MEMBER_TEXT = 2000;
export const MAX_STAFF_TEXT = 1000;
export const MAX_REPLY_LENGTH = 600;

export const optionSchema = z.object({
  title: z.string().trim().min(1).max(120),
  details: z.string().trim().max(400),
  priceHint: z.string().trim().max(80),
});
export type ConciergeOption = z.infer<typeof optionSchema>;

// The only thing the assistant may answer, as JSON.
export const assistantOutputSchema = z.object({
  reply: z.string().trim().min(1).max(MAX_REPLY_LENGTH),
  options: z.array(optionSchema).max(3),
});
export type AssistantOutput = z.infer<typeof assistantOutputSchema>;

export interface Constraints {
  readonly kosher?: boolean;
  readonly budget?: string;
}

// Step of the progress bar: received, idea chosen, booked.
export function stepOf(status: RequestStatus): 1 | 2 | 3 {
  if (status === "chosen") return 2;
  if (status === "booked" || status === "closed") return 3;
  return 1;
}

export const isFinished = (status: RequestStatus): boolean => status === "closed" || status === "cancelled";

export type Transition = { readonly ok: true } | { readonly ok: false; readonly error: "concierge_closed" | "invalid_transition" };

// What a couple may do: choose an idea, cancel.
export function coupleChoose(status: RequestStatus, optionCount: number, index: number): Transition {
  if (isFinished(status)) return { ok: false, error: "concierge_closed" };
  if (status === "booked" || index < 0 || index >= optionCount) return { ok: false, error: "invalid_transition" };
  return { ok: true };
}

export function coupleCancel(status: RequestStatus): Transition {
  if (isFinished(status)) return { ok: false, error: "concierge_closed" };
  return status === "booked" ? { ok: false, error: "invalid_transition" } : { ok: true };
}

// What the team may do: book (an idea must have been chosen), close.
export function staffMove(status: RequestStatus, chosenIndex: number | null, next: "booked" | "closed"): Transition {
  if (isFinished(status)) return { ok: false, error: "concierge_closed" };
  if (next === "booked" && (status !== "chosen" || chosenIndex === null)) return { ok: false, error: "invalid_transition" };
  return { ok: true };
}

export function titleFrom(text: string): string {
  const line = text.trim().split(/\r?\n/)[0] ?? "";
  const compact = line.replace(/\s+/g, " ");
  return compact.length <= 60 ? compact : `${compact.slice(0, 59).trimEnd()}…`;
}

// Shown when the assistant is absent or fails: the request goes to the team.
const TEAM_FALLBACK: Readonly<Record<QuestionLanguage, string>> = {
  fr: "Votre demande est bien reçue. L'équipe MAZL vous répond très bientôt.",
  en: "Your request has been received. The MAZL team will get back to you very soon.",
  he: "הבקשה שלכם התקבלה. צוות MAZL יחזור אליכם בקרוב.",
  es: "Hemos recibido tu solicitud. El equipo de MAZL te responderá muy pronto.",
  ru: "Ваш запрос получен. Команда MAZL ответит Вам очень скоро.",
};

export const teamFallbackText = (language: QuestionLanguage): string => TEAM_FALLBACK[language];
