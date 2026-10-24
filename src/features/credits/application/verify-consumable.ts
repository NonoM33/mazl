import { InvalidTransactionError, TransactionOwnedByAnotherUserError } from "../../subscriptions/domain/errors";
import type { CreditKind } from "../domain/catalog";
import { creditProductFor } from "../domain/catalog";
import type { CreditsView } from "../domain/view";
import type { CreditsRepository, TransactionDecoder } from "./ports";

export interface VerifyConsumableDeps {
  readonly repository: CreditsRepository;
  readonly transactions: TransactionDecoder;
  readonly clock: () => Date;
}

export interface ConsumablePurchaseResult {
  // False when this transaction had already been credited to the same member.
  readonly credited: boolean;
  readonly kind: CreditKind;
  readonly quantity: number;
  readonly credits: CreditsView;
}

export type VerifiedPurchase = Omit<ConsumablePurchaseResult, "credits">;

// The consumable policy: a product of the catalogue, a transaction typed
// "Consumable", not revoked (neither in the JWS nor by an earlier refund
// notification that the repository remembers), identified by its transactionId (the key of the
// purchase; the originalTransactionId of a consumable is no stable key).
// Throws InvalidTransactionError or TransactionOwnedByAnotherUserError.
export async function verifyConsumablePurchase(
  deps: VerifyConsumableDeps,
  userId: number,
  signedTransaction: string,
): Promise<VerifiedPurchase> {
  const signed = deps.transactions.verifySigned(signedTransaction);
  const product = creditProductFor(signed.productId);
  if (product === undefined) throw new InvalidTransactionError("product_not_allowed");
  if (signed.type !== "Consumable") throw new InvalidTransactionError("not_consumable");
  if (signed.revokedAt !== undefined) throw new InvalidTransactionError("revoked");
  if (signed.transactionId === undefined) throw new InvalidTransactionError("invalid_payload");

  const outcome = await deps.repository.recordPurchase(userId, {
    transactionId: signed.transactionId,
    productId: product.productId,
    kind: product.kind,
    quantity: product.quantity,
    environment: signed.environment,
    purchasedAt: signed.purchaseDate ?? signed.originalPurchaseDate ?? deps.clock(),
  });
  if (outcome === "owned_by_another_user") throw new TransactionOwnedByAnotherUserError();
  if (outcome === "revoked") throw new InvalidTransactionError("revoked");
  return { credited: outcome === "credited", kind: product.kind, quantity: product.quantity };
}
