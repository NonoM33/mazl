import type { AppStorePricing } from "../../application/ports";
import { AscCatalog } from "./catalog";
import { AscClient, type FetchLike } from "./client";
import { readAscConfig } from "./config";
import { AscTokenProvider } from "./jwt";
import { AscOffers } from "./offers";
import { AscPrices } from "./prices";

export * from "./errors";
export { readAscConfig } from "./config";

export interface AppStorePricingOptions {
  readonly fetch?: FetchLike;
  readonly clock?: () => number;
  readonly baseUrl?: string;
  readonly numberOfCodes?: number;
}

type Env = Readonly<Record<string, string | undefined>>;

// null when ASC_KEY_ID / ASC_ISSUER_ID / ASC_PRIVATE_KEY are missing: the server answers `store_not_configured`.
export function createAppStorePricing(env: Env, options: AppStorePricingOptions = {}): AppStorePricing | null {
  const config = readAscConfig(env);
  if (config === null) return null;
  const clock = options.clock ?? (() => Date.now());
  const tokens = new AscTokenProvider(config, clock);
  const client = new AscClient(tokens, options.fetch ?? ((url, init) => fetch(url, init)), options.baseUrl);
  const catalog = new AscCatalog(client, config.appId, config.subscriptionGroupId);
  const prices = new AscPrices(client, catalog, clock);
  const offers = new AscOffers(client, catalog, prices, options.numberOfCodes);
  return {
    currentPrices: (productId, territories) => prices.currentPrices(productId, territories),
    pricePoints: (productId, territory) => prices.pricePoints(productId, territory),
    planPriceChange: (productId, basePricePointId, startDate, preserve) => prices.planPriceChange(productId, basePricePointId, startDate, preserve),
    applyPriceChange: (plan) => prices.applyPriceChange(plan),
    createOfferCode: (request) => offers.create(request),
    deactivateOfferCode: (code) => offers.deactivate(code),
  };
}
