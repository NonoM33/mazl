import { InvalidTransactionError } from "../domain/errors";
import { statusForNotificationType } from "../domain/status";
import { toActiveSubscription } from "./activation";
import type { SubscriptionRepository } from "./ports";
import type { TransactionVerifier } from "./transaction-verifier";

export interface NotificationDeps {
  readonly transactions: TransactionVerifier;
  readonly repository: SubscriptionRepository;
}

export type NotificationOutcome =
  | { readonly kind: "handled" }
  | { readonly kind: "ignored"; readonly reason: "unknown_transaction" };

// App Store Server Notifications V2. Throws InvalidTransactionError when the
// outer payload or the transaction it carries cannot be trusted.
export async function handleAppleNotification(deps: NotificationDeps, signedPayload: string): Promise<NotificationOutcome> {
  const notification = deps.transactions.decodeNotification(signedPayload);
  const status = statusForNotificationType(notification.notificationType);
  if (status === undefined) return { kind: "handled" };

  if (notification.signedTransactionInfo === undefined) throw new InvalidTransactionError("invalid_payload");
  const transaction = deps.transactions.forNotification(notification.signedTransactionInfo);

  const owner = await deps.repository.findOwner(transaction.originalTransactionId);
  if (owner === undefined) return { kind: "ignored", reason: "unknown_transaction" };

  if (status === "active") await deps.repository.renew(toActiveSubscription(transaction));
  else await deps.repository.markStatus(transaction.originalTransactionId, status);
  return { kind: "handled" };
}
