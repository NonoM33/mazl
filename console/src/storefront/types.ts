// Contrat de la vitrine côté console (docs/storefront/CONTRACT.md §4 et §5). Types des réponses du back-office.

export const LANGS = ["fr", "en", "he", "es", "ru"] as const;
export type Lang = (typeof LANGS)[number];
export type LocalizedText = Readonly<Record<Lang, string>>;

export const THEME_IDS = ["valentine", "tu_bav", "rosh_hashana", "hanukkah", "christmas", "new_year", "purim", "passover", "mothers_day", "summer", "black_friday"] as const;
export type ThemeId = (typeof THEME_IDS)[number];

export const GLYPHS = ["heart", "two_hearts", "pomegranate", "flame", "fir", "sparkle", "mask", "matzah", "flower", "sun", "bolt"] as const;
export type GlyphId = (typeof GLYPHS)[number];

export type ProductKind = "subscription" | "boost" | "superlikes";

/** Prix réel lu chez Apple pour un pays (code ISO 3166-1 alpha-3). `amount` : chaîne décimale d'Apple (« 44.99 »). */
export interface StorePriceDto {
  readonly territory: string;
  readonly currency: string;
  readonly amount: string;
}

export interface ProductDto {
  readonly productId: string;
  readonly kind: ProductKind;
  /** Nom français affiché dans la console (« mazl+ 3 mois »). */
  readonly label: string;
  readonly visible: boolean;
  readonly sortOrder: number;
  readonly featured: boolean;
  readonly highlight: LocalizedText | null;
  /** France d'abord, puis les pays témoins. Vide si Apple ne répond pas (`appleError` dit pourquoi). */
  readonly applePrices: readonly StorePriceDto[];
  readonly appleError: string | null;
  /** Prix web (Stripe) ; null tant que le produit n'est pas vendu sur le web. */
  readonly web: { readonly priceId: string | null; readonly amountCents: number; readonly currency: string; readonly unavailable?: boolean } | null;
}

export interface ProductsDto {
  readonly products: readonly ProductDto[];
}

export interface ProductPatch {
  readonly visible?: boolean;
  readonly sortOrder?: number;
  readonly featured?: boolean;
  readonly highlight?: LocalizedText | null;
}

export interface PricePointDto {
  readonly id: string;
  readonly customerPrice: string;
  readonly currency: string;
}

export interface PricePointsDto {
  readonly territory: string;
  readonly pricePoints: readonly PricePointDto[];
}

export interface ApplePriceBody {
  readonly pricePointId: string;
  /** AAAA-MM-JJ */
  readonly startDate: string;
  readonly preserveCurrentPrice: boolean;
  readonly dryRun?: boolean;
}

export interface ApplePriceChangeDto {
  readonly territory: string;
  readonly currency: string;
  readonly from: string | null;
  readonly to: string;
}

export interface ApplePricePlanDto {
  readonly dryRun: boolean;
  readonly startDate: string;
  readonly preserveCurrentPrice: boolean;
  readonly changes: readonly ApplePriceChangeDto[];
}

export interface WebPriceBody {
  readonly amountCents: number;
  readonly currency: string;
}

export interface WebPriceDto {
  readonly priceId: string;
  readonly amountCents: number;
  readonly currency: string;
}

export type CampaignStatus = "draft" | "scheduled" | "cancelled";
export type CampaignState = "draft" | "scheduled" | "live" | "ended" | "cancelled";

export interface CampaignTexts {
  readonly title: string;
  readonly subtitle: string;
  readonly cta: string;
}
/** Le français est obligatoire ; une langue absente retombe sur lui. */
export type CampaignTextsByLang = Readonly<{ fr: CampaignTexts } & Partial<Record<Exclude<Lang, "fr">, CampaignTexts>>>;

/** Textes saisis dans le formulaire : les cinq langues, vides si non renseignées. */
export type FullTexts = Readonly<Record<Lang, CampaignTexts>>;

export interface CampaignTarget {
  readonly productId: string;
  readonly discountPercent: number;
}

export interface CampaignInput {
  readonly themeId: ThemeId;
  readonly name: string;
  readonly startsAt: string;
  readonly endsAt: string;
  readonly texts: CampaignTextsByLang;
  readonly targets: readonly CampaignTarget[];
  readonly changeAppIcon: boolean;
}

export interface CampaignDto extends CampaignInput {
  readonly id: number;
  readonly status: CampaignStatus;
  /** Codes d'offre Apple créés à la programmation, et dernière erreur éventuelle. */
  readonly apple: { readonly offerCodes: readonly string[]; readonly error: string | null } | null;
  readonly stripe: { readonly couponId: string; readonly promotionCode: string } | null;
  readonly createdBy: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface CampaignListDto {
  readonly year: number;
  readonly campaigns: readonly CampaignDto[];
}

/** Proposition du serveur pour une fête : dates calculées, chevauchements avec les autres propositions. */
export interface PresetDto {
  readonly themeId: ThemeId;
  readonly name: string;
  readonly startsAt: string;
  readonly endsAt: string;
  readonly conflictsWith: readonly ThemeId[];
}

export interface PresetListDto {
  readonly year: number;
  readonly presets: readonly PresetDto[];
}
