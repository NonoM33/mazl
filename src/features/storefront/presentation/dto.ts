import type { z } from "zod";
import { campaignStatus, type Campaign } from "../domain/campaign";
import type { ProductDisplay } from "../domain/products";
import type { ProductView } from "../application/catalog-service";
import type { Preset } from "../application/campaign-service";
import type {
  applePlanDto,
  applePriceBody,
  applePriceResultDto,
  campaignBody,
  campaignDto,
  campaignListDto,
  campaignPatchBody,
  pricePointDto,
  pricePointsDto,
  presetDto,
  presetListDto,
  productDisplayDto,
  productListDto,
  productPatchBody,
  productViewDto,
  webPriceBody,
  webPriceResultDto,
} from "./schemas";

export type CampaignDto = z.infer<typeof campaignDto>;
export type PresetDto = z.infer<typeof presetDto>;
export type ProductDisplayDto = z.infer<typeof productDisplayDto>;
export type ProductViewDto = z.infer<typeof productViewDto>;
export type ProductListDto = z.infer<typeof productListDto>;
export type PricePointDto = z.infer<typeof pricePointDto>;
export type PricePointsDto = z.infer<typeof pricePointsDto>;
export type ApplePlanDto = z.infer<typeof applePlanDto>;
export type ApplePriceResultDto = z.infer<typeof applePriceResultDto>;
export type WebPriceResultDto = z.infer<typeof webPriceResultDto>;
export type CampaignListDto = z.infer<typeof campaignListDto>;
export type PresetListDto = z.infer<typeof presetListDto>;

// Request bodies as a client writes them (defaults not yet applied).
export type ProductPatchBody = z.input<typeof productPatchBody>;
export type ApplePriceRequestBody = z.input<typeof applePriceBody>;
export type WebPriceRequestBody = z.input<typeof webPriceBody>;
export type CampaignRequestBody = z.input<typeof campaignBody>;
export type CampaignPatchRequestBody = z.input<typeof campaignPatchBody>;

export function toCampaignDto(campaign: Campaign, now: Date): CampaignDto {
  return {
    id: campaign.id,
    themeId: campaign.themeId,
    name: campaign.name,
    startsAt: campaign.startsAt.toISOString(),
    endsAt: campaign.endsAt.toISOString(),
    status: campaignStatus(campaign, now),
    texts: campaign.texts,
    targets: campaign.targets.map((target) => ({ ...target })),
    changeAppIcon: campaign.changeAppIcon,
    apple: { codes: campaign.apple.codes.map((code) => ({ ...code })), error: campaign.apple.error },
    stripe: { promotions: campaign.stripe.promotions.map((promotion) => ({ ...promotion })), error: campaign.stripe.error },
    createdBy: campaign.createdBy,
    createdAt: campaign.createdAt.toISOString(),
    updatedAt: campaign.updatedAt.toISOString(),
  };
}

export function toProductDisplayDto(product: ProductDisplay): ProductDisplayDto {
  return {
    productId: product.productId,
    visible: product.visible,
    sortOrder: product.sortOrder,
    featured: product.featured,
    highlight: product.highlight,
    stripePriceId: product.stripePriceId,
    updatedAt: product.updatedAt.toISOString(),
    updatedBy: product.updatedBy,
  };
}

export function toProductViewDto(view: ProductView): ProductViewDto {
  return {
    ...toProductDisplayDto(view),
    kind: view.kind,
    months: view.months,
    effectiveStripePriceId: view.effectiveStripePriceId,
    prices: {
      apple: view.prices.apple.status === "ok" ? { status: "ok", items: view.prices.apple.items.map((p) => ({ ...p })) } : view.prices.apple,
      web: view.prices.web.status === "ok" ? { status: "ok", items: view.prices.web.items.map((p) => ({ ...p })) } : view.prices.web,
    },
  };
}

export function toPresetDto(preset: Preset): PresetDto {
  return {
    ...preset,
    startsAt: preset.startsAt.toISOString(),
    endsAt: preset.endsAt.toISOString(),
    existing: preset.existing.map((e) => ({ ...e })),
    conflicts: preset.conflicts.map((c) => ({ ...c })),
    overlapsThemes: [...preset.overlapsThemes],
  };
}
