// Formulaire d'une campagne : valeurs saisies → requête, avec vérification. Fonctions pures.
import { defaultDiscount, defaultTexts } from "./theme-texts";
import { daysBetween, isoToParisLocal, parisLocalToIso } from "./paris-time";
import { LANGS, type CampaignDto, type CampaignInput, type CampaignTarget, type CampaignTexts, type FullTexts, type Lang, type ProductDto, type ThemeId } from "./types";

export const NAME_MAX = 80;
export const TITLE_MAX = 60;
export const SUBTITLE_MAX = 140;
export const CTA_MAX = 32;
export const DISCOUNT_MIN = 5;
export const DISCOUNT_MAX = 90;
export const DURATION_MAX_DAYS = 45;

export interface TargetDraft {
  readonly productId: string;
  readonly enabled: boolean;
  /** Saisie brute du pourcentage. */
  readonly discountText: string;
}

export interface CampaignForm {
  readonly themeId: ThemeId;
  readonly name: string;
  /** Heure de Paris, format `datetime-local`. */
  readonly startsLocal: string;
  readonly endsLocal: string;
  readonly texts: FullTexts;
  readonly targets: readonly TargetDraft[];
  readonly changeAppIcon: boolean;
}

export interface FormErrors {
  readonly name?: string;
  readonly startsLocal?: string;
  readonly endsLocal?: string;
  readonly range?: string;
  readonly texts?: Readonly<Partial<Record<Lang, string>>>;
  readonly targets?: Readonly<Record<string, string>>;
}

export type FormResult = { readonly ok: true; readonly input: CampaignInput } | { readonly ok: false; readonly errors: FormErrors };

/** Les produits qu'une remise de campagne peut viser : les abonnements, par défaut tous. */
export function defaultTargets(products: readonly ProductDto[], themeId: ThemeId, selected: readonly CampaignTarget[] = []): readonly TargetDraft[] {
  const discount = String(defaultDiscount(themeId));
  return [...products]
    .sort((a, b) => a.sortOrder - b.sortOrder)
    .map((product) => {
      const found = selected.find((target) => target.productId === product.productId);
      if (found !== undefined) return { productId: product.productId, enabled: true, discountText: String(found.discountPercent) };
      return { productId: product.productId, enabled: selected.length === 0 && product.kind === "subscription", discountText: discount };
    });
}

const EMPTY_TEXTS = { title: "", subtitle: "", cta: "" } as const;

/** Une langue absente de la campagne s'affiche vide dans le formulaire (le français la remplace à l'affichage). */
export function fullTexts(texts: CampaignInput["texts"]): FullTexts {
  return { fr: texts.fr, en: texts.en ?? EMPTY_TEXTS, he: texts.he ?? EMPTY_TEXTS, es: texts.es ?? EMPTY_TEXTS, ru: texts.ru ?? EMPTY_TEXTS };
}

export function newForm(themeId: ThemeId, products: readonly ProductDto[], name: string, startsAt: string, endsAt: string): CampaignForm {
  return { themeId, name, startsLocal: isoToParisLocal(startsAt), endsLocal: isoToParisLocal(endsAt), texts: defaultTexts(themeId), targets: defaultTargets(products, themeId), changeAppIcon: true };
}

export function formFromCampaign(campaign: CampaignDto, products: readonly ProductDto[]): CampaignForm {
  return {
    themeId: campaign.themeId,
    name: campaign.name,
    startsLocal: isoToParisLocal(campaign.startsAt),
    endsLocal: isoToParisLocal(campaign.endsAt),
    texts: fullTexts(campaign.texts),
    targets: defaultTargets(products, campaign.themeId, campaign.targets),
    changeAppIcon: campaign.changeAppIcon,
  };
}

export function parseDiscount(text: string): number | null {
  const trimmed = text.trim().replace(/\s*%$/, "");
  if (!/^\d{1,3}$/.test(trimmed)) return null;
  const value = Number(trimmed);
  return value >= DISCOUNT_MIN && value <= DISCOUNT_MAX ? value : null;
}

