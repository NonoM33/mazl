import { createHash } from "node:crypto";
import { AlreadySubscribedError, NoCustomerError, OfferUnavailableError, WithdrawalWaiverRequiredError } from "../domain/errors";
import type { Offer } from "../domain/offers";
import { WITHDRAWAL_TEXT, WITHDRAWAL_VERSION } from "../domain/withdrawal";
import type { BillingRepository, StripeGateway } from "./ports";
import type { BillingSettings } from "./settings";

export interface CheckoutRequest {
  readonly offer: Offer;
  readonly waiverAccepted: boolean | undefined;
  readonly waiverVersion: string | undefined;
}

export const WITHDRAWAL_SHA256 = createHash("sha256").update(WITHDRAWAL_TEXT).digest("hex");

export class CheckoutService {
  constructor(
    private readonly gateway: StripeGateway,
    private readonly repository: BillingRepository,
    private readonly settings: BillingSettings,
  ) {}

  async start(userId: number, request: CheckoutRequest): Promise<{ readonly url: string }> {
    const { offer } = request;
    if (request.waiverAccepted !== true || request.waiverVersion !== WITHDRAWAL_VERSION) throw new WithdrawalWaiverRequiredError();
    const priceId = this.settings.prices[offer.id];
    if (priceId === undefined) throw new OfferUnavailableError(offer.id);
    if (offer.kind === "subscription") await this.refuseSecondSubscription(userId);
    const customerId = await this.customerOf(userId);
    // The proof exists before the member can pay, and survives a failed session.
    const waiverId = await this.repository.recordWaiver({
      userId,
      offer: offer.id,
      textVersion: WITHDRAWAL_VERSION,
      textSha256: WITHDRAWAL_SHA256,
    });
    const session = await this.gateway.createCheckoutSession({
      customerId,
      userId,
      offer,
      priceId,
      waiverId,
      successUrl: this.settings.successUrl,
      cancelUrl: this.settings.cancelUrl,
    });
    await this.repository.attachCheckoutSession(waiverId, session.id);
    return { url: session.url };
  }

  private async refuseSecondSubscription(userId: number): Promise<void> {
    const entitlement = await this.repository.entitlementOf(userId);
    if (entitlement?.live === true) throw new AlreadySubscribedError(entitlement.store === "stripe" ? "stripe" : "apple");
  }

  private async customerOf(userId: number): Promise<string> {
    const known = await this.repository.customerIdOf(userId);
    if (known !== undefined) return known;
    const created = await this.gateway.createCustomer({ userId, email: await this.repository.memberEmail(userId) });
    return await this.repository.saveCustomer(userId, created.id);
  }
}

export class PortalService {
  constructor(
    private readonly gateway: StripeGateway,
    private readonly repository: BillingRepository,
    private readonly settings: BillingSettings,
  ) {}

  async open(userId: number): Promise<{ readonly url: string }> {
    const customerId = await this.repository.customerIdOf(userId);
    if (customerId === undefined) throw new NoCustomerError();
    return await this.gateway.createPortalSession({ customerId, returnUrl: this.settings.returnUrl });
  }
}
