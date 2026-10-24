import { dailyAllowance } from "./allowance";
import type { CreditKind } from "./catalog";

// The `credits` object returned by every endpoint (snake_case, as the app parses it).
export interface KindCredits {
  readonly daily_allowance: number;
  readonly daily_remaining: number;
  readonly purchased_balance: number;
  readonly available: number;
}

export interface CreditsView {
  readonly super_like: KindCredits;
  readonly boost: KindCredits;
  readonly resets_at: string;
}

export type PerKind = Readonly<Record<CreditKind, number>>;

export interface CreditsInput {
  readonly isPlus: boolean;
  readonly dailyUsed: PerKind;
  readonly balances: PerKind;
  readonly resetsAt: Date;
}

function kindCredits(input: CreditsInput, kind: CreditKind): KindCredits {
  const allowance = dailyAllowance(input.isPlus, kind);
  const remaining = Math.max(0, allowance - input.dailyUsed[kind]);
  const balance = input.balances[kind];
  return { daily_allowance: allowance, daily_remaining: remaining, purchased_balance: balance, available: remaining + Math.max(balance, 0) };
}

export function buildCredits(input: CreditsInput): CreditsView {
  return {
    super_like: kindCredits(input, "super_like"),
    boost: kindCredits(input, "boost"),
    resets_at: input.resetsAt.toISOString(),
  };
}
