import type { PlanType } from "../domain/plan";
import { toActiveSubscription } from "./activation";
import type { SubscriptionRepository } from "./ports";
import type { TransactionVerifier } from "./transaction-verifier";

export interface VerifyPurchaseDeps {
  readonly transactions: TransactionVerifier;
  readonly repository: SubscriptionRepository;
}

export interface PurchaseResult {
  readonly planType: PlanType;
  readonly status: "active";
  readonly expiresAt: Date;
  readonly productId: string;
}

// Throws InvalidTransactionError or TransactionOwnedByAnotherUserError.
export async function verifyApplePurchase(
  deps: VerifyPurchaseDeps,
  userId: number,
  signedTransaction: string,
): Promise<PurchaseResult> {
  const subscription = toActiveSubscription(deps.transactions.forPurchase(signedTransaction));
  await deps.repository.activate(userId, subscription);
  return {
    planType: subscription.planType,
    status: "active",
    expiresAt: subscription.expiresAt,
    productId: subscription.productId,
  };
}
