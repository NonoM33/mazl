import { UnknownPriceError } from "../domain/errors";
import { OFFERS, subscriptionOfferById, type SubscriptionOffer } from "../domain/offers";
import { isLive, projectEntitlement, type StripeSubscriptionState } from "../domain/projection";
import type { BillingRepository, StripeGateway, SubscriptionView } from "./ports";
import type { BillingSettings } from "./settings";

export interface SubscriptionSyncDeps {
  readonly gateway: StripeGateway;
  readonly repository: BillingRepository;
  readonly settings: BillingSettings;
  readonly now?: () => Date;
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
    if (await this.isDuplicate(state)) {
      await this.cancelDuplicate(state);
      return;
    }
    await this.deps.repository.saveSubscription(state);
    await this.cancelLaterDuplicates(state);
    await this.projectState(state);
  }

  // When the older subscription's event comes last, the newer one is already
  // stored: it is the duplicate.
  private async cancelLaterDuplicates(state: StripeSubscriptionState): Promise<void> {
    const now = this.deps.now?.() ?? new Date();
    if (!isLive(state, now)) return;
    for (const other of await this.deps.repository.subscriptionsOf(state.userId)) {
      if (other.subscriptionId !== state.subscriptionId && isLive(other, now) && startsBefore(state, other)) await this.cancelDuplicate(other);
    }
  }

  // A live subscription is a duplicate when it is new while the member already
  // has mazl+ from the App Store, or when another live Stripe subscription
  // started earlier (ties broken by id): the same one is kept whatever the
  // order of the events (security review M2). A Stripe subscription that was
  // there before an App Store purchase is not the duplicate: the conflict is
  // explained to the member, who cancels one of the two (ADR W04).
  private async isDuplicate(state: StripeSubscriptionState): Promise<boolean> {
    const now = this.deps.now?.() ?? new Date();
    if (!isLive(state, now)) return false;
    const entitlement = await this.deps.repository.entitlementOf(state.userId);
    const isNew = (await this.deps.repository.ownerOfSubscription(state.subscriptionId)) === undefined;
    if (isNew && entitlement?.live === true && entitlement.store !== "stripe") return true;
    const others = await this.deps.repository.subscriptionsOf(state.userId);
    return others.some((other) => other.subscriptionId !== state.subscriptionId && isLive(other, now) && startsBefore(other, state));
  }

  private async cancelDuplicate(state: StripeSubscriptionState): Promise<void> {
    await this.deps.gateway.cancelSubscription(state.subscriptionId);
    await this.deps.gateway.refundLatestPayment(state.subscriptionId);
    await this.deps.repository.saveSubscription({ ...state, status: "canceled" });
    console.warn(`Duplicate mazl+ subscription ${state.subscriptionId} of member ${state.userId} cancelled and refunded`);
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

function startsBefore(a: StripeSubscriptionState, b: StripeSubscriptionState): boolean {
  const diff = a.startedAt.getTime() - b.startedAt.getTime();
  return diff < 0 || (diff === 0 && a.subscriptionId < b.subscriptionId);
}
