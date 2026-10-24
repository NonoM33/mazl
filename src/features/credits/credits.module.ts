import type { Hono, MiddlewareHandler } from "hono";
import type { Sql } from "postgres";
import type { AppVariables } from "../../shared/http/middleware";
import type { TransactionVerifier } from "../subscriptions/application/transaction-verifier";
import { CreditsService } from "./application/credits-service";
import { PgCreditsRepository } from "./infra/pg-credits-repository";
import { PgPlusStatus } from "./infra/pg-plus-status";
import { registerCreditsRoutes } from "./presentation/credits.routes";

export interface CreditsModuleOptions {
  readonly sql: Sql;
  // The Apple JWS verifier shared with the subscriptions feature.
  readonly transactions: TransactionVerifier;
}

// Boost and super like credits held by the server: allowances, purchased
// consumables, debits and refunds (docs/premium/CREDITS.md).
export function createCreditsService(options: CreditsModuleOptions): CreditsService {
  return new CreditsService({
    repository: new PgCreditsRepository(options.sql),
    plus: new PgPlusStatus(options.sql),
    transactions: options.transactions,
  });
}

export function registerCredits(
  app: Hono<{ Variables: AppVariables }>,
  credits: CreditsService,
  authenticate: MiddlewareHandler<{ Variables: AppVariables }>,
): void {
  registerCreditsRoutes(app, { authenticate, credits });
}
