import { z } from "zod";
import { InvalidTransactionError } from "../domain/errors";
import type { ProductPolicy, SignedTransaction, VerifiedTransaction } from "../domain/transaction";
import type { JwsVerifier } from "./ports";

// JWSTransactionDecodedPayload (Apple), the fields this app relies on.
// Dates are milliseconds since the epoch. expiresDate is absent on a consumable.
const transactionSchema = z.object({
  bundleId: z.string(),
  productId: z.string(),
  originalTransactionId: z.string().min(1).max(64),
  transactionId: z.string().min(1).max(64).optional(),
  type: z.string().optional(),
  expiresDate: z.number().optional(),
  originalPurchaseDate: z.number().optional(),
  purchaseDate: z.number().optional(),
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

function optionalDate(millis: number | undefined): Date | undefined {
  return millis === undefined ? undefined : toDate(millis);
}

export class TransactionVerifier {
  constructor(
    private readonly jws: JwsVerifier,
    private readonly policy: ProductPolicy,
    private readonly clock: () => Date = () => new Date(),
  ) {}

  // A purchase presented by the app: the subscription must be live right now.
  forPurchase(signedTransaction: string): VerifiedTransaction {
    const transaction = this.toSubscription(this.verifySigned(signedTransaction));
    if (transaction.revokedAt !== undefined) throw new InvalidTransactionError("revoked");
    if (transaction.expiresAt.getTime() <= this.clock().getTime()) throw new InvalidTransactionError("expired");
    return transaction;
  }

  // A transaction carried by a notification: same signature, bundle and product
  // checks, but its expiry or revocation is the news itself, not a defect.
  forNotification(signedTransaction: string): VerifiedTransaction {
    return this.toSubscription(this.verifySigned(signedTransaction));
  }

  decodeNotification(signedPayload: string): AppStoreNotification {
    const parsed = notificationSchema.safeParse(this.jws.verify(signedPayload));
    if (!parsed.success) throw new InvalidTransactionError("invalid_payload");
    return { notificationType: parsed.data.notificationType, signedTransactionInfo: parsed.data.data?.signedTransactionInfo };
  }

  // Signature chain and bundle only: no product policy, no expiry. Both the
  // subscription policy (toSubscription) and the consumable policy (credits)
  // start from this.
  verifySigned(signedTransaction: string): SignedTransaction {
    const parsed = transactionSchema.safeParse(this.jws.verify(signedTransaction));
    if (!parsed.success) throw new InvalidTransactionError("invalid_payload");
    const payload = parsed.data;
    if (payload.bundleId !== this.policy.bundleId) throw new InvalidTransactionError("wrong_bundle");
    return {
      originalTransactionId: payload.originalTransactionId,
      transactionId: payload.transactionId,
      productId: payload.productId,
      type: payload.type,
      environment: payload.environment,
      originalPurchaseDate: optionalDate(payload.originalPurchaseDate),
      purchaseDate: optionalDate(payload.purchaseDate),
      expiresAt: optionalDate(payload.expiresDate),
      revokedAt: optionalDate(payload.revocationDate),
    };
  }

  // The subscription policy: a listed product that carries an expiry date.
  toSubscription(signed: SignedTransaction): VerifiedTransaction {
    if (!this.policy.productIds.includes(signed.productId)) throw new InvalidTransactionError("product_not_allowed");
    if (signed.expiresAt === undefined) throw new InvalidTransactionError("invalid_payload");
    return {
      originalTransactionId: signed.originalTransactionId,
      productId: signed.productId,
      environment: signed.environment,
      originalPurchaseDate: signed.originalPurchaseDate,
      expiresAt: signed.expiresAt,
      revokedAt: signed.revokedAt,
    };
  }
}
