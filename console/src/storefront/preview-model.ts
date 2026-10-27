// Données de l'aperçu « tel que l'app le montrera » : lignes de prix, fin de campagne, couleurs lisibles. Fonctions pures.
import { discountedAmount } from "./campaign-form";
import { PARIS, lastDayInstant } from "./paris-time";
import { applePrice, formatMoney } from "./price-change";
import { sortProducts } from "./offers-model";
import type { CampaignTarget, Lang, ProductDto } from "./types";

const UNTIL: Readonly<Record<Lang, string>> = { fr: "jusqu'au", en: "until", he: "עד", es: "hasta el", ru: "до" };
const LOCALES: Readonly<Record<Lang, string>> = { fr: "fr-FR", en: "en-GB", he: "he-IL", es: "es-ES", ru: "ru-RU" };

/** « jusqu'au 14 février » dans la langue de l'aperçu, jour de Paris. */
export function untilLabel(endsAtIso: string, lang: Lang): string {
  if (Number.isNaN(Date.parse(endsAtIso))) return "";
  const day = new Intl.DateTimeFormat(LOCALES[lang], { timeZone: PARIS, day: "numeric", month: "long" }).format(lastDayInstant(endsAtIso));
  return `${UNTIL[lang]} ${day}`;
}

const MONTHS_BY_SUFFIX: Readonly<Record<string, number>> = { "1m": 1, "3m": 3, "6m": 6, "12m": 12 };
const DURATION_NAMES: Readonly<Record<Lang, Readonly<Record<number, string>>>> = {
  fr: { 1: "mazl+ 1 mois", 3: "mazl+ 3 mois", 6: "mazl+ 6 mois", 12: "mazl+ 12 mois" },
  en: { 1: "mazl+ 1 month", 3: "mazl+ 3 months", 6: "mazl+ 6 months", 12: "mazl+ 12 months" },
  he: { 1: "mazl+ חודש אחד", 3: "mazl+ 3 חודשים", 6: "mazl+ 6 חודשים", 12: "mazl+ 12 חודשים" },
  es: { 1: "mazl+ 1 mes", 3: "mazl+ 3 meses", 6: "mazl+ 6 meses", 12: "mazl+ 12 meses" },
  ru: { 1: "mazl+ 1 месяц", 3: "mazl+ 3 месяца", 6: "mazl+ 6 месяцев", 12: "mazl+ 12 месяцев" },
};

/** Nom affiché de l'offre dans la langue demandée (noms saisis dans App Store Connect) ; le nom français en repli. */
export function offerName(product: Pick<ProductDto, "productId" | "label">, lang: Lang): string {
  const months = MONTHS_BY_SUFFIX[product.productId.split(".").pop() ?? ""];
  return months === undefined ? product.label : (DURATION_NAMES[lang][months] ?? product.label);
}

export interface PaywallLine {
  readonly productId: string;
  readonly name: string;
  readonly highlight: string | null;
  readonly price: string;
  /** Prix barré, présent seulement si une remise s'applique. */
  readonly oldPrice: string | null;
  readonly badge: string | null;
}

/** Les offres visibles, dans l'ordre du serveur, avec la remise de la campagne sur celles qu'elle cible. */
export function paywallLines(products: readonly ProductDto[], targets: readonly CampaignTarget[], lang: Lang): readonly PaywallLine[] {
  return sortProducts(products)
    .filter((product) => product.visible && product.kind === "subscription")
    .map((product) => {
      const france = applePrice(product, "FRA");
      const target = targets.find((candidate) => candidate.productId === product.productId);
      const amount = france === undefined ? null : Number(france.amount);
      const highlight = product.featured && product.highlight !== null ? (product.highlight[lang].trim() === "" ? product.highlight.fr : product.highlight[lang]) : null;
      const base = france === undefined || amount === null ? "—" : formatMoney(france.amount, france.currency);
      if (target === undefined || france === undefined || amount === null) return { productId: product.productId, name: offerName(product, lang), highlight, price: base, oldPrice: null, badge: null };
      return {
        productId: product.productId,
        name: offerName(product, lang),
        highlight,
        price: formatMoney(discountedAmount(amount, target.discountPercent), france.currency),
        oldPrice: base,
        badge: `−${target.discountPercent} %`,
      };
    });
}

function luminance(hex: string): number {
  const match = /^#([0-9a-f]{6})$/i.exec(hex);
  if (match === null) return 0;
  const channels = [0, 2, 4].map((offset) => {
    const value = parseInt((match[1] ?? "").slice(offset, offset + 2), 16) / 255;
    return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * (channels[0] ?? 0) + 0.7152 * (channels[1] ?? 0) + 0.0722 * (channels[2] ?? 0);
}

export function contrastRatio(a: string, b: string): number {
  const [light, dark] = [luminance(a), luminance(b)].sort((x, y) => y - x) as [number, number];
  return (light + 0.05) / (dark + 0.05);
}

/** Couleur de texte la plus lisible (encre ou blanc) sur un fond d'accent. */
export function readableOn(background: string): "#0B0B0F" | "#FFFFFF" {
  return contrastRatio(background, "#FFFFFF") >= contrastRatio(background, "#0B0B0F") ? "#FFFFFF" : "#0B0B0F";
}
