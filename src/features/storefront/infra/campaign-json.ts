import { z } from "zod";
import type { AppleCampaignState, CampaignTarget, CampaignTexts, StripeCampaignState } from "../domain/campaign";

// What the JSONB columns of storefront_campaigns hold. Read back through these
// schemas, so a row edited by hand cannot reach the domain malformed.
const text = z.object({ title: z.string(), subtitle: z.string(), cta: z.string() });

const textsSchema: z.ZodType<CampaignTexts> = z.object({
  fr: text,
  en: text.optional(),
  he: text.optional(),
  es: text.optional(),
  ru: text.optional(),
});

const targetsSchema: z.ZodType<readonly CampaignTarget[]> = z.array(z.object({ productId: z.string(), discountPercent: z.number() }));

const appleSchema: z.ZodType<AppleCampaignState> = z.object({
  codes: z.array(z.object({ productId: z.string(), offerCodeId: z.string(), customCodeId: z.string(), customCode: z.string() })),
  error: z.string().nullable(),
});

const stripeSchema: z.ZodType<StripeCampaignState> = z.object({
  promotions: z.array(z.object({ productId: z.string(), couponId: z.string(), promotionCodeId: z.string() })),
  error: z.string().nullable(),
});

export const parseTexts = (value: unknown): CampaignTexts => textsSchema.parse(value);
export const parseTargets = (value: unknown): readonly CampaignTarget[] => targetsSchema.parse(value);
export const parseAppleState = (value: unknown): AppleCampaignState => appleSchema.parse(value);
export const parseStripeState = (value: unknown): StripeCampaignState => stripeSchema.parse(value);
