// Business errors of the storefront. `code` is the stable identifier the API sends.

export abstract class StorefrontError extends Error {
  abstract readonly code: string;
}

export class ProductNotFoundError extends StorefrontError {
  readonly code = "product_not_found";
  constructor(readonly productId: string) {
    super(`Unknown product ${productId}`);
    this.name = "ProductNotFoundError";
  }
}

export class CampaignNotFoundError extends StorefrontError {
  readonly code = "campaign_not_found";
  constructor(readonly campaignId: number) {
    super(`Unknown campaign ${String(campaignId)}`);
    this.name = "CampaignNotFoundError";
  }
}

export class InvalidCampaignError extends StorefrontError {
  readonly code = "invalid_campaign";
  constructor(readonly problems: readonly string[]) {
    super(problems.join(" ; "));
    this.name = "InvalidCampaignError";
  }
}

export class CampaignOverlapError extends StorefrontError {
  readonly code = "campaign_overlap";
  constructor(readonly conflictingId: number) {
    super(`The campaign overlaps the scheduled campaign ${String(conflictingId)}`);
    this.name = "CampaignOverlapError";
  }
}

export class CampaignNotEditableError extends StorefrontError {
  readonly code = "campaign_not_editable";
  constructor(reason: string) {
    super(reason);
    this.name = "CampaignNotEditableError";
  }
}

export class CampaignStateError extends StorefrontError {
  readonly code = "campaign_wrong_state";
  constructor(reason: string) {
    super(reason);
    this.name = "CampaignStateError";
  }
}

export class InvalidPriceChangeError extends StorefrontError {
  readonly code = "invalid_price_change";
  constructor(reason: string) {
    super(reason);
    this.name = "InvalidPriceChangeError";
  }
}

export type StoreName = "apple" | "stripe";

// No adapter is wired for this store (credentials missing): nothing was sent.
export class StoreNotConfiguredError extends StorefrontError {
  readonly code = "store_not_configured";
  constructor(readonly store: StoreName) {
    super(`The ${store} store is not configured on this server`);
    this.name = "StoreNotConfiguredError";
  }
}

// The store answered with a failure, or did not answer.
export class StoreCallError extends StorefrontError {
  readonly code = "store_error";
  constructor(
    readonly store: StoreName,
    reason: string,
  ) {
    super(`${store}: ${reason}`);
    this.name = "StoreCallError";
  }
}
