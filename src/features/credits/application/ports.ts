import type { ConsumableRefundOutcome } from "../../subscriptions/application/ports";
import type { SignedTransaction } from "../../subscriptions/domain/transaction";
import type { DebitSource } from "../domain/allowance";
import type { CreditKind } from "../domain/catalog";
import type { CreditsView, PerKind } from "../domain/view";

export interface WalletSnapshot {
  // Debits taken from the allowance of the day, per kind.
  readonly dailyUsed: PerKind;
  // Purchased credits, per kind. Negative after a refunded pack that was spent.
  readonly balances: PerKind;
  readonly resetsAt: Date;
}

export interface SpendRequest {
  readonly userId: number;
  readonly kind: CreditKind;
  readonly allowance: number;
  readonly targetUserId: number | undefined;
}

export type SpendOutcome =
  | { readonly ok: true; readonly spendId: number; readonly source: DebitSource }
  | { readonly ok: false };

export interface NewPurchase {
  readonly transactionId: string;
  readonly productId: string;
  readonly kind: CreditKind;
  readonly quantity: number;
  readonly environment: "Sandbox" | "Production";
  readonly purchasedAt: Date;
}

export type PurchaseOutcome = "credited" | "already_credited" | "owned_by_another_user";

export interface CreditsRepository {
  snapshot(userId: number): Promise<WalletSnapshot>;
  // One transaction that locks the balance row (SELECT ... FOR UPDATE), picks
  // the source with the domain rule and writes the debit.
  spend(request: SpendRequest): Promise<SpendOutcome>;
  // Undoes a debit: the journal line goes, a purchased credit comes back.
  cancelSpend(userId: number, spendId: number): Promise<void>;
  // Idempotent on the transactionId.
  recordPurchase(userId: number, purchase: NewPurchase): Promise<PurchaseOutcome>;
  // Once only per transactionId; the balance may become negative.
  refundPurchase(transactionId: string): Promise<ConsumableRefundOutcome>;
}

// mazl+ is read from the subscriptions table, never from the client.
export interface PlusStatus {
  isPlus(userId: number): Promise<boolean>;
}

// The signature chain and bundle checks of the Apple JWS (TransactionVerifier).
export interface TransactionDecoder {
  verifySigned(signedTransaction: string): SignedTransaction;
}

export type SpendResult =
  | { readonly ok: true; readonly spendId: number; readonly credits: CreditsView }
  | { readonly ok: false; readonly credits: CreditsView };

// What the swipe and boost routes of other features see of the credits.
export interface CreditsGateway {
  credits(userId: number): Promise<CreditsView>;
  spend(userId: number, kind: CreditKind, targetUserId?: number): Promise<SpendResult>;
  cancelSpend(userId: number, spendId: number): Promise<void>;
}
