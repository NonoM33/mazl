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

// One checkout at a time per member, so two clicks cannot both find no open
// session and both create one (security review M2). In memory: one process.
class MemberQueue {
  private readonly tails = new Map<number, Promise<unknown>>();

  run<T>(userId: number, task: () => Promise<T>): Promise<T> {
    const previous = this.tails.get(userId) ?? Promise.resolve();
    const result = previous.then(task, task);
    const tail = result.catch(() => undefined);
    this.tails.set(userId, tail);
    void tail.then(() => { if (this.tails.get(userId) === tail) this.tails.delete(userId); });
    return result;
  }
}

export class CheckoutService {
  private readonly queue = new MemberQueue();

  constructor(
    private readonly gateway: StripeGateway,
    private readonly repository: BillingRepository,
    private readonly settings: BillingSettings,
  ) {}

  start(userId: number, request: CheckoutRequest): Promise<{ readonly url: string }> {
    return this.queue.run(userId, () => this.startNow(userId, request));
  }

  private async startNow(userId: number, request: CheckoutRequest): Promise<{ readonly url: string }> {
    const { offer } = request;
    if (request.waiverAccepted !== true || request.waiverVersion !== WITHDRAWAL_VERSION) throw new WithdrawalWaiverRequiredError();
    const priceId = this.settings.prices[offer.id];
    if (priceId === undefined) throw new OfferUnavailableError(offer.id);
    if (offer.kind === "subscription") await this.refuseSecondSubscription(userId);
    const customerId = await this.customerOf(userId);
    // A subscription checkout left open in another tab could still be paid.
    if (offer.kind === "subscription") await this.gateway.expireOpenSubscriptionCheckouts(customerId);
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
