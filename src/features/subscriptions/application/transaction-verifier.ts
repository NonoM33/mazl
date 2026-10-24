import { z } from "zod";
import { InvalidTransactionError } from "../domain/errors";
import type { ProductPolicy, VerifiedTransaction } from "../domain/transaction";
import type { JwsVerifier } from "./ports";

// JWSTransactionDecodedPayload (Apple), the fields this app relies on.
// Dates are milliseconds since the epoch.
const transactionSchema = z.object({
  bundleId: z.string(),
  productId: z.string(),
  originalTransactionId: z.string().min(1).max(64),
  expiresDate: z.number(),
  originalPurchaseDate: z.number().optional(),
  revocationDate: z.number().optional(),
  environment: z.enum(["Sandbox", "Production"]),
});

// ResponseBodyV2DecodedPayload: the signed transaction is absent on some types.
const notificationSchema = z.object({
  notificationType: z.string().min(1),
  data: z.object({ signedTransactionInfo: z.string().optional() }).optional(),
});

export interface AppStoreNotification {
  readonly notificationType: string;
  readonly signedTransactionInfo: string | undefined;
}

function toDate(millis: number): Date {
  const date = new Date(millis);
  if (Number.isNaN(date.getTime())) throw new InvalidTransactionError("invalid_payload");
  return date;
}

export class TransactionVerifier {
  constructor(
    private readonly jws: JwsVerifier,
    private readonly policy: ProductPolicy,
    private readonly clock: () => Date = () => new Date(),
  ) {}

  // A purchase presented by the app: the subscription must be live right now.
  forPurchase(signedTransaction: string): VerifiedTransaction {
    const transaction = this.decode(signedTransaction);
    if (transaction.revokedAt !== undefined) throw new InvalidTransactionError("revoked");
    if (transaction.expiresAt.getTime() <= this.clock().getTime()) throw new InvalidTransactionError("expired");
    return transaction;
  }

  // A transaction carried by a notification: same signature, bundle and product
  // checks, but its expiry or revocation is the news itself, not a defect.
  forNotification(signedTransaction: string): VerifiedTransaction {
    return this.decode(signedTransaction);
  }

  decodeNotification(signedPayload: string): AppStoreNotification {
    const parsed = notificationSchema.safeParse(this.jws.verify(signedPayload));
    if (!parsed.success) throw new InvalidTransactionError("invalid_payload");
    return { notificationType: parsed.data.notificationType, signedTransactionInfo: parsed.data.data?.signedTransactionInfo };
  }

  private decode(signedTransaction: string): VerifiedTransaction {
    const parsed = transactionSchema.safeParse(this.jws.verify(signedTransaction));
    if (!parsed.success) throw new InvalidTransactionError("invalid_payload");
    const payload = parsed.data;
    if (payload.bundleId !== this.policy.bundleId) throw new InvalidTransactionError("wrong_bundle");
    if (!this.policy.productIds.includes(payload.productId)) throw new InvalidTransactionError("product_not_allowed");
    return {
      originalTransactionId: payload.originalTransactionId,
      productId: payload.productId,
      environment: payload.environment,
      originalPurchaseDate: payload.originalPurchaseDate === undefined ? undefined : toDate(payload.originalPurchaseDate),
      expiresAt: toDate(payload.expiresDate),
      revokedAt: payload.revocationDate === undefined ? undefined : toDate(payload.revocationDate),
    };
  }
}
