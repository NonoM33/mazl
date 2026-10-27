import type { AuditLog } from "../../audit/application/ports";
import { campaignStatus, type AppleOfferCodeState, type Campaign, type CampaignInput, type StripePromotionState } from "../domain/campaign";
import { applyEdit, assertNoOverlap, assertValidCampaign, type CampaignEdit } from "../domain/campaign-rules";
import { calendarForYear } from "../domain/calendar";
import { CampaignNotFoundError, CampaignStateError, InvalidCampaignError, StoreCallError } from "../domain/errors";
import { generateOfferCode } from "../domain/offer-code";
import { parisDay, parisMidnight } from "../domain/paris-time";
import { catalogProduct } from "../domain/products";
import { themeById, type ThemeId } from "../domain/themes";
import { effectiveStripePriceId } from "./catalog-service";
import type { AppStorePricing, WebPricing } from "./ports";
import type { StorefrontRepository } from "./repository";
import { callStore, describeFailure } from "./store-call";

export interface CampaignDeps {
  readonly repository: StorefrontRepository;
  readonly apple: AppStorePricing;
  readonly web: WebPricing;
  readonly audit: AuditLog;
  readonly env: Readonly<Record<string, string | undefined>>;
  readonly now: () => Date;
}

export interface Preset {
  readonly themeId: ThemeId;
  readonly glyph: string;
  readonly accent: string;
  readonly name: string;
  readonly eventStart: string;
  readonly eventEnd: string;
  readonly startsAt: Date;
  readonly endsAt: Date;
  readonly past: boolean;
  // Campaigns already saved (not cancelled) that cover this window.
  readonly existing: readonly { readonly id: number; readonly name: string; readonly status: string }[];
  // Scheduled campaigns this window would collide with when published.
  readonly conflicts: readonly { readonly id: number; readonly name: string }[];
  // Other themes of the same year whose window overlaps this one.
  readonly overlapsThemes: readonly ThemeId[];
}

const MIN_YEAR = 2020;
const MAX_YEAR = 2100;

export class CampaignService {
  constructor(private readonly deps: CampaignDeps) {}

  list(year: number | undefined): Promise<readonly Campaign[]> {
    if (year === undefined) return this.deps.repository.listCampaigns();
    return this.deps.repository.listCampaigns({ from: parisMidnight(`${String(year)}-01-01`), to: parisMidnight(`${String(year + 1)}-01-01`) });
  }

  async get(id: number): Promise<Campaign> {
    const campaign = await this.deps.repository.getCampaign(id);
    if (campaign === null) throw new CampaignNotFoundError(id);
    return campaign;
  }

  async create(actor: string, input: CampaignInput): Promise<Campaign> {
    assertValidCampaign(input);
    const campaign = await this.deps.repository.insertCampaign(input, actor);
    await this.audit(actor, "storefront.campaign.create", campaign, { themeId: campaign.themeId });
    return campaign;
  }

  async update(actor: string, id: number, edit: CampaignEdit): Promise<Campaign> {
    const current = await this.get(id);
    const next = applyEdit(current, edit, this.deps.now());
    const updated = await this.deps.repository.updateCampaign(id, next);
    await this.audit(actor, "storefront.campaign.update", updated, {
      fields: (Object.keys(edit) as (keyof CampaignEdit)[]).filter((key) => edit[key] !== undefined),
    });
    return updated;
  }

  async presets(year: number): Promise<readonly Preset[]> {
    if (!Number.isInteger(year) || year < MIN_YEAR || year > MAX_YEAR) throw new InvalidCampaignError([`year must be from ${String(MIN_YEAR)} to ${String(MAX_YEAR)}`]);
    const now = this.deps.now();
    const dates = calendarForYear(year);
    const all = await this.deps.repository.listCampaigns({
      from: dates.reduce((min, d) => (d.startsAt < min ? d.startsAt : min), dates[0]?.startsAt ?? now),
      to: dates.reduce((max, d) => (d.endsAt > max ? d.endsAt : max), dates[0]?.endsAt ?? now),
    });
    return dates.map((d) => {
      const theme = themeById(d.themeId);
      const overlapping = all.filter((c) => c.status !== "cancelled" && c.startsAt < d.endsAt && d.startsAt < c.endsAt);
      return {
        themeId: d.themeId,
        glyph: theme.glyph,
        accent: theme.accent,
        name: `${d.themeId} ${d.eventStart.slice(0, 4)}`,
        eventStart: d.eventStart,
        eventEnd: d.eventEnd,
        startsAt: d.startsAt,
        endsAt: d.endsAt,
        past: d.endsAt <= now,
        existing: overlapping.filter((c) => c.themeId === d.themeId).map((c) => ({ id: c.id, name: c.name, status: campaignStatus(c, now) })),
        conflicts: overlapping.filter((c) => c.status === "scheduled").map((c) => ({ id: c.id, name: c.name })),
        overlapsThemes: dates.filter((other) => other.themeId !== d.themeId && other.startsAt < d.endsAt && d.startsAt < other.endsAt).map((other) => other.themeId),
      };
    });
  }

