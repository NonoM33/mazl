import { campaignStatus, localizedField, type Campaign } from "../domain/campaign";
import { pickText, type Language, type LocalizedText } from "../domain/languages";
import { formatParis } from "../domain/paris-time";
import { themeById, type ThemeId } from "../domain/themes";
import type { StorefrontRepository } from "./repository";

// GET /api/storefront (docs/storefront/CONTRACT.md §4). Public: no price is sent for iOS,
// only what to show, in which order, and the campaign.
export interface PublicTarget {
  readonly productId: string;
  readonly discountPercent: number;
  readonly iosOfferCode?: string;
  readonly webPromotion: boolean;
}

export interface PublicCampaign {
  readonly id: number;
  readonly themeId: ThemeId;
  readonly accent: string;
  readonly glyph: string;
  readonly startsAt: string;
  readonly endsAt: string;
  readonly title: string;
  readonly subtitle: string;
  readonly cta: string;
  readonly targets: readonly PublicTarget[];
}

export interface PublicStorefront {
  readonly serverTime: string;
  readonly products: readonly {
    readonly productId: string;
    readonly visible: boolean;
    readonly sortOrder: number;
    readonly featured: boolean;
    readonly highlight: string | null;
  }[];
  readonly campaign: PublicCampaign | null;
  readonly appIcon: string | null;
  readonly nextChangeAt: string | null;
}

function publicCampaign(campaign: Campaign, language: Language): PublicCampaign {
  const theme = themeById(campaign.themeId);
  const pick = (field: "title" | "subtitle" | "cta"): string => pickText(localizedField(campaign.texts, field), language);
  return {
    id: campaign.id,
    themeId: campaign.themeId,
    accent: theme.accent,
    glyph: theme.glyph,
    startsAt: campaign.startsAt.toISOString(),
    endsAt: campaign.endsAt.toISOString(),
    title: pick("title"),
    subtitle: pick("subtitle"),
    cta: pick("cta"),
    targets: campaign.targets.map((target) => {
      const code = campaign.apple.codes.find((candidate) => candidate.productId === target.productId);
      return {
        productId: target.productId,
        discountPercent: target.discountPercent,
        ...(code === undefined ? {} : { iosOfferCode: code.customCode }),
        webPromotion: campaign.stripe.promotions.some((promotion) => promotion.productId === target.productId),
      };
    }),
  };
}

export async function buildPublicStorefront(repository: StorefrontRepository, now: Date, language: Language): Promise<PublicStorefront> {
  const [products, scheduled] = await Promise.all([repository.listProducts(), repository.scheduledCampaigns()]);
  const live = scheduled.find((campaign) => campaignStatus(campaign, now) === "live");
  const upcoming = scheduled.filter((campaign) => campaign.startsAt > now).sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime())[0];
  const nextChange = live?.endsAt ?? upcoming?.startsAt;
  const highlight = (value: LocalizedText | null): string | null => (value === null ? null : pickText(value, language));
  return {
    serverTime: now.toISOString(),
    products: products.map((product) => ({
      productId: product.productId,
      visible: product.visible,
      sortOrder: product.sortOrder,
      featured: product.featured,
      highlight: highlight(product.highlight),
    })),
    campaign: live === undefined ? null : publicCampaign(live, language),
    appIcon: live?.changeAppIcon === true ? `AppIcon-${live.themeId}` : null,
    nextChangeAt: nextChange === undefined ? null : formatParis(nextChange),
  };
}
