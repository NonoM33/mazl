import { z } from "zod";
import { MAX_DISCOUNT_PERCENT, MAX_NAME_LENGTH, MIN_DISCOUNT_PERCENT } from "../domain/campaign-rules";
import { THEME_IDS } from "../domain/themes";

// Wire formats of the storefront API: requests (parsed at the edge) and responses
// (documented in the OpenAPI, and checked against the examples by tests).

const isoDate = z.iso.datetime({ offset: true });
const productId = z.string().min(1).max(100);

// ---------- requests ----------

const highlight = z
  .object({
    fr: z.string().trim().min(1).max(60),
    en: z.string().trim().min(1).max(60).optional(),
    he: z.string().trim().min(1).max(60).optional(),
    es: z.string().trim().min(1).max(60).optional(),
    ru: z.string().trim().min(1).max(60).optional(),
  })
  .strict();

export const productPatchBody = z
  .object({
    visible: z.boolean().optional(),
    sortOrder: z.number().int().min(0).max(1000).optional(),
    featured: z.boolean().optional(),
    highlight: highlight.nullable().optional(),
  })
  .strict()
  .refine((body) => Object.values(body).some((value) => value !== undefined), "au moins un champ à modifier");

export const applePriceBody = z
  .object({
    pricePointId: z.string().min(1).max(200),
    startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    // Subscribers keep the price they pay today unless told otherwise.
    preserveCurrentPrice: z.boolean().default(true),
    // Nothing is written unless dryRun is false.
    dryRun: z.boolean().default(true),
  })
  .strict();

export const webPriceBody = z
  .object({
    amountCents: z.number().int().min(50).max(1_000_000),
    currency: z.string().regex(/^[A-Za-z]{3}$/),
  })
  .strict();

const campaignText = z.object({
  title: z.string().trim().min(1).max(60),
  subtitle: z.string().trim().min(1).max(140),
  cta: z.string().trim().min(1).max(30),
});

const campaignTexts = z
  .object({ fr: campaignText, en: campaignText.optional(), he: campaignText.optional(), es: campaignText.optional(), ru: campaignText.optional() })
  .strict();

const campaignTarget = z
  .object({ productId, discountPercent: z.number().int().min(MIN_DISCOUNT_PERCENT).max(MAX_DISCOUNT_PERCENT) })
  .strict();

export const campaignBody = z
  .object({
    themeId: z.enum(THEME_IDS),
    name: z.string().trim().min(1).max(MAX_NAME_LENGTH),
    startsAt: isoDate,
    endsAt: isoDate,
    texts: campaignTexts,
    targets: z.array(campaignTarget).min(1).max(8),
    changeAppIcon: z.boolean().default(true),
  })
  .strict();

export const campaignPatchBody = z
  .object({
    themeId: z.enum(THEME_IDS).optional(),
    name: z.string().trim().min(1).max(MAX_NAME_LENGTH).optional(),
    startsAt: isoDate.optional(),
    endsAt: isoDate.optional(),
    texts: campaignTexts.optional(),
    targets: z.array(campaignTarget).min(1).max(8).optional(),
    changeAppIcon: z.boolean().optional(),
  })
  .strict()
  .refine((body) => Object.values(body).some((value) => value !== undefined), "au moins un champ à modifier");

export const yearQuery = z.coerce.number().int().min(2020).max(2100);
export const territoryQuery = z.string().regex(/^[A-Z]{3}$/);
export const campaignIdParam = z.coerce.number().int().min(1).max(2_147_483_647);

// ---------- responses ----------

export const errorEnvelope = z.object({ success: z.literal(false), error: z.string(), message: z.string().optional() });
export const envelope = <T extends z.ZodType>(data: T) => z.object({ success: z.literal(true), data });

const storePrice = z.object({ territory: z.string(), currency: z.string(), customerPrice: z.string() });
const webPrice = z.object({ priceId: z.string(), amountCents: z.number().int(), currency: z.string() });
const storePrices = <T extends z.ZodType>(item: T) =>
  z.union([z.object({ status: z.literal("ok"), items: z.array(item) }), z.object({ status: z.literal("unavailable"), error: z.string() })]);