  // Creates the offer codes at Apple and the promotions at Stripe, then schedules the campaign.
  // A failure leaves the campaign a draft, with the error saved; what was already created is
  // kept and reused by the next attempt.
  async publish(actor: string, id: number): Promise<Campaign> {
    const campaign = await this.get(id);
    if (campaign.status !== "draft") throw new CampaignStateError(`Only a draft can be published (this one is ${campaignStatus(campaign, this.deps.now())})`);
    if (campaign.endsAt <= this.deps.now()) throw new InvalidCampaignError(["the campaign is already over"]);
    assertValidCampaign(campaign);
    assertNoOverlap(campaign, await this.deps.repository.scheduledCampaigns());

    const apple = await this.createAppleCodes(campaign);
    const stripe = await this.createPromotions(campaign);
    const scheduled = await this.deps.repository.saveCampaignState(id, {
      status: "scheduled",
      apple: { codes: apple, error: null },
      stripe: { promotions: stripe, error: null },
    });
    await this.audit(actor, "storefront.campaign.publish", scheduled, { appleCodes: apple.length, webPromotions: stripe.length });
    return scheduled;
  }

  // Deactivates what publishing created. If a store refuses, the campaign stays as it is
  // (cancel again, or end it earlier) so that no code is left active behind a cancelled campaign.
  async cancel(actor: string, id: number): Promise<Campaign> {
    const campaign = await this.get(id);
    const state = campaignStatus(campaign, this.deps.now());
    if (state === "ended" || state === "cancelled") throw new CampaignStateError(`A ${state} campaign cannot be cancelled`);
    const failures: { apple: string | null; stripe: string | null } = { apple: null, stripe: null };
    for (const code of campaign.apple.codes) {
      try {
        await callStore("apple", () => this.deps.apple.deactivateOfferCode(code));
      } catch (error: unknown) {
        failures.apple = describeFailure(error);
      }
    }
    for (const promotion of campaign.stripe.promotions) {
      try {
        await callStore("stripe", () => this.deps.web.deactivatePromotion({ couponId: promotion.couponId, promotionCodeId: promotion.promotionCodeId }));
      } catch (error: unknown) {
        failures.stripe = describeFailure(error);
      }
    }
    if (failures.apple !== null || failures.stripe !== null) {
      await this.deps.repository.saveCampaignState(id, {
        apple: { ...campaign.apple, error: failures.apple },
        stripe: { ...campaign.stripe, error: failures.stripe },
      });
      await this.audit(actor, "storefront.campaign.cancel_failed", campaign, { apple: failures.apple !== null, stripe: failures.stripe !== null });
      throw new StoreCallError(failures.apple !== null ? "apple" : "stripe", failures.apple ?? failures.stripe ?? "deactivation failed");
    }
    const cancelled = await this.deps.repository.saveCampaignState(id, {
      status: "cancelled",
      apple: { ...campaign.apple, error: null },
      stripe: { ...campaign.stripe, error: null },
    });
    await this.audit(actor, "storefront.campaign.cancel", cancelled, { wasLive: state === "live" });
    return cancelled;
  }

  private async createAppleCodes(campaign: Campaign): Promise<readonly AppleOfferCodeState[]> {
    const subscriptions = campaign.targets.filter((target) => catalogProduct(target.productId)?.kind === "subscription");
    const codes: AppleOfferCodeState[] = [...campaign.apple.codes];
    const taken = new Set(await this.deps.repository.takenOfferCodes());
    const expiresOn = parisDay(new Date(campaign.endsAt.getTime() - 1));
    for (const target of subscriptions) {
      if (codes.some((code) => code.productId === target.productId)) continue;
      const months = subscriptions.length > 1 ? (catalogProduct(target.productId)?.months ?? null) : null;
      const customCode = generateOfferCode({ themeId: campaign.themeId, endsAt: campaign.endsAt, months, taken });
      try {
        const created = await callStore("apple", () =>
          this.deps.apple.createOfferCode({
            productId: target.productId,
            name: `${campaign.name} ${customCode}`.slice(0, 64),
            customCode,
            discountPercent: target.discountPercent,
            expiresOn,
          }),
        );
        codes.push({ productId: created.productId, offerCodeId: created.offerCodeId, customCodeId: created.customCodeId, customCode: created.customCode });
        taken.add(created.customCode);
      } catch (error: unknown) {
        await this.deps.repository.saveCampaignState(campaign.id, { apple: { codes, error: describeFailure(error) } });
        throw error;
      }
    }
    if (codes.length !== campaign.apple.codes.length || campaign.apple.error !== null) {
      await this.deps.repository.saveCampaignState(campaign.id, { apple: { codes, error: null } });
    }
    return codes;
  }

  private async createPromotions(campaign: Campaign): Promise<readonly StripePromotionState[]> {
    const promotions: StripePromotionState[] = [...campaign.stripe.promotions];
    for (const target of campaign.targets) {
      if (promotions.some((promotion) => promotion.productId === target.productId)) continue;
      const product = await this.deps.repository.getProduct(target.productId);
      const priceId = product === null ? null : effectiveStripePriceId(product, this.deps.env);
      // Not sold on the web: nothing to discount there.
      if (priceId === null) continue;
      try {
        const created = await callStore("stripe", () =>
          this.deps.web.createPromotion(`${campaign.name} ${target.productId}`.slice(0, 64), target.discountPercent, [priceId], campaign.endsAt),
        );
        promotions.push({ productId: target.productId, couponId: created.couponId, promotionCodeId: created.promotionCodeId });
      } catch (error: unknown) {
        await this.deps.repository.saveCampaignState(campaign.id, { stripe: { promotions, error: describeFailure(error) } });
        throw error;
      }
    }
    return promotions;
  }

  private audit(actor: string, action: string, campaign: Campaign, details: Readonly<Record<string, unknown>>): Promise<unknown> {
    return this.deps.audit.record({ actor, action, targetType: "storefront_campaign", targetId: String(campaign.id), details: { name: campaign.name, ...details } });
  }
}

