import { type AscClient, query, stringAttr } from "./client";
import { UnknownProductError, UnsupportedProductError } from "./errors";

export type AscProduct =
  | { readonly kind: "subscription"; readonly productId: string; readonly id: string; readonly period: string }
  | { readonly kind: "consumable"; readonly productId: string; readonly id: string };

// productId (com.mazl.app.plus.3m) -> App Store Connect resource id, looked up once.
export class AscCatalog {
  private readonly known = new Map<string, AscProduct>();

  constructor(
    private readonly client: AscClient,
    private readonly appId: string,
    private readonly groupId: string,
  ) {}

  async resolve(productId: string): Promise<AscProduct> {
    const cached = this.known.get(productId);
    if (cached !== undefined) return cached;
    const found = (await this.findSubscription(productId)) ?? (await this.findInAppPurchase(productId));
    if (found === undefined) throw new UnknownProductError(productId);
    this.known.set(productId, found);
    return found;
  }

  async subscription(productId: string, operation: string): Promise<Extract<AscProduct, { kind: "subscription" }>> {
    const product = await this.resolve(productId);
    if (product.kind !== "subscription") throw new UnsupportedProductError(productId, operation);
    return product;
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-subscriptiongroups-_id_-subscriptions
  private async findSubscription(productId: string): Promise<AscProduct | undefined> {
    const page = await this.client.getAll(
      `/v1/subscriptionGroups/${this.groupId}/subscriptions?${query({ "filter[productId]": productId, limit: "200" })}`,
    );
    const match = page.data.find((r) => stringAttr(r, "productId") === productId);
    if (match === undefined) return undefined;
    return { kind: "subscription", productId, id: match.id, period: stringAttr(match, "subscriptionPeriod") ?? "" };
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-apps-_id_-inapppurchasesv2
  private async findInAppPurchase(productId: string): Promise<AscProduct | undefined> {
    const page = await this.client.getAll(
      `/v1/apps/${this.appId}/inAppPurchasesV2?${query({ "filter[productId]": productId, limit: "200" })}`,
    );
    const match = page.data.find((r) => stringAttr(r, "productId") === productId);
    return match === undefined ? undefined : { kind: "consumable", productId, id: match.id };
  }
}
