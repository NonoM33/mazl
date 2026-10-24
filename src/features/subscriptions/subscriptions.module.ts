import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import type { AppVariables } from "../../shared/http/middleware";
import type { ConsumableRefunds } from "./application/ports";
import { TransactionVerifier } from "./application/transaction-verifier";
import { AppleJwsVerifier } from "./infra/apple-jws-verifier";
import { APPLE_ROOT_CA_G3_DER } from "./infra/apple-root-ca";
import { readProductPolicy } from "./infra/config";
import { PgSubscriptionRepository } from "./infra/pg-subscription-repository";
import { registerSubscriptionsRoutes } from "./presentation/subscriptions.routes";

export interface SubscriptionsModuleOptions {
  readonly sql: Sql;
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly env?: Record<string, string | undefined>;
  // Shared with the credits feature, which decodes consumables the same way.
  readonly transactions?: TransactionVerifier;
  readonly consumables?: ConsumableRefunds;
}

// The one Apple JWS verifier of the app, anchored on Apple Root CA - G3.
export function createTransactionVerifier(env: Record<string, string | undefined> = process.env): TransactionVerifier {
  return new TransactionVerifier(new AppleJwsVerifier(APPLE_ROOT_CA_G3_DER), readProductPolicy(env));
}

// Native Apple purchase verification (StoreKit 2 + Server Notifications V2),
// anchored on Apple Root CA - G3.
export function registerSubscriptions(app: Hono<{ Variables: AppVariables }>, options: SubscriptionsModuleOptions): void {
  registerSubscriptionsRoutes(app, {
    authenticate: options.authenticate,
    transactions: options.transactions ?? createTransactionVerifier(options.env ?? process.env),
    repository: new PgSubscriptionRepository(options.sql),
    ...(options.consumables === undefined ? {} : { consumables: options.consumables }),
  });
}
