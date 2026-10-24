// Free plan: 10 likes per calendar day, mazl+: unlimited (CGV 2.1, docs/web/adr/W07).
export const FREE_DAILY_LIKES = 10;

export interface LikeAllowance {
  // null = unlimited.
  readonly daily_allowance: number | null;
  readonly remaining: number | null;
  readonly resets_at: string;
}

export interface AllowanceInput {
  readonly isPlus: boolean;
  readonly likesToday: number;
  readonly resetsAt: Date;
}

export function buildAllowance(input: AllowanceInput): LikeAllowance {
  const resets_at = input.resetsAt.toISOString();
  if (input.isPlus) return { daily_allowance: null, remaining: null, resets_at };
  return {
    daily_allowance: FREE_DAILY_LIKES,
    remaining: Math.max(0, FREE_DAILY_LIKES - input.likesToday),
    resets_at,
  };
}

export function isExhausted(allowance: LikeAllowance): boolean {
  return allowance.remaining !== null && allowance.remaining <= 0;
}
