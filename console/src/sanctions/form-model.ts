// Modèle du formulaire de décision / sanction, partagé par le panneau de signalement et la fiche membre.
import type { DecisionGround, ReportDecisionBody, SanctionInput, SanctionKind } from "../shared/api/contracts";

export type Outcome = "dismissed" | "actioned";

export interface DecisionForm {
  readonly outcome: Outcome;
  readonly kind: SanctionKind | null;
  readonly ground: DecisionGround | null;
  readonly facts: string;
  readonly durationDays: string;
  readonly note: string;
  readonly banConfirmed: boolean;
}

export type FormErrors = Partial<Record<"kind" | "ground" | "facts" | "durationDays" | "note" | "banConfirmed", string>>;

export const NOTE_MIN = 3;
export const NOTE_MAX = 2000;
export const FACTS_MIN = 10;
export const FACTS_MAX = 2000;
export const JUSTIFICATION_MIN = 10;
export const JUSTIFICATION_MAX = 500;

export function emptyForm(outcome: Outcome = "actioned", suggested: SanctionKind | null = null): DecisionForm {
  return { outcome, kind: suggested, ground: null, facts: "", durationDays: "7", note: "", banConfirmed: false };
}

export function hasDuration(kind: SanctionKind | null): boolean {
  return kind === "restriction" || kind === "suspension";
}

export function validateDecision(form: DecisionForm, options: { readonly canBan: boolean }): FormErrors {
  const errors: { -readonly [K in keyof FormErrors]: string } = {};
  const note = form.note.trim();
  if (note.length < NOTE_MIN) errors.note = `La note interne est obligatoire (${NOTE_MIN} caractères minimum).`;
  else if (note.length > NOTE_MAX) errors.note = `La note interne est limitée à ${NOTE_MAX} caractères.`;
  if (form.outcome === "dismissed") return errors;

  if (form.kind === null) errors.kind = "Choisissez une sanction.";
  if (form.kind === "ban" && !options.canBan) errors.kind = "Le bannissement exige une permission que vous n'avez pas.";
  if (form.ground === null) errors.ground = "Choisissez le motif normalisé de la décision.";
  const facts = form.facts.trim();
  if (facts.length < FACTS_MIN) errors.facts = `Décrivez les faits communiqués au membre (${FACTS_MIN} caractères minimum).`;
  else if (facts.length > FACTS_MAX) errors.facts = `Les faits sont limités à ${FACTS_MAX} caractères.`;
  if (hasDuration(form.kind)) {
    const days = Number(form.durationDays);
    if (!Number.isInteger(days) || days < 1 || days > 365) errors.durationDays = "La durée doit être un nombre entier de jours, entre 1 et 365.";
  }
  if (form.kind === "ban" && !form.banConfirmed) errors.banConfirmed = "Confirmez explicitement le bannissement.";
  return errors;
}

export function isValid(errors: FormErrors): boolean {
  return Object.keys(errors).length === 0;
}

export function toSanctionInput(form: DecisionForm): SanctionInput | null {
  if (form.kind === null || form.ground === null) return null;
  const base = { kind: form.kind, ground: form.ground, facts: form.facts.trim() };
  return hasDuration(form.kind) ? { ...base, durationDays: Number(form.durationDays) } : base;
}

export function toReportDecisionBody(form: DecisionForm): ReportDecisionBody | null {
  const note = form.note.trim();
  if (form.outcome === "dismissed") return { outcome: "dismissed", note };
  const sanction = toSanctionInput(form);
  return sanction === null ? null : { outcome: "actioned", note, sanction };
}

export function toMemberSanctionBody(form: DecisionForm): (SanctionInput & { readonly note: string }) | null {
  const sanction = toSanctionInput(form);
  return sanction === null ? null : { ...sanction, note: form.note.trim() };
}

export function validateJustification(text: string): string | null {
  const length = text.trim().length;
  if (length < JUSTIFICATION_MIN) return `Le motif doit comporter au moins ${JUSTIFICATION_MIN} caractères.`;
  if (length > JUSTIFICATION_MAX) return `Le motif est limité à ${JUSTIFICATION_MAX} caractères.`;
  return null;
}
