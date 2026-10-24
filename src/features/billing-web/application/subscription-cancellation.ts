import type { BillingRepository, StripeGateway } from "./ports";

const ENDED = new Set(["canceled", "incomplete_expired"]);

// Account erasure: the web subscriptions must stop billing before the member
// is erased (the App Store subscription is the member's to cancel in iOS
// settings). Every subscription Stripe knows for the customer is cancelled,
// not only those MAZL stored; the customer itself is deleted once the member
// is erased, Stripe keeping the invoices the law requires (security review B2).
export class SubscriptionCancellation {
  constructor(
    private readonly gateway: StripeGateway,
    private readonly repository: BillingRepository,
  ) {}

  // Returns the member's Stripe customer, to delete after the erasure.
  async cancelAll(userId: number): Promise<string | undefined> {
    const customerId = await this.repository.customerIdOf(userId);
    const ids = new Set<string>();
    for (const state of await this.repository.subscriptionsOf(userId)) if (!ENDED.has(state.status)) ids.add(state.subscriptionId);
    if (customerId !== undefined) for (const id of await this.gateway.liveSubscriptionsOf(customerId)) ids.add(id);
    for (const id of ids) await this.gateway.cancelSubscription(id);
    return customerId;
  }

  forgetCustomer(customerId: string): Promise<void> {
    return this.gateway.deleteCustomer(customerId);
  }
}
