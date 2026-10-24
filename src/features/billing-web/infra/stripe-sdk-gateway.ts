import Stripe from "stripe";
import type { CheckoutSessionInput, PriceView, StripeGateway, SubscriptionView } from "../application/ports";
import { StripeGatewayError } from "../domain/errors";
import { stripeMode } from "../domain/offers";
import type { StripeSubscriptionStatus } from "../domain/projection";

export interface SdkGatewayOptions {
  readonly secretKey: string;
  // Points the SDK at a fake server (tests); undefined means api.stripe.com.
  readonly apiBase?: URL | undefined;
}

export function createStripeClient(options: SdkGatewayOptions): Stripe {
  const { apiBase } = options;
  return new Stripe(options.secretKey, {
    // Bun has no node:http agent semantics the SDK relies on; fetch is the portable client.
    httpClient: Stripe.createFetchHttpClient(),
    maxNetworkRetries: apiBase === undefined ? 2 : 0,
    timeout: 15_000,
    ...(apiBase === undefined
      ? {}
      : {
          host: apiBase.hostname,
          port: apiBase.port === "" ? (apiBase.protocol === "https:" ? 443 : 80) : Number(apiBase.port),
          protocol: apiBase.protocol === "https:" ? ("https" as const) : ("http" as const),
        }),
  });
}

const unix = (seconds: number): Date => new Date(seconds * 1000);

function userIdOf(metadata: Stripe.Metadata | null): number | undefined {
  const raw = metadata?.user_id;
  const id = raw === undefined ? NaN : Number(raw);
  return Number.isSafeInteger(id) && id > 0 ? id : undefined;
}

function periodEnd(subscription: Stripe.Subscription): Date | undefined {
  const ends = subscription.items.data.map((item) => item.current_period_end);
  return ends.length === 0 ? undefined : unix(Math.max(...ends));
}

function customerIdOf(customer: string | Stripe.Customer | Stripe.DeletedCustomer): string {
  return typeof customer === "string" ? customer : customer.id;
}

function toSubscriptionView(subscription: Stripe.Subscription): SubscriptionView {
  return {
    id: subscription.id,
    customerId: customerIdOf(subscription.customer),
    metadataUserId: userIdOf(subscription.metadata),
    metadataOffer: subscription.metadata.offer,
    priceId: subscription.items.data[0]?.price.id,
    status: subscription.status as StripeSubscriptionStatus,
    currentPeriodEnd: periodEnd(subscription),
    cancelAtPeriodEnd: subscription.cancel_at_period_end,
    startedAt: unix(subscription.start_date),
  };
}

async function call<T>(operation: string, request: () => Promise<T>): Promise<T> {
  try {
    return await request();
  } catch (error: unknown) {
    if (error instanceof Stripe.errors.StripeError) throw new StripeGatewayError(operation, error.code);
    throw error;
  }
}

export class SdkStripeGateway implements StripeGateway {
  constructor(private readonly stripe: Stripe) {}

  async createCustomer(input: { readonly userId: number; readonly email: string | undefined }): Promise<{ readonly id: string }> {
    const params: Stripe.CustomerCreateParams = { metadata: { user_id: String(input.userId) } };
    if (input.email !== undefined) params.email = input.email;
    // One customer per member even if two checkouts race (Stripe keeps the key 24 h).
    const customer = await call("customers.create", () =>
      this.stripe.customers.create(params, { idempotencyKey: `mazl-customer-${input.userId}` }),
    );
    return { id: customer.id };
  }

  async createCheckoutSession(input: CheckoutSessionInput): Promise<{ readonly id: string; readonly url: string }> {
    const metadata = { user_id: String(input.userId), offer: input.offer.id, waiver_id: String(input.waiverId) };
    const base: Stripe.Checkout.SessionCreateParams = {
      mode: stripeMode(input.offer),
      customer: input.customerId,
      client_reference_id: String(input.userId),
      metadata,
      line_items: [{ price: input.priceId, quantity: 1 }],
      success_url: input.successUrl,
      cancel_url: input.cancelUrl,
      locale: "fr",
    };
    const params: Stripe.Checkout.SessionCreateParams =
      input.offer.kind === "subscription"
        ? { ...base, subscription_data: { metadata } }
        : { ...base, invoice_creation: { enabled: true }, payment_intent_data: { metadata } };
    const session = await call("checkout.sessions.create", () => this.stripe.checkout.sessions.create(params));
    if (session.url === null) throw new StripeGatewayError("checkout.sessions.create", "no_url");
    return { id: session.id, url: session.url };
  }

  async createPortalSession(input: { readonly customerId: string; readonly returnUrl: string }): Promise<{ readonly url: string }> {
    const session = await call("billingPortal.sessions.create", () =>
      this.stripe.billingPortal.sessions.create({ customer: input.customerId, return_url: input.returnUrl }),
    );
    return { url: session.url };
  }

  async retrieveSubscription(subscriptionId: string): Promise<SubscriptionView> {
    return toSubscriptionView(await call("subscriptions.retrieve", () => this.stripe.subscriptions.retrieve(subscriptionId)));
  }

  async cancelSubscription(subscriptionId: string): Promise<void> {
    try {
      await call("subscriptions.cancel", () => this.stripe.subscriptions.cancel(subscriptionId));
    } catch (error: unknown) {
      if (error instanceof StripeGatewayError && error.code === "resource_missing") return;
      throw error;
    }
  }

  async retrievePrice(priceId: string): Promise<PriceView> {
    const price = await call("prices.retrieve", () => this.stripe.prices.retrieve(priceId));
    return { id: price.id, unitAmount: price.unit_amount, currency: price.currency, taxBehavior: price.tax_behavior ?? null };
  }
}
