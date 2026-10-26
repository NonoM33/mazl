// Construction et vérification des requêtes envoyées à /matching. Fonctions pures.
import type { MatchingParams, PreviewRequest } from "../shared/api/contracts";

export const NOTE_MIN = 3;
export const NOTE_MAX = 500;
export const AB_SHARE_MIN = 1;
export const AB_SHARE_MAX = 50;
export const SEED_MIN = -2_147_483_648;
export const SEED_MAX = 4_294_967_295;
/** Tailles de population proposées (le serveur accepte 20 à 400). 400 donne des classements plus fournis. */
export const PREVIEW_SIZES: readonly number[] = [120, 250, 400];
export const DEFAULT_PREVIEW_SIZE = 400;

export type Parsed<T> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly error: string };

/** Entier saisi à la main, borné : le message d'erreur dit la borne. */
export function parseIntegerInput(text: string, min: number, max: number): Parsed<number> {
  const trimmed = text.trim();
  if (!/^-?\d+$/.test(trimmed)) return { ok: false, error: "Saisissez un nombre entier." };
  const value = Number(trimmed);
  if (!Number.isSafeInteger(value) || value < min || value > max) return { ok: false, error: `Entre ${min} et ${max}.` };
  return { ok: true, value };
}

/** La note est obligatoire (même règle que le serveur : 3 à 500 caractères, espaces retirés). */
export function validateNote(note: string): string | null {
  const length = note.trim().length;
  if (length < NOTE_MIN) return `La note est obligatoire (${NOTE_MIN} caractères au moins) : elle explique le changement à vos collègues.`;
  if (length > NOTE_MAX) return `La note est trop longue (${NOTE_MAX} caractères au plus).`;
  return null;
}

export interface CreateVersionBody {
  readonly params: MatchingParams;
  readonly note: string;
  readonly activate: boolean;
}

export const createVersionBody = (params: MatchingParams, note: string, activate: boolean): CreateVersionBody => ({ params, note: note.trim(), activate });
export const activateBody = (note: string): { readonly note: string } => ({ note: note.trim() });

export interface AbTestBody {
  readonly variantId: number;
  readonly sharePercent: number;
}

export function abTestBody(variantId: number | null, shareText: string): Parsed<AbTestBody> {
  if (variantId === null) return { ok: false, error: "Choisissez la version à tester." };
  const share = parseIntegerInput(shareText, AB_SHARE_MIN, AB_SHARE_MAX);
  if (!share.ok) return { ok: false, error: `Part des membres : ${share.error}` };
  return { ok: true, value: { variantId, sharePercent: share.value } };
}

export interface ViewerChoice {
  readonly seedText: string;
  readonly indexText: string;
  readonly size: number;
}

/**
 * Simulation en direct : réglages en cours d'édition, comparés à la version active (`compareWith`).
 * La population est celle, fictive, du serveur : seuls la graine et l'index du membre sont envoyés.
 */
export function previewBody(draft: MatchingParams, active: MatchingParams, choice: ViewerChoice): Parsed<PreviewRequest> {
  const seed = parseIntegerInput(choice.seedText, SEED_MIN, SEED_MAX);
  if (!seed.ok) return { ok: false, error: `Graine : ${seed.error}` };
  const index = parseIntegerInput(choice.indexText, 0, choice.size - 1);
  if (!index.ok) return { ok: false, error: `Index du membre : ${index.error}` };
  return { ok: true, value: { params: draft, compareWith: active, seed: seed.value, viewer: index.value, size: choice.size } };
}
