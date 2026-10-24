import { UnknownPriceError } from "../domain/errors";
import { OFFERS, subscriptionOfferById, type SubscriptionOffer } from "../domain/offers";
import { projectEntitlement, type StripeSubscriptionState } from "../domain/projection";
import type { BillingRepository, StripeGateway, SubscriptionView } from "./ports";
import type { BillingSettings } from "./settings";

export interface SubscriptionSyncDeps {
  readonly gateway: StripeGateway;
  readonly repository: BillingRepository;
  readonly settings: BillingSettings;
}

// Keeps `stripe_subscriptions` (the full Stripe state) and the `subscriptions`
// row (the mazl+ entitlement) in line with what Stripe reports. The state is
// always read back from Stripe, so the order in which events arrive is moot.
export class SubscriptionSync {
  constructor(private readonly deps: SubscriptionSyncDeps) {}

  async syncFromStripe(subscriptionId: string): Promise<void> {
    const view = await this.deps.gateway.retrieveSubscription(subscriptionId);
    const userId = await this.ownerOf(view);
    if (userId === undefined) {
      console.warn(`Stripe subscription ${view.id} belongs to no existing member: ignored`);
      return;
    }
    const state = this.stateOf(view, userId);
    await this.deps.repository.saveSubscription(state);
    await this.projectState(state);
  }

  // Re-applies the stored Stripe state of a member, for the case where the
  // entitlement row went to another source and that source has since expired.
  async reprojectStored(userId: number): Promise<void> {
    for (const state of await this.deps.repository.subscriptionsOf(userId)) await this.projectState(state);
  }

  private async projectState(state: StripeSubscriptionState): Promise<void> {
    const projection = projectEntitlement(state);
    if (projection !== undefined) await this.deps.repository.project(projection);
  }

  // The customer mapping wins over the metadata: it is what MAZL stored itself.
  private async ownerOf(view: SubscriptionView): Promise<number | undefined> {
    const { repository } = this.deps;
    const candidate = (await repository.userOfCustomer(view.customerId)) ?? view.metadataUserId;
    if (candidate === undefined) return undefined;
    return (await repository.userExists(candidate)) ? candidate : undefined;
  }

  private stateOf(view: SubscriptionView, userId: number): StripeSubscriptionState {
    const offer = this.offerOf(view);
    if (view.priceId === undefined || view.currentPeriodEnd === undefined) throw new UnknownPriceError(view.priceId);
    return {
      subscriptionId: view.id,
      userId,
      customerId: view.customerId,
      priceId: view.priceId,
      offer,
      status: view.status,
      currentPeriodEnd: view.currentPeriodEnd,
      cancelAtPeriodEnd: view.cancelAtPeriodEnd,
      startedAt: view.startedAt,
    };
  }

  // The configured price decides; the metadata written at checkout is the fallback.
  private offerOf(view: SubscriptionView): SubscriptionOffer {
    const byPrice = OFFERS.find((offer) => offer.kind === "subscription" && this.deps.settings.prices[offer.id] === view.priceId);
    const offer = byPrice?.kind === "subscription" ? byPrice : subscriptionOfferById(view.metadataOffer ?? "");
    if (offer === undefined) throw new UnknownPriceError(view.priceId);
    return offer;
  }
}
