import type { ConsumableRefundOutcome, ConsumableRefunds } from "../../subscriptions/application/ports";
import { dailyAllowance } from "../domain/allowance";
import { creditProductFor, type CreditKind } from "../domain/catalog";
import { buildCredits, type CreditsView } from "../domain/view";
import type { CreditsGateway, CreditsRepository, PlusStatus, SpendGuard, SpendResult, TransactionDecoder } from "./ports";
import { verifyConsumablePurchase, type ConsumablePurchaseResult } from "./verify-consumable";

export interface CreditsServiceDeps {
  readonly repository: CreditsRepository;
  readonly plus: PlusStatus;
  readonly transactions: TransactionDecoder;
  readonly clock?: () => Date;
}

// Boosts and super likes held by the server: reading the balance, spending,
// buying consumables and taking refunds back.
export class CreditsService implements CreditsGateway, ConsumableRefunds {
  private readonly clock: () => Date;

  constructor(private readonly deps: CreditsServiceDeps) {
    this.clock = deps.clock ?? (() => new Date());
  }

  async credits(userId: number): Promise<CreditsView> {
    const [snapshot, isPlus] = await Promise.all([this.deps.repository.snapshot(userId), this.deps.plus.isPlus(userId)]);
    return buildCredits({ isPlus, ...snapshot });
  }

  // The allowance of the day goes first, the purchased credits next. When
  // nothing is left the answer carries the balance, so the caller can show it.
  async spend(userId: number, kind: CreditKind, targetUserId?: number, guard?: SpendGuard): Promise<SpendResult> {
    const allowance = dailyAllowance(await this.deps.plus.isPlus(userId), kind);
    const outcome = await this.deps.repository.spend({ userId, kind, allowance, targetUserId, guard });
    const credits = await this.credits(userId);
    return outcome.ok ? { ok: true, spendId: outcome.spendId, credits } : { ok: false, reason: outcome.reason, credits };
  }

  async cancelSpend(userId: number, spendId: number): Promise<void> {
    await this.deps.repository.cancelSpend(userId, spendId);
  }

  async verifyPurchase(userId: number, signedTransaction: string): Promise<ConsumablePurchaseResult> {
    const purchase = await verifyConsumablePurchase(
      { repository: this.deps.repository, transactions: this.deps.transactions, clock: this.clock },
      userId,
      signedTransaction,
    );
    return { ...purchase, credits: await this.credits(userId) };
  }

  sells(productId: string): boolean {
    return creditProductFor(productId) !== undefined;
  }

  refund(transactionId: string): Promise<ConsumableRefundOutcome> {
    return this.deps.repository.refundPurchase(transactionId);
  }
}
