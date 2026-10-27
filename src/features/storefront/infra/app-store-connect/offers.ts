import type { AppleOfferCode, AppleOfferCodeRequest } from "../../application/ports";
import type { AscCatalog } from "./catalog";
import { type AscClient, query, relatedId, stringAttr } from "./client";
import { AscApiError, OfferCodeError } from "./errors";
import type { AscPrices } from "./prices";

const PAGE = "200";
export const DEFAULT_NUMBER_OF_CODES = 100_000;

// SubscriptionOfferDuration values that equal a subscription's own period.
// https://developer.apple.com/documentation/appstoreconnectapi/subscriptionofferduration
const OFFER_DURATIONS = new Set(["ONE_MONTH", "TWO_MONTHS", "THREE_MONTHS", "SIX_MONTHS", "ONE_YEAR", "ONE_WEEK"]);

const cents = (price: string): number => Math.round(Number(price) * 100);

export class AscOffers {
  constructor(
    private readonly client: AscClient,
    private readonly catalog: AscCatalog,
    private readonly prices: AscPrices,
    private readonly numberOfCodes: number = DEFAULT_NUMBER_OF_CODES,
  ) {}

  async create(request: AppleOfferCodeRequest): Promise<AppleOfferCode> {
    validate(request);
    const product = await this.catalog.subscription(request.productId, "An offer code");
    if (!OFFER_DURATIONS.has(product.period)) {
      throw new OfferCodeError(`Subscription period ${product.period || "(unknown)"} has no matching offer duration`);
    }
    const reduced = await this.reducedPricePoints(request);
    const offerCodeId = await this.createOffer(request, product.id, product.period, reduced);
    try {
      const custom = await this.createCustomCode(request, offerCodeId);
      return { productId: request.productId, offerCodeId, customCodeId: custom, customCode: request.customCode };
    } catch (error) {
      await this.deactivateQuietly(offerCodeId);
      throw error;
    }
  }

  async deactivate(code: AppleOfferCode): Promise<void> {
    const failures: unknown[] = [];
    // https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-subscriptionoffercodecustomcodes-_id_
    // https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-subscriptionoffercodes-_id_
    const steps: readonly [string, string, string][] = [
      ["subscriptionOfferCodeCustomCodes", "/v1/subscriptionOfferCodeCustomCodes/", code.customCodeId],
      ["subscriptionOfferCodes", "/v1/subscriptionOfferCodes/", code.offerCodeId],
    ];
    for (const [type, base, id] of steps) {
      try {
        await this.client.patch(`${base}${id}`, { data: { type, id, attributes: { active: false } } });
      } catch (error) {
        failures.push(error);
      }
    }
    if (failures.length > 0) throw new OfferCodeError(`Could not fully deactivate offer code ${code.customCode}`, failures[0]);
  }

