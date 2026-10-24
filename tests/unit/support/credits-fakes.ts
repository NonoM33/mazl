import type { ConsumableRefundOutcome } from "../../../src/features/subscriptions/application/ports";
import type {
  CreditsRepository,
  NewPurchase,
  PlusStatus,
  PurchaseOutcome,
  SpendOutcome,
  SpendRequest,
  WalletSnapshot,
} from "../../../src/features/credits/application/ports";
import { chooseDebitSource, type DebitSource } from "../../../src/features/credits/domain/allowance";
import type { CreditKind } from "../../../src/features/credits/domain/catalog";

interface SpendLine {
  readonly id: number;
  readonly userId: number;
  readonly kind: CreditKind;
  readonly source: DebitSource;
  readonly targetUserId: number | undefined;
  today: boolean;
  // Minutes since the debit; `age` moves time forward.
  minutesAgo: number;
}

interface PurchaseLine {
  readonly userId: number;
  readonly kind: CreditKind;
  readonly quantity: number;
  refunded: boolean;
}

// In-memory stand-in with the same observable rules as the Postgres repository.
export class InMemoryCredits implements CreditsRepository {
  readonly spends: SpendLine[] = [];
  readonly purchases = new Map<string, PurchaseLine>();
  // Transactions Apple refunded before they were ever credited.
  readonly revoked = new Set<string>();
  readonly resetsAt = new Date("2026-10-25T00:00:00.000Z");
  private readonly balances = new Map<string, number>();
  private nextId = 1;

  balance(userId: number, kind: CreditKind): number {
    return this.balances.get(`${userId}:${kind}`) ?? 0;
  }

  setBalance(userId: number, kind: CreditKind, value: number): void {
    this.balances.set(`${userId}:${kind}`, value);
  }

  // Time passes for the debit journal (the boost guard looks at running time).
  age(minutes: number): void {
    for (const line of this.spends) line.minutesAgo += minutes;
  }

  private alreadyPaid(request: SpendRequest): boolean {
    const guard = request.guard;
    if (guard === undefined) return false;
    return this.spends.some(
      (s) =>
        s.userId === request.userId &&
        s.kind === request.kind &&
        (guard.kind === "once_per_target" ? s.targetUserId === request.targetUserId : s.minutesAgo < guard.minutes),
    );
  }

  // Midnight passes: yesterday's debits no longer count against the allowance.
  nextDay(): void {
    for (const line of this.spends) line.today = false;
  }

  private dailyUsed(userId: number, kind: CreditKind): number {
    return this.spends.filter((s) => s.userId === userId && s.kind === kind && s.source === "daily" && s.today).length;
  }

  async snapshot(userId: number): Promise<WalletSnapshot> {
    return {
      dailyUsed: { super_like: this.dailyUsed(userId, "super_like"), boost: this.dailyUsed(userId, "boost") },
      balances: { super_like: this.balance(userId, "super_like"), boost: this.balance(userId, "boost") },
      resetsAt: this.resetsAt,
    };
  }

  async spend(request: SpendRequest): Promise<SpendOutcome> {
    if (this.alreadyPaid(request)) return { ok: false, reason: "already_spent" };
    const source = chooseDebitSource({
      allowance: request.allowance,
      dailyUsed: this.dailyUsed(request.userId, request.kind),
      purchasedBalance: this.balance(request.userId, request.kind),
    });
    if (source === undefined) return { ok: false, reason: "exhausted" };
    const id = this.nextId++;
    this.spends.push({ id, userId: request.userId, kind: request.kind, source, targetUserId: request.targetUserId, today: true, minutesAgo: 0 });
    if (source === "purchased") this.setBalance(request.userId, request.kind, this.balance(request.userId, request.kind) - 1);
    return { ok: true, spendId: id, source };
  }

  async cancelSpend(userId: number, spendId: number): Promise<void> {
    const index = this.spends.findIndex((s) => s.id === spendId && s.userId === userId);
    const line = this.spends[index];
    if (line === undefined) return;
    this.spends.splice(index, 1);
    if (line.source === "purchased") this.setBalance(userId, line.kind, this.balance(userId, line.kind) + 1);
  }

  async recordPurchase(userId: number, purchase: NewPurchase): Promise<PurchaseOutcome> {
    if (this.revoked.has(purchase.transactionId)) return "revoked";
    const known = this.purchases.get(purchase.transactionId);
    if (known !== undefined) return known.userId === userId ? "already_credited" : "owned_by_another_user";
    this.purchases.set(purchase.transactionId, { userId, kind: purchase.kind, quantity: purchase.quantity, refunded: false });
    this.setBalance(userId, purchase.kind, this.balance(userId, purchase.kind) + purchase.quantity);
    return "credited";
  }

  async refundPurchase(transactionId: string): Promise<ConsumableRefundOutcome> {
    const line = this.purchases.get(transactionId);
    if (line === undefined) {
      this.revoked.add(transactionId);
      return "unknown";
    }
    if (line.refunded) return "already_refunded";
    line.refunded = true;
    this.setBalance(line.userId, line.kind, this.balance(line.userId, line.kind) - line.quantity);
    return "refunded";
  }
}

export class FakePlusStatus implements PlusStatus {
  readonly plus = new Set<number>();
  async isPlus(userId: number): Promise<boolean> {
    return this.plus.has(userId);
  }
}
