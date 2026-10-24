import type {
  BillingEvent,
  BillingRepository,
  CheckoutSessionInput,
  EntitlementRow,
  NewWaiver,
  PriceView,
  StripeGateway,
  SubscriptionView,
  WebhookVerifier,
} from "../../../src/features/billing-web/application/ports";
import type { BillingSettings } from "../../../src/features/billing-web/application/settings";
import { InvalidSignatureError, StripeGatewayError } from "../../../src/features/billing-web/domain/errors";
import type { EntitlementProjection, StripeSubscriptionState } from "../../../src/features/billing-web/domain/projection";

export const SETTINGS: BillingSettings = {
  prices: {
    plus_1m: "price_plus_1m",
    plus_3m: "price_plus_3m",
    plus_6m: "price_plus_6m",
    plus_12m: "price_plus_12m",
    boost_1: "price_boost_1",
    boost_3: "price_boost_3",
    superlikes_5: "price_sl_5",
    superlikes_15: "price_sl_15",
  },
  successUrl: "https://mazl.test/app/premium?checkout=success",
  cancelUrl: "https://mazl.test/app/premium?checkout=cancel",
  returnUrl: "https://mazl.test/app/premium",
};

export class FakeGateway implements StripeGateway {
  readonly customers: { userId: number; email: string | undefined }[] = [];
  readonly sessions: CheckoutSessionInput[] = [];
  readonly portals: { customerId: string; returnUrl: string }[] = [];
  readonly cancelled: string[] = [];
  readonly refunded: string[] = [];
  readonly deletedCustomers: string[] = [];
  readonly expiredFor: string[] = [];
  // Checkout sessions as Stripe keeps them: open until paid or expired.
  readonly checkouts: { id: string; customerId: string; mode: "subscription" | "payment"; status: "open" | "expired" }[] = [];
  readonly subscriptions = new Map<string, SubscriptionView>();
  readonly prices = new Map<string, PriceView>();
  priceReads = 0;
  failCancel = false;

  async createCustomer(input: { userId: number; email: string | undefined }): Promise<{ id: string }> {
    this.customers.push(input);
    return { id: `cus_${input.userId}` };
  }

  async createCheckoutSession(input: CheckoutSessionInput): Promise<{ id: string; url: string }> {
    await Promise.resolve();
    this.sessions.push(input);
    const id = `cs_${this.sessions.length}`;
    this.checkouts.push({ id, customerId: input.customerId, mode: input.offer.kind === "subscription" ? "subscription" : "payment", status: "open" });
    return { id, url: `https://checkout.stripe.test/${id}` };
  }

  async expireOpenSubscriptionCheckouts(customerId: string): Promise<void> {
    await Promise.resolve();
    this.expiredFor.push(customerId);
    for (const checkout of this.checkouts) {
      if (checkout.customerId === customerId && checkout.mode === "subscription" && checkout.status === "open") checkout.status = "expired";
    }
  }

  openSubscriptionCheckouts(customerId: string) {
    return this.checkouts.filter((checkout) => checkout.customerId === customerId && checkout.mode === "subscription" && checkout.status === "open");
  }

  async liveSubscriptionsOf(customerId: string): Promise<string[]> {
    return [...this.subscriptions.values()]
      .filter((view) => view.customerId === customerId && !["canceled", "incomplete_expired"].includes(view.status))
      .map((view) => view.id);
  }

  async deleteCustomer(customerId: string): Promise<void> {
    this.deletedCustomers.push(customerId);
  }

  async refundLatestPayment(subscriptionId: string): Promise<void> {
    this.refunded.push(subscriptionId);
  }

  async createPortalSession(input: { customerId: string; returnUrl: string }): Promise<{ url: string }> {
    this.portals.push(input);
    return { url: "https://billing.stripe.test/portal" };
  }

  async retrieveSubscription(subscriptionId: string): Promise<SubscriptionView> {
    const view = this.subscriptions.get(subscriptionId);
    if (view === undefined) throw new StripeGatewayError("subscriptions.retrieve", "resource_missing");
    return view;
  }

  async cancelSubscription(subscriptionId: string): Promise<void> {
    if (this.failCancel) throw new StripeGatewayError("subscriptions.cancel", "api_error");
    this.cancelled.push(subscriptionId);
  }

  async retrievePrice(priceId: string): Promise<PriceView> {
    this.priceReads += 1;
    const price = this.prices.get(priceId);
    if (price === undefined) throw new StripeGatewayError("prices.retrieve", "resource_missing");
    return price;
  }
}