export function validateForm(form: CampaignForm): FormResult {
  const errors: { -readonly [K in keyof FormErrors]: FormErrors[K] } = {};
  const name = form.name.trim();
  if (name === "") errors.name = "Donnez un nom interne à la campagne (il n'est pas montré aux membres).";
  else if (name.length > NAME_MAX) errors.name = `Le nom est trop long (${NAME_MAX} caractères au plus).`;

  const startsAt = parisLocalToIso(form.startsLocal);
  const endsAt = parisLocalToIso(form.endsLocal);
  if (startsAt === null) errors.startsLocal = "Choisissez la date et l'heure de début (heure de Paris).";
  if (endsAt === null) errors.endsLocal = "Choisissez la date et l'heure de fin (heure de Paris).";
  if (startsAt !== null && endsAt !== null) {
    if (Date.parse(endsAt) <= Date.parse(startsAt)) errors.range = "La fin doit être après le début.";
    else if (daysBetween(startsAt, endsAt) > DURATION_MAX_DAYS) errors.range = `Une campagne dure ${DURATION_MAX_DAYS} jours au plus.`;
  }

  const textErrors: Partial<Record<Lang, string>> = {};
  for (const lang of LANGS) {
    const { title, subtitle, cta } = form.texts[lang];
    const filled = [title, subtitle, cta].some((value) => value.trim() !== "");
    if (lang === "fr" || filled) {
      if (title.trim() === "" || subtitle.trim() === "" || cta.trim() === "") textErrors[lang] = lang === "fr" ? "Le français est obligatoire : titre, sous-titre et bouton." : "Renseignez les trois textes, ou videz-les tous (le français s'affichera).";
      else if (title.length > TITLE_MAX) textErrors[lang] = `Titre trop long (${TITLE_MAX} caractères au plus).`;
      else if (subtitle.length > SUBTITLE_MAX) textErrors[lang] = `Sous-titre trop long (${SUBTITLE_MAX} caractères au plus).`;
      else if (cta.length > CTA_MAX) textErrors[lang] = `Texte du bouton trop long (${CTA_MAX} caractères au plus).`;
    }
  }
  if (Object.keys(textErrors).length > 0) errors.texts = textErrors;

  const targetErrors: Record<string, string> = {};
  const targets: CampaignTarget[] = [];
  for (const target of form.targets) {
    if (!target.enabled) continue;
    const discount = parseDiscount(target.discountText);
    if (discount === null) targetErrors[target.productId] = `Remise entre ${DISCOUNT_MIN} et ${DISCOUNT_MAX} %.`;
    else targets.push({ productId: target.productId, discountPercent: discount });
  }
  if (Object.keys(targetErrors).length > 0) errors.targets = targetErrors;

  if (Object.keys(errors).length > 0 || startsAt === null || endsAt === null) return { ok: false, errors };
  const clean = (lang: Lang): CampaignTexts => ({ title: form.texts[lang].title.trim(), subtitle: form.texts[lang].subtitle.trim(), cta: form.texts[lang].cta.trim() });
  const isBlank = (lang: Lang): boolean => form.texts[lang].title.trim() === "" && form.texts[lang].subtitle.trim() === "" && form.texts[lang].cta.trim() === "";
  const trimmed: CampaignInput["texts"] = { fr: clean("fr"), ...Object.fromEntries((["en", "he", "es", "ru"] as const).filter((lang) => !isBlank(lang)).map((lang) => [lang, clean(lang)])) };
  return { ok: true, input: { themeId: form.themeId, name, startsAt, endsAt, texts: trimmed, targets, changeAppIcon: form.changeAppIcon } };
}

export const hasErrors = (errors: FormErrors): boolean => Object.keys(errors).length > 0;

/** Remise appliquée à un prix : 44,99 € à −30 % = 31,49 €. Arrondi au centime. */
export function discountedAmount(amount: number, percent: number): number {
  return Math.round((Math.round(amount * 100) * (100 - percent)) / 100) / 100;
}

/** Tous les messages d'erreur du formulaire, à plat (pour un résumé ou un rapport). */
export function errorMessages(errors: FormErrors): readonly string[] {
  return [errors.name, errors.startsLocal, errors.endsLocal, errors.range, ...Object.values(errors.texts ?? {}), ...Object.values(errors.targets ?? {})].filter((message): message is string => message !== undefined);
}
