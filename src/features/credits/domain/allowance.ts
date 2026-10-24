import type { CreditKind } from "./catalog";

// Included per calendar day (docs/premium/CREDITS.md, "Règles").
const FREE_ALLOWANCE: Readonly<Record<CreditKind, number>> = { super_like: 1, boost: 0 };
const PLUS_ALLOWANCE: Readonly<Record<CreditKind, number>> = { super_like: 5, boost: 1 };

export function dailyAllowance(isPlus: boolean, kind: CreditKind): number {
  return (isPlus ? PLUS_ALLOWANCE : FREE_ALLOWANCE)[kind];
}

export type DebitSource = "daily" | "purchased";

export interface WalletState {
  readonly allowance: number;
  readonly dailyUsed: number;
  // Can be negative: a refunded pack that was already spent.
  readonly purchasedBalance: number;
}

// The allowance of the day first, the purchased credits next, else nothing.
export function chooseDebitSource(wallet: WalletState): DebitSource | undefined {
  if (wallet.dailyUsed < wallet.allowance) return "daily";
  if (wallet.purchasedBalance > 0) return "purchased";
  return undefined;
}
