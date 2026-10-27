import type Stripe from "stripe";
import type { WebPrice, WebPricing, WebPromotion } from "../../application/ports";
import { WebPricingError } from "./errors";

const PRODUCT_METADATA_KEY = "productId";

const unixSeconds = (date: Date): number => Math.floor(date.getTime() / 1000);

function productIdOf(price: Stripe.Price): string {
  return typeof price.product === "string" ? price.product : price.product.id;
}

export class StripeWebPricing implements WebPricing {
  constructor(private readonly stripe: Stripe) {}

  async currentPrice(priceId: string): Promise<WebPrice> {
    const price = await this.stripe.prices.retrieve(priceId);
    return toWebPrice(price);
  }

  // A Stripe price is immutable: a new price is created on the product that carries metadata.productId.
  async createPrice(productId: string, amountCents: number, currency: string, recurringMonths: number | null): Promise<WebPrice> {
    if (!Number.isSafeInteger(amountCents) || amountCents <= 0) throw new WebPricingError("amountCents must be a positive integer");
    if (!/^[A-Za-z]{3}$/.test(currency)) throw new WebPricingError("currency must be a 3-letter ISO 4217 code");
    if (recurringMonths !== null && (!Number.isSafeInteger(recurringMonths) || recurringMonths <= 0)) {
      throw new WebPricingError("recurringMonths must be a positive integer or null");
    }
    const product = await this.productFor(productId);
    const price = await this.stripe.prices.create({
      product,
      unit_amount: amountCents,
      currency: currency.toLowerCase(),
      metadata: { [PRODUCT_METADATA_KEY]: productId },
      ...(recurringMonths === null ? {} : { recurring: { interval: "month", interval_count: recurringMonths } }),
    });
    return toWebPrice(price);
  }

  // Coupon percent_off limited to the products of the given prices, usable once per customer's first invoice,
  // plus the promotion code that exposes it. redeem_by ends the campaign.
  async createPromotion(name: string, percentOff: number, appliesToPriceIds: readonly string[], redeemBy: Date): Promise<WebPromotion> {
    if (!(percentOff > 0 && percentOff <= 100)) throw new WebPricingError("percentOff must be above 0 and at most 100");
    if (appliesToPriceIds.length === 0) throw new WebPricingError("a promotion must apply to at least one price");
    const products = new Set<string>();
    for (const priceId of appliesToPriceIds) products.add(productIdOf(await this.stripe.prices.retrieve(priceId)));
    const coupon = await this.stripe.coupons.create({
      name,
      percent_off: percentOff,
      duration: "once",
      applies_to: { products: [...products] },
      redeem_by: unixSeconds(redeemBy),
    });
    try {
      const code = await this.stripe.promotionCodes.create({
        promotion: { type: "coupon", coupon: coupon.id },
        expires_at: unixSeconds(redeemBy),
      });
      return { couponId: coupon.id, promotionCodeId: code.id };
    } catch (error) {
      await this.deleteCouponQuietly(coupon.id);
      throw error;
    }
  }

  async deactivatePromotion(promotion: WebPromotion): Promise<void> {
    await this.stripe.promotionCodes.update(promotion.promotionCodeId, { active: false });
  }

  private async productFor(productId: string): Promise<string> {
    for await (const product of this.stripe.products.list({ active: true, limit: 100 })) {
      if (product.metadata[PRODUCT_METADATA_KEY] === productId) return product.id;
    }
    const created = await this.stripe.products.create({ name: stripeProductName(productId), metadata: { [PRODUCT_METADATA_KEY]: productId } });
    return created.id;
  }

  private async deleteCouponQuietly(couponId: string): Promise<void> {
    try {
      await this.stripe.coupons.del(couponId);
    } catch {
      // The promotion code failure is the one to report; an unused coupon without code redeems nothing.
    }
  }
}

function toWebPrice(price: Stripe.Price): WebPrice {
  if (price.unit_amount === null) throw new WebPricingError(`Stripe price ${price.id} has no unit_amount (tiered or custom price)`);
  return { priceId: price.id, amountCents: price.unit_amount, currency: price.currency.toUpperCase() };
}

// The name the customer reads on Stripe's checkout and receipts, never the technical id.
export function stripeProductName(productId: string): string {
  const plus = /^com\.mazl\.app\.plus\.(\d+)m$/.exec(productId);
  if (plus) return `mazl+ ${plus[1]} mois`;
  const pack = /^com\.mazl\.app\.(boost|superlikes)\.(\d+)$/.exec(productId);
  if (pack) return pack[1] === "boost" ? `${pack[2]} Boost${pack[2] === "1" ? "" : "s"}` : `${pack[2]} Super Likes`;
  return "mazl";
}
