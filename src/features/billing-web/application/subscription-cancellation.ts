import type { BillingRepository, StripeGateway } from "./ports";

const ENDED = new Set(["canceled", "incomplete_expired"]);

// Account erasure: the web subscription must stop billing before the member is
// erased (the App Store subscription is the member's to cancel in iOS settings).
export class SubscriptionCancellation {
  constructor(
    private readonly gateway: StripeGateway,
    private readonly repository: BillingRepository,
  ) {}

  async cancelAll(userId: number): Promise<void> {
    for (const state of await this.repository.subscriptionsOf(userId)) {
      if (!ENDED.has(state.status)) await this.gateway.cancelSubscription(state.subscriptionId);
    }
  }
}
