import type { AuditEntry, AuditEntryInput, AuditLog } from "../../../src/features/audit/application/ports";
import type {
  AppStorePricing,
  AppleOfferCode,
  AppleOfferCodeRequest,
  ApplePriceChangePlan,
  ApplePricePoint,
  StorePrice,
  WebPrice,
  WebPricing,
  WebPromotion,
} from "../../../src/features/storefront/application/ports";
import type { CampaignStatePatch, PriceChangeEntry, ProductPatch, StorefrontRepository } from "../../../src/features/storefront/application/repository";
import { EMPTY_APPLE_STATE, EMPTY_STRIPE_STATE, type Campaign, type CampaignInput } from "../../../src/features/storefront/domain/campaign";
import { CampaignNotFoundError, CampaignOverlapError, ProductNotFoundError } from "../../../src/features/storefront/domain/errors";
import { CATALOG_PRODUCTS, type ProductDisplay } from "../../../src/features/storefront/domain/products";

export class MemoryRepository implements StorefrontRepository {
  products = new Map<string, ProductDisplay>(
    CATALOG_PRODUCTS.map((p) => [
      p.productId,
      { productId: p.productId, visible: true, sortOrder: p.defaultSortOrder, featured: p.defaultFeatured, highlight: null, stripePriceId: null, updatedAt: new Date(0), updatedBy: null },
    ]),
  );
  campaigns: Campaign[] = [];
  priceChanges: PriceChangeEntry[] = [];
  private nextId = 1;

  async listProducts() {
    return [...this.products.values()].sort((a, b) => a.sortOrder - b.sortOrder);
  }
  async getProduct(productId: string) {
    return this.products.get(productId) ?? null;
  }
  async updateProduct(productId: string, patch: ProductPatch, by: string) {
    const current = this.products.get(productId);
    if (current === undefined) throw new ProductNotFoundError(productId);
    const next: ProductDisplay = {
      ...current,
      ...(patch.visible === undefined ? {} : { visible: patch.visible }),
      ...(patch.sortOrder === undefined ? {} : { sortOrder: patch.sortOrder }),
      ...(patch.featured === undefined ? {} : { featured: patch.featured }),
      ...(patch.highlight === undefined ? {} : { highlight: patch.highlight }),
      updatedBy: by,
    };
    this.products.set(productId, next);
    return next;
  }
  async setStripePriceId(productId: string, priceId: string, by: string) {
    const current = this.products.get(productId);
    if (current === undefined) throw new ProductNotFoundError(productId);
    const next = { ...current, stripePriceId: priceId, updatedBy: by };
    this.products.set(productId, next);
    return next;
  }
  async listCampaigns(range?: { from: Date; to: Date }) {
    return this.campaigns.filter((c) => range === undefined || (c.startsAt < range.to && c.endsAt > range.from)).sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
  }
  async getCampaign(id: number) {
    return this.campaigns.find((c) => c.id === id) ?? null;
  }
  async insertCampaign(input: CampaignInput, by: string) {
    const campaign: Campaign = {
      ...input,
      id: this.nextId++,
      status: "draft",
      apple: EMPTY_APPLE_STATE,
      stripe: EMPTY_STRIPE_STATE,
      createdBy: by,
      createdAt: new Date(0),
      updatedAt: new Date(0),
    };
    this.campaigns.push(campaign);
    return campaign;
  }
  async updateCampaign(id: number, input: CampaignInput) {
    const current = await this.getCampaign(id);
    if (current === null) throw new CampaignNotFoundError(id);
    const next = { ...current, ...input };
    this.campaigns = this.campaigns.map((c) => (c.id === id ? next : c));
    return next;
  }
  async saveCampaignState(id: number, patch: CampaignStatePatch) {
    const current = await this.getCampaign(id);
    if (current === null) throw new CampaignNotFoundError(id);
    if (patch.status === "scheduled") {
      const clash = this.campaigns.find((c) => c.status === "scheduled" && c.id !== id && c.startsAt < current.endsAt && current.startsAt < c.endsAt);
      if (clash !== undefined) throw new CampaignOverlapError(clash.id);
    }
    const next: Campaign = { ...current, status: patch.status ?? current.status, apple: patch.apple ?? current.apple, stripe: patch.stripe ?? current.stripe };
    this.campaigns = this.campaigns.map((c) => (c.id === id ? next : c));
    return next;
  }
  async scheduledCampaigns() {
    return this.campaigns.filter((c) => c.status === "scheduled");
  }
  async takenOfferCodes() {
    return new Set(this.campaigns.flatMap((c) => c.apple.codes.map((code) => code.customCode)));
  }
  async recordPriceChange(entry: PriceChangeEntry) {
    this.priceChanges.push(entry);
  }
}

