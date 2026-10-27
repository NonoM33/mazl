import { StoreNotConfiguredError } from "../domain/errors";
import type { AppStorePricing, WebPricing } from "../application/ports";

// Wired while a store has no adapter (credentials missing): every call says so, nothing is sent.
export const appStoreNotConfigured: AppStorePricing = {
  currentPrices: () => Promise.reject(new StoreNotConfiguredError("apple")),
  pricePoints: () => Promise.reject(new StoreNotConfiguredError("apple")),
  planPriceChange: () => Promise.reject(new StoreNotConfiguredError("apple")),
  applyPriceChange: () => Promise.reject(new StoreNotConfiguredError("apple")),
  createOfferCode: () => Promise.reject(new StoreNotConfiguredError("apple")),
  deactivateOfferCode: () => Promise.reject(new StoreNotConfiguredError("apple")),
};

export const webPricingNotConfigured: WebPricing = {
  currentPrice: () => Promise.reject(new StoreNotConfiguredError("stripe")),
  createPrice: () => Promise.reject(new StoreNotConfiguredError("stripe")),
  createPromotion: () => Promise.reject(new StoreNotConfiguredError("stripe")),
  deactivatePromotion: () => Promise.reject(new StoreNotConfiguredError("stripe")),
};
