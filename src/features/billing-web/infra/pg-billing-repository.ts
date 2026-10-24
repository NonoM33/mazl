import type { Sql } from "postgres";
import type { BillingRepository, EntitlementRow, NewWaiver } from "../application/ports";
import { subscriptionOfferById } from "../domain/offers";
import type { EntitlementProjection, StripeSubscriptionState, StripeSubscriptionStatus } from "../domain/projection";

interface SubscriptionRow {
  readonly subscription_id: string;
  readonly user_id: number;
  readonly customer_id: string;
  readonly price_id: string;
  readonly offer: string;
  readonly status: StripeSubscriptionStatus;
  readonly current_period_end: Date;
  readonly cancel_at_period_end: boolean;
  readonly started_at: Date;
}

// The subscriptions timestamps are TIMESTAMP (no zone) columns holding UTC:
// they are bound as ISO strings, as every writer of this table always did.
const iso = (date: Date): string => date.toISOString();

function toState(row: SubscriptionRow): StripeSubscriptionState | undefined {
  const offer = subscriptionOfferById(row.offer);
  if (offer === undefined) {
    console.error(`stripe_subscriptions ${row.subscription_id}: unknown offer ${row.offer}`);
    return undefined;
  }
  return {
    subscriptionId: row.subscription_id,
    userId: row.user_id,
    customerId: row.customer_id,
    priceId: row.price_id,
    offer,
    status: row.status,
    currentPeriodEnd: row.current_period_end,
    cancelAtPeriodEnd: row.cancel_at_period_end,
    startedAt: row.started_at,
  };
}

export class PgBillingRepository implements BillingRepository {
  constructor(private readonly sql: Sql) {}

  async memberEmail(userId: number): Promise<string | undefined> {
    const rows = await this.sql<{ email: string | null }[]>`SELECT email FROM users WHERE id = ${userId}`;
    return rows[0]?.email ?? undefined;
  }

  async userExists(userId: number): Promise<boolean> {
    return (await this.sql`SELECT 1 FROM users WHERE id = ${userId}`).length > 0;
  }

  async customerIdOf(userId: number): Promise<string | undefined> {
    const rows = await this.sql<{ customer_id: string }[]>`SELECT customer_id FROM stripe_customers WHERE user_id = ${userId}`;
    return rows[0]?.customer_id;
  }

  async saveCustomer(userId: number, customerId: string): Promise<string> {
    await this.sql`
      INSERT INTO stripe_customers (user_id, customer_id) VALUES (${userId}, ${customerId})
      ON CONFLICT (user_id) DO NOTHING
    `;
    const stored = await this.customerIdOf(userId);
    if (stored === undefined) throw new Error("billing: the Stripe customer was not saved");
    return stored;
  }

  async userOfCustomer(customerId: string): Promise<number | undefined> {
    const rows = await this.sql<{ user_id: number }[]>`SELECT user_id FROM stripe_customers WHERE customer_id = ${customerId}`;
    return rows[0]?.user_id;
  }

  async recordWaiver(waiver: NewWaiver): Promise<number> {
    const rows = await this.sql<{ id: number }[]>`
      INSERT INTO billing_withdrawal_waivers (user_id, offer, text_version, text_sha256)
      VALUES (${waiver.userId}, ${waiver.offer}, ${waiver.textVersion}, ${waiver.textSha256})
      RETURNING id
    `;
    const id = rows[0]?.id;
    if (id === undefined) throw new Error("billing: the waiver was not recorded");
    return id;
  }

  async attachCheckoutSession(waiverId: number, sessionId: string): Promise<void> {
    await this.sql`UPDATE billing_withdrawal_waivers SET checkout_session_id = ${sessionId} WHERE id = ${waiverId}`;
  }

  // A row left unprocessed by a failed attempt is taken again on redelivery.
  async beginEvent(eventId: string, type: string): Promise<"new" | "duplicate"> {
    const inserted = await this.sql`
      INSERT INTO stripe_events (event_id, type) VALUES (${eventId}, ${type})
      ON CONFLICT (event_id) DO NOTHING RETURNING event_id
    `;
    if (inserted.length > 0) return "new";
    const rows = await this.sql<{ processed_at: Date | null }[]>`SELECT processed_at FROM stripe_events WHERE event_id = ${eventId}`;
    return rows[0]?.processed_at == null ? "new" : "duplicate";
  }