export class MemoryAudit implements AuditLog {
  entries: AuditEntryInput[] = [];
  async record(entry: AuditEntryInput): Promise<AuditEntry> {
    this.entries.push(entry);
    return { ...entry, id: this.entries.length, createdAt: new Date(0).toISOString(), previousHash: "", hash: "" };
  }
  async list() {
    return { entries: [], total: 0 };
  }
  async verify() {
    return { ok: true as const, entries: 0, headHash: "" };
  }
}

// A fake Apple that remembers every call. Only the real method names exist on it.
export class FakeApple implements AppStorePricing {
  calls: string[] = [];
  created: AppleOfferCodeRequest[] = [];
  deactivated: AppleOfferCode[] = [];
  applied: ApplePriceChangePlan[] = [];
  failOn: "create" | "apply" | "deactivate" | null = null;
  failAfterCreates = Number.POSITIVE_INFINITY;
  private counter = 0;

  async currentPrices(): Promise<readonly StorePrice[]> {
    this.calls.push("currentPrices");
    return [{ territory: "FRA", currency: "EUR", customerPrice: "24.99" }];
  }
  async pricePoints(productId: string, territory: string): Promise<readonly ApplePricePoint[]> {
    this.calls.push("pricePoints");
    return [{ id: `pp_${productId}_${territory}`, territory, customerPrice: "26.99", proceeds: "18.90" }];
  }
  async planPriceChange(productId: string, basePricePointId: string, startDate: string, preserveCurrentPrice: boolean): Promise<ApplePriceChangePlan> {
    this.calls.push("planPriceChange");
    return { productId, startDate, preserveCurrentPrice, changes: [{ territory: "FRA", from: "24.99", to: "26.99", pricePointId: basePricePointId }, { territory: "USA", from: null, to: "28.99", pricePointId: "pp_usa" }] };
  }
  async applyPriceChange(plan: ApplePriceChangePlan): Promise<void> {
    this.calls.push("applyPriceChange");
    if (this.failOn === "apply") throw new Error("apple refused the price");
    this.applied.push(plan);
  }
  async createOfferCode(request: AppleOfferCodeRequest): Promise<AppleOfferCode> {
    this.calls.push("createOfferCode");
    if (this.failOn === "create" || this.created.length >= this.failAfterCreates) throw new Error("apple down");
    this.created.push(request);
    this.counter += 1;
    return { productId: request.productId, offerCodeId: `oc_${String(this.counter)}`, customCodeId: `cc_${String(this.counter)}`, customCode: request.customCode };
  }
  async deactivateOfferCode(code: AppleOfferCode): Promise<void> {
    this.calls.push("deactivateOfferCode");
    if (this.failOn === "deactivate") throw new Error("apple down");
    this.deactivated.push(code);
  }
}

export class FakeStripe implements WebPricing {
  calls: string[] = [];
  promotions: { name: string; percentOff: number; prices: readonly string[]; redeemBy: Date }[] = [];
  prices: { productId: string; amountCents: number; currency: string; months: number | null }[] = [];
  deactivated: WebPromotion[] = [];
  fail = false;
  private counter = 0;

  async currentPrice(priceId: string): Promise<WebPrice> {
    this.calls.push("currentPrice");
    return { priceId, amountCents: 2499, currency: "eur" };
  }
  async createPrice(productId: string, amountCents: number, currency: string, recurringMonths: number | null): Promise<WebPrice> {
    this.calls.push("createPrice");
    if (this.fail) throw new Error("stripe down");
    this.prices.push({ productId, amountCents, currency, months: recurringMonths });
    this.counter += 1;
    return { priceId: `price_new_${String(this.counter)}`, amountCents, currency };
  }
  async createPromotion(name: string, percentOff: number, appliesToPriceIds: readonly string[], redeemBy: Date): Promise<WebPromotion> {
    this.calls.push("createPromotion");
    if (this.fail) throw new Error("stripe down");
    this.promotions.push({ name, percentOff, prices: appliesToPriceIds, redeemBy });
    this.counter += 1;
    return { couponId: `coupon_${String(this.counter)}`, promotionCodeId: `promo_${String(this.counter)}` };
  }
  async deactivatePromotion(promotion: WebPromotion): Promise<void> {
    this.calls.push("deactivatePromotion");
    if (this.fail) throw new Error("stripe down");
    this.deactivated.push(promotion);
  }
}
