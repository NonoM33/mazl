import { planTypeForProduct } from "../domain/plan";
import type { VerifiedTransaction } from "../domain/transaction";
import type { ActiveSubscription } from "./ports";

export function toActiveSubscription(transaction: VerifiedTransaction): ActiveSubscription {
  return {
    originalTransactionId: transaction.originalTransactionId,
    productId: transaction.productId,
    planType: planTypeForProduct(transaction.productId),
    startedAt: transaction.originalPurchaseDate,
    expiresAt: transaction.expiresAt,
  };
}
