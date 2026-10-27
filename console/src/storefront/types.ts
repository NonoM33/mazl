// Contrat de la vitrine côté console (docs/storefront/CONTRACT.md §5). Les formes de réponse et de requête sont CELLES DU SERVEUR
// (src/features/storefront/presentation/schemas.ts, importées en types seulement) : aucune forme n'est redéfinie ici.

export const LANGS = ["fr", "en", "he", "es", "ru"] as const;
export type Lang = (typeof LANGS)[number];
/** Texte par langue, tel que le serveur le range : le français est obligatoire, une autre langue absente retombe sur lui. */
export type LocalizedText = Readonly<{ fr: string } & Partial<Record<Exclude<Lang, "fr">, string>>>;

export const THEME_IDS = ["valentine", "tu_bav", "rosh_hashana", "hanukkah", "christmas", "new_year", "purim", "passover", "mothers_day", "summer", "black_friday"] as const;
export type ThemeId = (typeof THEME_IDS)[number];

export const GLYPHS = ["heart", "two_hearts", "pomegranate", "flame", "fir", "sparkle", "mask", "matzah", "flower", "sun", "bolt"] as const;
export type GlyphId = (typeof GLYPHS)[number];

import type {
  ApplePlanDto,
  ApplePriceRequestBody,
  ApplePriceResultDto,
  CampaignDto as ServerCampaignDto,
  CampaignListDto,
  CampaignPatchRequestBody,
  CampaignRequestBody,
  PresetDto,
  PresetListDto,
  PricePointDto,
  PricePointsDto,
  ProductDisplayDto,
  ProductListDto,
  ProductPatchBody,
  ProductViewDto,
  WebPriceRequestBody,
  WebPriceResultDto,
} from "../../../src/features/storefront/presentation/dto";

export type {
  ApplePlanDto,
  CampaignListDto,
  PresetDto,
  PresetListDto,
  PricePointDto,
  PricePointsDto,
  ProductDisplayDto,
  WebPriceResultDto,
  ApplePriceResultDto,
};

export type ProductDto = ProductViewDto;
export type ProductsDto = ProductListDto;
export type ProductPatch = ProductPatchBody;
export type ApplePriceBody = ApplePriceRequestBody;
export type WebPriceBody = WebPriceRequestBody;
export type CampaignDto = ServerCampaignDto;
export type CampaignInput = CampaignRequestBody;
export type CampaignPatch = CampaignPatchRequestBody;

/** Prix lu chez Apple pour un pays (ISO 3166-1 alpha-3) ; `customerPrice` : chaîne décimale d'Apple (« 44.99 »). */
export type StorePriceDto = Extract<ProductViewDto["prices"]["apple"], { status: "ok" }>["items"][number];
/** Prix Stripe en vigueur d'un produit. */
export type WebPriceDto = Extract<ProductViewDto["prices"]["web"], { status: "ok" }>["items"][number];
export type ApplePriceChangeDto = ApplePlanDto["changes"][number];

/** Le serveur rend l'état affiché : brouillon, programmée, en cours, terminée, annulée. */
export type CampaignState = CampaignDto["status"];
export type CampaignStatus = CampaignState;

export type CampaignTextsByLang = CampaignDto["texts"];
export type CampaignTexts = CampaignTextsByLang["fr"];
export type CampaignTarget = CampaignDto["targets"][number];

/** Textes saisis dans le formulaire : les cinq langues, vides si non renseignées. */
export type FullTexts = Readonly<Record<Lang, CampaignTexts>>;