const localizedString = z.object({ fr: z.string(), en: z.string().optional(), he: z.string().optional(), es: z.string().optional(), ru: z.string().optional() });

export const productDisplayDto = z.object({
  productId,
  visible: z.boolean(),
  sortOrder: z.number().int(),
  featured: z.boolean(),
  highlight: localizedString.nullable(),
  stripePriceId: z.string().nullable(),
  updatedAt: isoDate,
  updatedBy: z.string().nullable(),
});

export const productViewDto = productDisplayDto.extend({
  kind: z.enum(["subscription", "credits"]),
  months: z.number().int().nullable(),
  effectiveStripePriceId: z.string().nullable(),
  prices: z.object({ apple: storePrices(storePrice), web: storePrices(webPrice) }),
});
export const productListDto = z.object({ products: z.array(productViewDto) });

export const pricePointDto = z.object({ id: z.string(), territory: z.string(), customerPrice: z.string(), proceeds: z.string() });
export const pricePointsDto = z.object({ productId, territory: z.string(), pricePoints: z.array(pricePointDto) });

export const applePlanDto = z.object({
  productId,
  startDate: z.string(),
  preserveCurrentPrice: z.boolean(),
  changes: z.array(z.object({ territory: z.string(), from: z.string().nullable(), to: z.string(), pricePointId: z.string() })),
});
export const applePriceResultDto = z.object({ dryRun: z.boolean(), plan: applePlanDto });
export const webPriceResultDto = z.object({ price: webPrice, previousPriceId: z.string().nullable(), product: productDisplayDto });

export const campaignDto = z.object({
  id: z.number().int(),
  themeId: z.enum(THEME_IDS),
  name: z.string(),
  startsAt: isoDate,
  endsAt: isoDate,
  status: z.enum(["draft", "scheduled", "live", "ended", "cancelled"]),
  texts: campaignTexts,
  targets: z.array(campaignTarget),
  changeAppIcon: z.boolean(),
  apple: z.object({
    codes: z.array(z.object({ productId, offerCodeId: z.string(), customCodeId: z.string(), customCode: z.string() })),
    error: z.string().nullable(),
  }),
  stripe: z.object({
    promotions: z.array(z.object({ productId, couponId: z.string(), promotionCodeId: z.string() })),
    error: z.string().nullable(),
  }),
  createdBy: z.string(),
  createdAt: isoDate,
  updatedAt: isoDate,
});
export const campaignListDto = z.object({ campaigns: z.array(campaignDto) });

export const presetDto = z.object({
  themeId: z.enum(THEME_IDS),
  glyph: z.string(),
  accent: z.string(),
  name: z.string(),
  eventStart: z.string(),
  eventEnd: z.string(),
  startsAt: isoDate,
  endsAt: isoDate,
  past: z.boolean(),
  existing: z.array(z.object({ id: z.number().int(), name: z.string(), status: z.string() })),
  conflicts: z.array(z.object({ id: z.number().int(), name: z.string() })),
  overlapsThemes: z.array(z.enum(THEME_IDS)),
});
export const presetListDto = z.object({ year: z.number().int(), presets: z.array(presetDto) });

export const publicStorefrontDto = z.object({
  serverTime: isoDate,
  products: z.array(z.object({ productId, visible: z.boolean(), sortOrder: z.number().int(), featured: z.boolean(), highlight: z.string().nullable() })),
  campaign: z
    .object({
      id: z.number().int(),
      themeId: z.enum(THEME_IDS),
      accent: z.string(),
      glyph: z.string(),
      startsAt: isoDate,
      endsAt: isoDate,
      title: z.string(),
      subtitle: z.string(),
      cta: z.string(),
      targets: z.array(z.object({ productId, discountPercent: z.number().int(), iosOfferCode: z.string().optional(), webPromotion: z.boolean() })),
    })
    .nullable(),
  appIcon: z.string().nullable(),
  nextChangeAt: isoDate.nullable(),
});

export const openApiDocument = z.object({ openapi: z.string() }).passthrough();
