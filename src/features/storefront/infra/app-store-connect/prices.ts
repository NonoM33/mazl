import type { ApplePriceChangePlan, ApplePricePoint, StorePrice, Territory } from "../../application/ports";
import type { AscCatalog } from "./catalog";
import { type AscClient, indexById, query, relatedId, type Resource, stringAttr } from "./client";
import { type DatedPrice, effectivePrice, todayIso } from "./effective-price";
import { AscResponseError, PriceChangeError } from "./errors";

export interface CurrentSubscriptionPrice {
  readonly territory: Territory;
  readonly currency: string;
  readonly customerPrice: string;
  readonly pricePointId: string;
}

const PAGE = "200";
const APPLY_CONCURRENCY = 5;

export class AscPrices {
  constructor(
    private readonly client: AscClient,
    private readonly catalog: AscCatalog,
    private readonly clock: () => number,
  ) {}

  async currentPrices(productId: string, territories: readonly Territory[]): Promise<readonly StorePrice[]> {
    const product = await this.catalog.resolve(productId);
    if (product.kind === "subscription") {
      const current = await this.subscriptionPrices(product.id, territories);
      return current.map(({ territory, currency, customerPrice }) => ({ territory, currency, customerPrice }));
    }
    return this.consumablePrices(product.id, territories);
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-subscriptions-_id_-prices
  async subscriptionPrices(subscriptionId: string, territories: readonly Territory[]): Promise<readonly CurrentSubscriptionPrice[]> {
    const params: Record<string, string> = { include: "subscriptionPricePoint,territory", limit: PAGE };
    if (territories.length > 0) params["filter[territory]"] = territories.join(",");
    const page = await this.client.getAll(`/v1/subscriptions/${subscriptionId}/prices?${query(params)}`);
    const points = indexById(page.included, "subscriptionPricePoints");
    const currencies = indexById(page.included, "territories");
    const byTerritory = new Map<string, DatedPrice<CurrentSubscriptionPrice>[]>();
    for (const price of page.data) {
      const territory = relatedId(price, "territory");
      const pointId = relatedId(price, "subscriptionPricePoint");
      const point = pointId === undefined ? undefined : points.get(pointId);
      const customerPrice = point === undefined ? undefined : stringAttr(point, "customerPrice");
      if (territory === undefined || pointId === undefined || customerPrice === undefined) continue;
      const currency = stringAttr(currencies.get(territory) ?? price, "currency") ?? "";
      const list = byTerritory.get(territory) ?? [];
      list.push({
        startDate: stringAttr(price, "startDate") ?? null,
        preserved: price.attributes?.preserved === true,
        monthlyPlan: stringAttr(price, "planType") === "MONTHLY",
        value: { territory, currency, customerPrice, pricePointId: pointId },
      });
      byTerritory.set(territory, list);
    }
    const today = todayIso(this.clock);
    const found = [...byTerritory.values()].flatMap((list) => effectivePrice(list, today) ?? []);
    // Same order as asked for, not Apple's.
    return territories.length === 0 ? found : [...found].sort((a, b) => territories.indexOf(a.territory) - territories.indexOf(b.territory));
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/get-v2-inapppurchases-_id_-iappriceschedule
  // (manualPrices and automaticPrices are its two price lists)
  private async consumablePrices(iapId: string, territories: readonly Territory[]): Promise<readonly StorePrice[]> {
    const today = todayIso(this.clock);
    const found = new Map<string, StorePrice>();
    // Automatic first, then manual overrides: a manual price wins over the one derived from the base territory.
    for (const list of ["automaticPrices", "manualPrices"] as const) {
      const params: Record<string, string> = { include: "inAppPurchasePricePoint,territory", limit: PAGE };
      if (territories.length > 0) params["filter[territory]"] = territories.join(",");
      // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-inapppurchasepriceschedules-_id_-manualprices
      // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-inapppurchasepriceschedules-_id_-automaticprices
      const page = await this.client.getAll(`/v1/inAppPurchasePriceSchedules/${iapId}/${list}?${query(params)}`);
      const points = indexById(page.included, "inAppPurchasePricePoints");
      const currencies = indexById(page.included, "territories");
      const byTerritory = new Map<string, DatedPrice<StorePrice>[]>();
      for (const price of page.data) {
        const territory = relatedId(price, "territory");
        const pointId = relatedId(price, "inAppPurchasePricePoint");
        const point = pointId === undefined ? undefined : points.get(pointId);
        const customerPrice = point === undefined ? undefined : stringAttr(point, "customerPrice");
        if (territory === undefined || customerPrice === undefined) continue;
        const entries = byTerritory.get(territory) ?? [];
        entries.push({
          startDate: stringAttr(price, "startDate") ?? null,
          endDate: stringAttr(price, "endDate") ?? null,
          value: { territory, currency: stringAttr(currencies.get(territory) ?? price, "currency") ?? "", customerPrice },
        });
        byTerritory.set(territory, entries);
      }
      for (const [territory, entries] of byTerritory) {
        const price = effectivePrice(entries, today);
        if (price !== undefined) found.set(territory, price);
      }
    }
    return [...found.values()];
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-subscriptions-_id_-pricepoints
  async pricePoints(productId: string, territory: Territory): Promise<readonly ApplePricePoint[]> {
    const product = await this.catalog.subscription(productId, "Price points");
    const page = await this.client.getAll(
      `/v1/subscriptions/${product.id}/pricePoints?${query({ "filter[territory]": territory, limit: PAGE })}`,
    );
    return page.data.flatMap((r) => toPricePoint(r, territory));
  }

  // Everything the change would do, country by country. Reads only.
  async planPriceChange(productId: string, basePricePointId: string, startDate: string, preserveCurrentPrice: boolean): Promise<ApplePriceChangePlan> {
    const product = await this.catalog.subscription(productId, "A price change");
    // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-subscriptionpricepoints-_id_
    const base = await this.client.getOne(`/v1/subscriptionPricePoints/${basePricePointId}?include=territory`);
    const baseTerritory = relatedId(base.data, "territory");
    const baseTo = stringAttr(base.data, "customerPrice");
    if (baseTerritory === undefined || baseTo === undefined) throw new AscResponseError(`/v1/subscriptionPricePoints/${basePricePointId}`, "price point without territory or customerPrice");
    // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-subscriptionpricepoints-_id_-equalizations
    const equalized = await this.client.getAll(
      `/v1/subscriptionPricePoints/${basePricePointId}/equalizations?${query({ include: "territory", limit: PAGE })}`,
    );
    const current = new Map((await this.subscriptionPrices(product.id, [])).map((p) => [p.territory, p]));
    const targets = [
      { territory: baseTerritory, to: baseTo, pricePointId: basePricePointId },
      ...equalized.data.flatMap((r) => {
        const territory = relatedId(r, "territory");
        const to = stringAttr(r, "customerPrice");
        return territory === undefined || to === undefined ? [] : [{ territory, to, pricePointId: r.id }];
      }),
    ];
    const changes = targets
      .filter((t) => current.get(t.territory)?.pricePointId !== t.pricePointId)
      .map((t) => ({ territory: t.territory, from: current.get(t.territory)?.customerPrice ?? null, to: t.to, pricePointId: t.pricePointId }));
    return { productId, startDate, preserveCurrentPrice, changes };
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/post-v1-subscriptionprices
  async applyPriceChange(plan: ApplePriceChangePlan): Promise<void> {
    const product = await this.catalog.subscription(plan.productId, "A price change");
    const applied: string[] = [];
    const failures: { territory: string; error: Error }[] = [];
    for (let i = 0; i < plan.changes.length; i += APPLY_CONCURRENCY) {
      const batch = plan.changes.slice(i, i + APPLY_CONCURRENCY);
      const results = await Promise.allSettled(
        batch.map((change) =>
          this.client.post("/v1/subscriptionPrices", {
            data: {
              type: "subscriptionPrices",
              attributes: { startDate: plan.startDate, preserveCurrentPrice: plan.preserveCurrentPrice },
              relationships: {
                subscription: { data: { type: "subscriptions", id: product.id } },
                subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: change.pricePointId } },
                territory: { data: { type: "territories", id: change.territory } },
              },
            },
          }),
        ),
      );
      results.forEach((result, index) => {
        const territory = batch[index]?.territory ?? "?";
        if (result.status === "fulfilled") applied.push(territory);
        else failures.push({ territory, error: result.reason instanceof Error ? result.reason : new Error(String(result.reason)) });
      });
    }
    if (failures.length > 0) throw new PriceChangeError(applied, failures);
  }
}

function toPricePoint(resource: Resource, fallbackTerritory: Territory): ApplePricePoint[] {
  const customerPrice = stringAttr(resource, "customerPrice");
  const proceeds = stringAttr(resource, "proceeds");
  if (customerPrice === undefined || proceeds === undefined) return [];
  return [{ id: resource.id, territory: relatedId(resource, "territory") ?? fallbackTerritory, customerPrice, proceeds }];
}