  async completeEvent(eventId: string): Promise<void> {
    await this.sql`UPDATE stripe_events SET processed_at = NOW() WHERE event_id = ${eventId}`;
  }

  async saveSubscription(state: StripeSubscriptionState): Promise<void> {
    await this.sql`
      INSERT INTO stripe_subscriptions
        (subscription_id, user_id, customer_id, price_id, offer, status, current_period_end, cancel_at_period_end, started_at)
      VALUES
        (${state.subscriptionId}, ${state.userId}, ${state.customerId}, ${state.priceId}, ${state.offer.id}, ${state.status},
         ${iso(state.currentPeriodEnd)}::timestamptz, ${state.cancelAtPeriodEnd}, ${iso(state.startedAt)}::timestamptz)
      ON CONFLICT (subscription_id) DO UPDATE SET
        customer_id = EXCLUDED.customer_id, price_id = EXCLUDED.price_id, offer = EXCLUDED.offer, status = EXCLUDED.status,
        current_period_end = EXCLUDED.current_period_end, cancel_at_period_end = EXCLUDED.cancel_at_period_end,
        updated_at = NOW()
    `;
  }

  async subscriptionsOf(userId: number): Promise<readonly StripeSubscriptionState[]> {
    const rows = await this.sql<SubscriptionRow[]>`
      SELECT subscription_id, user_id, customer_id, price_id, offer, status, current_period_end, cancel_at_period_end, started_at
      FROM stripe_subscriptions WHERE user_id = ${userId} ORDER BY updated_at DESC, subscription_id
    `;
    return rows.map(toState).filter((state): state is StripeSubscriptionState => state !== undefined);
  }

  async ownerOfSubscription(subscriptionId: string): Promise<number | undefined> {
    const rows = await this.sql<{ user_id: number }[]>`SELECT user_id FROM stripe_subscriptions WHERE subscription_id = ${subscriptionId}`;
    return rows[0]?.user_id;
  }

  // The protection is in the WHERE of the upsert, not in a read before it: the
  // live entitlement of the App Store (or of another Stripe subscription, unless
  // the incoming one is active) is never overwritten, even by two racing writers.
  async project(projection: EntitlementProjection): Promise<"written" | "kept"> {
    const written = await this.sql`
      INSERT INTO subscriptions
        (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
      VALUES
        (${projection.userId}, ${projection.planType}, ${projection.status}, 'stripe', ${projection.productId},
         ${projection.originalTransactionId}, ${iso(projection.startedAt)}::timestamp, ${iso(projection.expiresAt)}::timestamp)
      ON CONFLICT (user_id) DO UPDATE SET
        plan_type = EXCLUDED.plan_type,
        status = EXCLUDED.status,
        store = 'stripe',
        product_id = EXCLUDED.product_id,
        original_transaction_id = EXCLUDED.original_transaction_id,
        started_at = EXCLUDED.started_at,
        expires_at = EXCLUDED.expires_at,
        updated_at = NOW()
      WHERE NOT (
        subscriptions.status = 'active'
        AND subscriptions.expires_at > (NOW() AT TIME ZONE 'UTC')
        AND subscriptions.original_transaction_id IS DISTINCT FROM EXCLUDED.original_transaction_id
        AND (subscriptions.store IS DISTINCT FROM 'stripe' OR EXCLUDED.status <> 'active')
      )
      RETURNING id
    `;
    return written.length > 0 ? "written" : "kept";
  }

  async entitlementOf(userId: number): Promise<EntitlementRow | undefined> {
    const rows = await this.sql<
      {
        store: string | null;
        status: string | null;
        plan_type: string | null;
        original_transaction_id: string | null;
        expires_at: Date | null;
        live: boolean;
      }[]
    >`
      SELECT store, status, plan_type, original_transaction_id,
             (expires_at AT TIME ZONE 'UTC') AS expires_at,
             (status = 'active' AND expires_at > (NOW() AT TIME ZONE 'UTC')) AS live
      FROM subscriptions WHERE user_id = ${userId}
    `;
    const row = rows[0];
    if (row === undefined) return undefined;
    return {
      store: row.store,
      status: row.status,
      planType: row.plan_type,
      originalTransactionId: row.original_transaction_id,
      expiresAt: row.expires_at,
      live: row.live === true,
    };
  }
}