// The signature is "valid" or anything else; the body is the event as JSON.
export class FakeVerifier implements WebhookVerifier {
  async verify(rawBody: string, signature: string | undefined): Promise<BillingEvent> {
    if (signature !== "valid") throw new InvalidSignatureError();
    return JSON.parse(rawBody) as BillingEvent;
  }
}

interface EntitlementLine extends EntitlementRow {
  userId: number;
}

// Same rule as the SQL upsert of PgBillingRepository.project (proved against
// Postgres in tests/billing-web-flow.test.ts).
export class InMemoryBilling implements BillingRepository {
  readonly users = new Set<number>([1, 2]);
  readonly customers = new Map<number, string>();
  readonly waivers: (NewWaiver & { id: number; sessionId?: string })[] = [];
  readonly events = new Map<string, boolean>();
  readonly subscriptions = new Map<string, StripeSubscriptionState>();
  readonly entitlements = new Map<number, EntitlementLine>();
  now = new Date("2026-10-24T12:00:00.000Z");

  async memberEmail(userId: number): Promise<string | undefined> {
    return `member${userId}@example.com`;
  }

  async userExists(userId: number): Promise<boolean> {
    return this.users.has(userId);
  }

  async customerIdOf(userId: number): Promise<string | undefined> {
    return this.customers.get(userId);
  }

  async saveCustomer(userId: number, customerId: string): Promise<string> {
    if (!this.customers.has(userId)) this.customers.set(userId, customerId);
    return this.customers.get(userId) ?? customerId;
  }

  async userOfCustomer(customerId: string): Promise<number | undefined> {
    return [...this.customers].find(([, id]) => id === customerId)?.[0];
  }

  async recordWaiver(waiver: NewWaiver): Promise<number> {
    const id = this.waivers.length + 1;
    this.waivers.push({ ...waiver, id });
    return id;
  }

  async attachCheckoutSession(waiverId: number, sessionId: string): Promise<void> {
    const waiver = this.waivers.find((w) => w.id === waiverId);
    if (waiver !== undefined) waiver.sessionId = sessionId;
  }

  async beginEvent(eventId: string): Promise<"new" | "duplicate"> {
    if (this.events.get(eventId) === true) return "duplicate";
    this.events.set(eventId, false);
    return "new";
  }

  async completeEvent(eventId: string): Promise<void> {
    this.events.set(eventId, true);
  }

  async saveSubscription(state: StripeSubscriptionState): Promise<void> {
    this.subscriptions.set(state.subscriptionId, state);
  }

  async subscriptionsOf(userId: number): Promise<readonly StripeSubscriptionState[]> {
    return [...this.subscriptions.values()].filter((s) => s.userId === userId);
  }

  async ownerOfSubscription(subscriptionId: string): Promise<number | undefined> {
    return this.subscriptions.get(subscriptionId)?.userId;
  }

  setApple(userId: number, expiresAt: Date, status = "active"): void {
    this.entitlements.set(userId, {
      userId,
      store: "apple",
      status,
      planType: "yearly",
      originalTransactionId: "2000000123456789",
      expiresAt,
      live: status === "active" && expiresAt > this.now,
    });
  }

  async project(projection: EntitlementProjection): Promise<"written" | "kept"> {
    const existing = this.entitlements.get(projection.userId);
    const protectedRow =
      existing?.live === true &&
      existing.originalTransactionId !== projection.originalTransactionId &&
      (existing.store !== "stripe" || projection.status !== "active");
    if (protectedRow) return "kept";
    this.entitlements.set(projection.userId, {
      userId: projection.userId,
      store: "stripe",
      status: projection.status,
      planType: projection.planType,
      originalTransactionId: projection.originalTransactionId,
      expiresAt: projection.expiresAt,
      live: projection.status === "active" && projection.expiresAt > this.now,
    });
    return "written";
  }

  async entitlementOf(userId: number): Promise<EntitlementRow | undefined> {
    return this.entitlements.get(userId);
  }
}

export function subscriptionView(overrides: Partial<SubscriptionView> = {}): SubscriptionView {
  return {
    id: "sub_1",
    customerId: "cus_1",
    metadataUserId: 1,
    metadataOffer: "plus_3m",
    priceId: SETTINGS.prices.plus_3m,
    status: "active",
    currentPeriodEnd: new Date("2027-01-24T12:00:00.000Z"),
    cancelAtPeriodEnd: false,
    startedAt: new Date("2026-10-24T12:00:00.000Z"),
    ...overrides,
  };
}
