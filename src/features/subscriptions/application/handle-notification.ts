import { InvalidTransactionError } from "../domain/errors";
import { statusForNotificationType } from "../domain/status";
import type { SignedTransaction } from "../domain/transaction";
import { toActiveSubscription } from "./activation";
import type { ConsumableRefunds, SubscriptionRepository } from "./ports";
import type { TransactionVerifier } from "./transaction-verifier";

export interface NotificationDeps {
  readonly transactions: TransactionVerifier;
  readonly repository: SubscriptionRepository;
  // Absent when the app sells no consumable.
  readonly consumables?: ConsumableRefunds;
}

export type NotificationOutcome =
  | { readonly kind: "handled" }
  | { readonly kind: "ignored"; readonly reason: "unknown_transaction" };

const IGNORED: NotificationOutcome = { kind: "ignored", reason: "unknown_transaction" };

// Only a refund or a revocation means something for a consumable: it takes the
// credits back. Every other type (CONSUMPTION_REQUEST...) changes nothing.
async function handleConsumable(
  consumables: ConsumableRefunds,
  notificationType: string,
  transaction: SignedTransaction,
): Promise<NotificationOutcome> {
  if (notificationType !== "REFUND" && notificationType !== "REVOKE") return { kind: "handled" };
  if (transaction.transactionId === undefined) throw new InvalidTransactionError("invalid_payload");
  const outcome = await consumables.refund(transaction.transactionId);
  return outcome === "unknown" ? IGNORED : { kind: "handled" };
}

// App Store Server Notifications V2. Throws InvalidTransactionError when the
// outer payload or the transaction it carries cannot be trusted.
export async function handleAppleNotification(deps: NotificationDeps, signedPayload: string): Promise<NotificationOutcome> {
  const notification = deps.transactions.decodeNotification(signedPayload);
  const status = statusForNotificationType(notification.notificationType);
  if (status === undefined) return { kind: "handled" };

  if (notification.signedTransactionInfo === undefined) throw new InvalidTransactionError("invalid_payload");
  const signed = deps.transactions.verifySigned(notification.signedTransactionInfo);
  if (deps.consumables?.sells(signed.productId) === true) {
    return await handleConsumable(deps.consumables, notification.notificationType, signed);
  }

  const transaction = deps.transactions.toSubscription(signed);
  const owner = await deps.repository.findOwner(transaction.originalTransactionId);
  if (owner === undefined) return IGNORED;

  if (status === "active") await deps.repository.renew(toActiveSubscription(transaction));
  else await deps.repository.markStatus(transaction.originalTransactionId, status, transaction.expiresAt);
  return { kind: "handled" };
}
