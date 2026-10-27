import type { Language, LocalizedText } from "./languages";
import type { ThemeId } from "./themes";

export type StoredCampaignStatus = "draft" | "scheduled" | "cancelled";
export type CampaignStatus = "draft" | "scheduled" | "live" | "ended" | "cancelled";

export interface CampaignText {
  readonly title: string;
  readonly subtitle: string;
  readonly cta: string;
}
// French is mandatory, the other languages fall back to it.
export type CampaignTexts = { readonly fr: CampaignText } & Partial<Record<Exclude<Language, "fr">, CampaignText>>;

export interface CampaignTarget {
  readonly productId: string;
  readonly discountPercent: number;
}

export interface AppleOfferCodeState {
  readonly productId: string;
  readonly offerCodeId: string;
  readonly customCodeId: string;
  readonly customCode: string;
}

export interface AppleCampaignState {
  readonly codes: readonly AppleOfferCodeState[];
  readonly error: string | null;
}

export interface StripePromotionState {
  readonly productId: string;
  readonly couponId: string;
  readonly promotionCodeId: string;
}

export interface StripeCampaignState {
  readonly promotions: readonly StripePromotionState[];
  readonly error: string | null;
}

export interface Campaign {
  readonly id: number;
  readonly themeId: ThemeId;
  readonly name: string;
  readonly startsAt: Date;
  readonly endsAt: Date;
  readonly texts: CampaignTexts;
  readonly targets: readonly CampaignTarget[];
  readonly changeAppIcon: boolean;
  readonly status: StoredCampaignStatus;
  readonly apple: AppleCampaignState;
  readonly stripe: StripeCampaignState;
  readonly createdBy: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface CampaignInput {
  readonly themeId: ThemeId;
  readonly name: string;
  readonly startsAt: Date;
  readonly endsAt: Date;
  readonly texts: CampaignTexts;
  readonly targets: readonly CampaignTarget[];
  readonly changeAppIcon: boolean;
}

export const EMPTY_APPLE_STATE: AppleCampaignState = { codes: [], error: null };
export const EMPTY_STRIPE_STATE: StripeCampaignState = { promotions: [], error: null };

export function campaignStatus(campaign: Pick<Campaign, "status" | "startsAt" | "endsAt">, now: Date): CampaignStatus {
  if (campaign.status === "cancelled") return "cancelled";
  if (campaign.status === "draft") return "draft";
  if (now < campaign.startsAt) return "scheduled";
  return now < campaign.endsAt ? "live" : "ended";
}

export function localizedField(texts: CampaignTexts, field: keyof CampaignText): LocalizedText {
  const result: { fr: string } & Partial<Record<Exclude<Language, "fr">, string>> = { fr: texts.fr[field] };
  for (const language of ["en", "he", "es", "ru"] as const) {
    const text = texts[language];
    if (text !== undefined) result[language] = text[field];
  }
  return result;
}
