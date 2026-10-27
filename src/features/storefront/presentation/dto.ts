import type { z } from "zod";
import { campaignStatus, type Campaign } from "../domain/campaign";
import type { ProductDisplay } from "../domain/products";
import type { ProductView } from "../application/catalog-service";
import type { Preset } from "../application/campaign-service";
import type { campaignDto, presetDto, productDisplayDto, productViewDto } from "./schemas";

export type CampaignDto = z.infer<typeof campaignDto>;
export type PresetDto = z.infer<typeof presetDto>;
export type ProductDisplayDto = z.infer<typeof productDisplayDto>;
export type ProductViewDto = z.infer<typeof productViewDto>;

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
