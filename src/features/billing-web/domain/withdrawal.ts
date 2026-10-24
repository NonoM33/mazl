// The express waiver of the 14-day withdrawal right for digital content
// (Code de la consommation, art. L221-28 13°). Any change of wording is a new
// version: the proof stored with each purchase names the version and the hash.
export const WITHDRAWAL_VERSION = "2026-10-24";

export const WITHDRAWAL_TEXT =
  "Je demande l'accès immédiat à mon achat et je renonce expressément à mon droit de rétractation de 14 jours dès le début de son exécution (article L221-28 13° du Code de la consommation).";

const two = (n: number) => String(n).padStart(2, "0");

// The confirmation shown when paying and printed on the pack's invoice, which
// Stripe e-mails: the durable medium of art. L221-13 (security review B4).
export function waiverConfirmation(acceptedAt: Date): string {
  const day = `${two(acceptedAt.getUTCDate())}/${two(acceptedAt.getUTCMonth() + 1)}/${acceptedAt.getUTCFullYear()}`;
  const time = `${two(acceptedAt.getUTCHours())}:${two(acceptedAt.getUTCMinutes())}`;
  return `Renoncement exprès au droit de rétractation accepté le ${day} à ${time} (UTC) : « ${WITHDRAWAL_TEXT} »`;
}