  // One price point per territory: FRA's closest to price x (1 - discount), the others by Apple's equalizations.
  private async reducedPricePoints(request: AppleOfferCodeRequest): Promise<readonly { territory: string; pricePointId: string }[]> {
    const product = await this.catalog.subscription(request.productId, "An offer code");
    const [france] = await this.prices.subscriptionPrices(product.id, ["FRA"]);
    if (france === undefined) throw new OfferCodeError(`No current price in FRA for ${request.productId}`);
    const target = (cents(france.customerPrice) * (100 - request.discountPercent)) / 100;
    const points = await this.prices.pricePoints(request.productId, "FRA");
    const closest = [...points].sort(
      (a, b) => Math.abs(cents(a.customerPrice) - target) - Math.abs(cents(b.customerPrice) - target) || cents(a.customerPrice) - cents(b.customerPrice),
    )[0];
    if (closest === undefined) throw new OfferCodeError(`No price point in FRA for ${request.productId}`);
    // https://developer.apple.com/documentation/appstoreconnectapi/get-v1-subscriptionpricepoints-_id_-equalizations
    const equalized = await this.client.getAll(
      `/v1/subscriptionPricePoints/${closest.id}/equalizations?${query({ include: "territory", limit: PAGE })}`,
    );
    const others = equalized.data.flatMap((r) => {
      const territory = relatedId(r, "territory");
      return territory === undefined ? [] : [{ territory, pricePointId: r.id }];
    });
    return [{ territory: "FRA", pricePointId: closest.id }, ...others];
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/post-v1-subscriptionoffercodes
  private async createOffer(
    request: AppleOfferCodeRequest,
    subscriptionId: string,
    duration: string,
    points: readonly { territory: string; pricePointId: string }[],
  ): Promise<string> {
    const localId = (territory: string): string => `\${price-${territory}}`;
    const body = (offerEligibility: string): unknown => ({
      data: {
        type: "subscriptionOfferCodes",
        attributes: {
          name: request.name,
          customerEligibilities: ["NEW", "EXISTING", "EXPIRED"],
          offerEligibility,
          duration,
          offerMode: "PAY_AS_YOU_GO",
          numberOfPeriods: 1,
          autoRenewEnabled: true,
        },
        relationships: {
          subscription: { data: { type: "subscriptions", id: subscriptionId } },
          prices: { data: points.map((p) => ({ type: "subscriptionOfferCodePrices", id: localId(p.territory) })) },
        },
      },
      included: points.map((p) => ({
        type: "subscriptionOfferCodePrices",
        id: localId(p.territory),
        relationships: {
          subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: p.pricePointId } },
          territory: { data: { type: "territories", id: p.territory } },
        },
      })),
    });
    try {
      return (await this.client.post("/v1/subscriptionOfferCodes", body("STACK_WITH_INTRO_OFFERS"))).id;
    } catch (error) {
      // Only a refusal that names offerEligibility falls back to REPLACE_INTRO_OFFERS; nothing was created.
      if (!(error instanceof AscApiError) || error.status >= 500 || !error.errors.some((e) => e.pointer?.includes("offerEligibility") === true)) throw error;
      return (await this.client.post("/v1/subscriptionOfferCodes", body("REPLACE_INTRO_OFFERS"))).id;
    }
  }

  // https://developer.apple.com/documentation/appstoreconnectapi/post-v1-subscriptionoffercodecustomcodes
  private async createCustomCode(request: AppleOfferCodeRequest, offerCodeId: string): Promise<string> {
    const created = await this.client.post("/v1/subscriptionOfferCodeCustomCodes", {
      data: {
        type: "subscriptionOfferCodeCustomCodes",
        attributes: { customCode: request.customCode, numberOfCodes: this.numberOfCodes, expirationDate: request.expiresOn },
        relationships: { offerCode: { data: { type: "subscriptionOfferCodes", id: offerCodeId } } },
      },
    });
    if (stringAttr(created, "customCode") !== undefined && stringAttr(created, "customCode") !== request.customCode) {
      throw new OfferCodeError("Apple created a custom code different from the requested one");
    }
    return created.id;
  }

  private async deactivateQuietly(offerCodeId: string): Promise<void> {
    try {
      await this.client.patch(`/v1/subscriptionOfferCodes/${offerCodeId}`, {
        data: { type: "subscriptionOfferCodes", id: offerCodeId, attributes: { active: false } },
      });
    } catch {
      // The original failure is the one to report; the orphan offer stays inactive-or-visible in App Store Connect.
    }
  }
}

function validate(request: AppleOfferCodeRequest): void {
  if (!Number.isInteger(request.discountPercent) || request.discountPercent < 1 || request.discountPercent > 99) {
    throw new OfferCodeError("discountPercent must be an integer between 1 and 99");
  }
  if (!/^[A-Z0-9]{6,64}$/.test(request.customCode)) throw new OfferCodeError("customCode must be 6 to 64 characters A-Z or 0-9");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(request.expiresOn)) throw new OfferCodeError("expiresOn must be YYYY-MM-DD");
  if (request.name.length === 0 || request.name.length > 64) throw new OfferCodeError("name must be 1 to 64 characters");
}
