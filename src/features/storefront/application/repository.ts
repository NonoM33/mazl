import type { AppleCampaignState, Campaign, CampaignInput, StoredCampaignStatus, StripeCampaignState } from "../domain/campaign";
import type { LocalizedText } from "../domain/languages";
import type { ProductDisplay } from "../domain/products";

export interface ProductPatch {
  readonly visible?: boolean;
  readonly sortOrder?: number;
  readonly featured?: boolean;
  readonly highlight?: LocalizedText | null;
}

export interface CampaignStatePatch {
  readonly status?: StoredCampaignStatus;
  readonly apple?: AppleCampaignState;
  readonly stripe?: StripeCampaignState;
}

export interface PriceChangeEntry {
  readonly actor: string;
  readonly productId: string;
  readonly platform: "apple" | "web";
  readonly territory: string | null;
  readonly oldPrice: string | null;
  readonly newPrice: string;
  readonly currency: string | null;
  // Day the new price starts (Apple) or the day it was written (web).
  readonly effectiveDate: string | null;
  readonly result: "applied" | "failed";
  readonly error: string | null;
}

export interface StorefrontRepository {
  // Ordered by sortOrder.
  listProducts(): Promise<readonly ProductDisplay[]>;
  getProduct(productId: string): Promise<ProductDisplay | null>;
  updateProduct(productId: string, patch: ProductPatch, by: string): Promise<ProductDisplay>;
  setStripePriceId(productId: string, priceId: string, by: string): Promise<ProductDisplay>;

  // Campaigns that overlap [from, to) when given, all of them otherwise; oldest start first.
  listCampaigns(range?: { readonly from: Date; readonly to: Date }): Promise<readonly Campaign[]>;
  getCampaign(id: number): Promise<Campaign | null>;
  insertCampaign(input: CampaignInput, by: string): Promise<Campaign>;
  updateCampaign(id: number, input: CampaignInput): Promise<Campaign>;
  // Writes the state of a campaign. A move to `scheduled` is refused with
  // CampaignOverlapError when another scheduled campaign overlaps, atomically.
  saveCampaignState(id: number, patch: CampaignStatePatch): Promise<Campaign>;
  scheduledCampaigns(): Promise<readonly Campaign[]>;
  // Every custom offer code ever created, cancelled campaigns included.
  takenOfferCodes(): Promise<ReadonlySet<string>>;

  recordPriceChange(entry: PriceChangeEntry): Promise<void>;
}
