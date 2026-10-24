// Order of the member's photos. Pure, so the keyboard and the drag and drop
// share one rule; the first photo is the main one.

export const MAX_PHOTOS = 6;

export function moveBy(ids: readonly number[], id: number, delta: -1 | 1): readonly number[] {
  const from = ids.indexOf(id);
  const to = from + delta;
  if (from < 0 || to < 0 || to >= ids.length) return ids;
  return moveTo(ids, id, to);
}

// Takes `id` out and puts it back at index `to` of the resulting list.
export function moveTo(ids: readonly number[], id: number, to: number): readonly number[] {
  const from = ids.indexOf(id);
  if (from < 0 || to < 0 || to >= ids.length || from === to) return ids;
  const rest = ids.filter((item) => item !== id);
  return [...rest.slice(0, to), id, ...rest.slice(to)];
}

const REASONS: Readonly<Record<string, string>> = {
  undecodable: "Cette image n'a pas pu être lue. Essayez une autre photo.",
  unsupported_format: "Ce format n'est pas pris en charge. Utilisez une photo JPEG, PNG ou HEIC.",
  too_large: "Cette photo est trop lourde ou trop grande (10 Mo au maximum).",
  empty: "Ce fichier est vide.",
};

export const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const ACCEPTED = /\.(jpe?g|png|heic|heif)$/i;
const ACCEPTED_TYPES = new Set(["image/jpeg", "image/png", "image/heic", "image/heif"]);

// Checked before sending so a wrong file costs no upload (the server decides anyway).
export function fileProblem(file: { readonly name: string; readonly type: string; readonly size: number }): string | null {
  if (file.size === 0) return REASONS.empty ?? null;
  if (!ACCEPTED_TYPES.has(file.type) && !ACCEPTED.test(file.name)) return REASONS.unsupported_format ?? null;
  if (file.size > MAX_UPLOAD_BYTES) return REASONS.too_large ?? null;
  return null;
}

export function rejectionMessage(status: number, reason: unknown): string | null {
  if (status === 409) return `${MAX_PHOTOS} photos au maximum. Supprimez-en une pour en ajouter.`;
  if (status === 413) return REASONS.too_large ?? null;
  if (status === 400) return (typeof reason === "string" ? REASONS[reason] : undefined) ?? "Cette photo a été refusée.";
  return null;
}
