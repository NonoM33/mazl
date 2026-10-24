// Readable labels of the profile answers, ported from
// mobile/lib/core/models/profile_labels.dart: successive screens stored "A la
// maison", "Tres observant", `kasher_a_la_maison` or `serious` for one idea.
// `null` means no chip (empty, "Non", "Autre"); an unknown value stays readable.

const HIDDEN = "";

const DENOMINATIONS: Readonly<Record<string, string>> = {
  laique: "Laïque", traditionaliste: "Traditionaliste", massorti: "Massorti", liberal: "Libéral", liberale: "Libérale",
  modern_orthodox: "Orthodoxe moderne", orthodoxe_moderne: "Orthodoxe moderne", orthodox: "Orthodoxe", orthodoxe: "Orthodoxe",
  habad: "Habad", loubavitch: "Habad", autre: HIDDEN,
};
const KASHRUT: Readonly<Record<string, string>> = {
  non: HIDDEN, no: HIDDEN, none: HIDDEN, a_la_maison: "Cacher à la maison", kasher_a_la_maison: "Cacher à la maison",
  cacher_a_la_maison: "Cacher à la maison", home: "Cacher à la maison", strict: "Cacher strict", kasher_strict: "Cacher strict", glatt: "Glatt cacher",
};
const SHABBAT: Readonly<Record<string, string>> = {
  non_observant: HIDDEN, not_observant: HIDDEN, partiellement: "Shabbat en partie", partial: "Shabbat en partie", partially: "Shabbat en partie",
  observant: "Shabbat observé", tres_observant: "Shabbat strict", strict: "Shabbat strict", shabbat_en_famille: "Shabbat en famille",
};
const INTENTIONS: Readonly<Record<string, string>> = {
  marriage: "Mariage", mariage: "Mariage", serious: "Relation sérieuse", open: "Ouvert à tout", friends_first: "Amitié d'abord",
};

// "Très Observant" → "tres_observant".
export function answerKey(value: string): string {
  return value.trim().toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[\s-]+/g, "_");
}

function label(raw: string | null | undefined, known: Readonly<Record<string, string>>): string | null {
  const value = raw?.trim() ?? "";
  if (value.length === 0) return null;
  const found = known[answerKey(value)];
  if (found !== undefined) return found.length === 0 ? null : found;
  const spaced = value.replaceAll("_", " ");
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

export const profileLabels = {
  denomination: (raw: string | null | undefined) => label(raw, DENOMINATIONS),
  kashrut: (raw: string | null | undefined) => label(raw, KASHRUT),
  shabbat: (raw: string | null | undefined) => label(raw, SHABBAT),
  intention: (raw: string | null | undefined) => label(raw, INTENTIONS),
};

// Values the mobile edit screen stores (edit_profile_screen.dart), with their label.
export interface Choice { readonly value: string; readonly label: string }
export const DENOMINATION_CHOICES: readonly Choice[] = [
  { value: "Laique", label: "Laïque" }, { value: "Traditionaliste", label: "Traditionaliste" }, { value: "Massorti", label: "Massorti" },
  { value: "Modern Orthodox", label: "Orthodoxe moderne" }, { value: "Orthodox", label: "Orthodoxe" }, { value: "Habad", label: "Habad" },
  { value: "Autre", label: "Autre" },
];
export const KASHRUT_CHOICES: readonly Choice[] = [
  { value: "Non", label: "Non" }, { value: "A la maison", label: "Cacher à la maison" }, { value: "Strict", label: "Cacher strict" }, { value: "Glatt", label: "Glatt cacher" },
];
export const SHABBAT_CHOICES: readonly Choice[] = [
  { value: "Non observant", label: "Non observant" }, { value: "Partiellement", label: "Shabbat en partie" },
  { value: "Observant", label: "Shabbat observé" }, { value: "Tres observant", label: "Shabbat strict" },
];
export const INTENTION_CHOICES: readonly Choice[] = [
  { value: "marriage", label: "Mariage" }, { value: "serious", label: "Relation sérieuse" }, { value: "open", label: "Ouvert à tout" }, { value: "friends_first", label: "Amitié d'abord" },
];
