import { OFFERS, type Offer } from "../domain/offers";
import { WITHDRAWAL_TEXT, WITHDRAWAL_VERSION } from "../domain/withdrawal";
import type { Clock } from "./clock";
import type { StripeGateway } from "./ports";
import type { BillingSettings } from "./settings";

export interface CatalogOffer {
  readonly id: string;
  readonly kind: "subscription" | "credits";
  readonly months?: number;
  readonly credit_kind?: "boost" | "super_like";
  readonly quantity?: number;
  readonly amount_ttc_cents: number;
  readonly featured: boolean;
  readonly per_month_ttc_cents?: number;
}

export interface CatalogView {
  readonly available: boolean;
  readonly currency: "EUR";
  readonly offers: readonly CatalogOffer[];
  readonly withdrawal: { readonly text: string; readonly version: string };
}

const CACHE_MS = 10 * 60_000;

export const WITHDRAWAL_VIEW = { text: WITHDRAWAL_TEXT, version: WITHDRAWAL_VERSION } as const;

export function unavailableCatalog(): CatalogView {
  return { available: false, currency: "EUR", offers: [], withdrawal: WITHDRAWAL_VIEW };
}

function describe(offer: Offer, amount: number): CatalogOffer {
  if (offer.kind === "subscription") {
    return {
      id: offer.id,
      kind: "subscription",
      months: offer.months,
      amount_ttc_cents: amount,
      featured: offer.featured,
      per_month_ttc_cents: Math.round(amount / offer.months),
    };
  }
  return { id: offer.id, kind: "credits", credit_kind: offer.creditKind, quantity: offer.quantity, amount_ttc_cents: amount, featured: false };
}

// Amounts come from Stripe (never hard-coded) and are cached for ten minutes.
export class CatalogService {
  private cache: { readonly at: number; readonly view: CatalogView } | undefined;

  constructor(
    private readonly gateway: StripeGateway,
    private readonly settings: BillingSettings,
    private readonly clock: Clock,
  ) {}

  async catalog(): Promise<CatalogView> {
    const at = this.clock().getTime();
    if (this.cache !== undefined && at - this.cache.at < CACHE_MS) return this.cache.view;
    const offers = (await Promise.all(OFFERS.map((offer) => this.describeOffer(offer)))).filter((o): o is CatalogOffer => o !== undefined);
    const view: CatalogView = { available: true, currency: "EUR", offers, withdrawal: WITHDRAWAL_VIEW };
    this.cache = { at, view };
    return view;
  }

  private async describeOffer(offer: Offer): Promise<CatalogOffer | undefined> {
    const priceId = this.settings.prices[offer.id];
    if (priceId === undefined) return undefined;
    const price = await this.gateway.retrievePrice(priceId);
    if (price.unitAmount === null) {
      console.warn(`Stripe price ${priceId} (${offer.id}) has no fixed amount: offer hidden`);
      return undefined;
    }
    if (price.taxBehavior !== "inclusive") {
      console.warn(`Stripe price ${priceId} (${offer.id}) is not tax inclusive (${price.taxBehavior ?? "none"}): the displayed amount may not be TTC`);
    }
    return describe(offer, price.unitAmount);
  }
}
