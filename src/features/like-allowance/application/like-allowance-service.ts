import type { PlusStatus } from "../../credits/application/ports";
import { buildAllowance, isExhausted, type LikeAllowance } from "../domain/allowance";
import type { LikeLedger } from "./ports";

export type LikeVerdict = { readonly allowed: true } | { readonly allowed: false; readonly allowance: LikeAllowance };

export class LikeAllowanceService {
  constructor(
    private readonly ledger: LikeLedger,
    private readonly plus: PlusStatus,
  ) {}

  async allowance(userId: number): Promise<LikeAllowance> {
    const [isPlus, likesToday, resetsAt] = await Promise.all([
      this.plus.isPlus(userId),
      this.ledger.likesToday(userId),
      this.ledger.resetsAt(),
    ]);
    return buildAllowance({ isPlus, likesToday, resetsAt });
  }

  // A like to someone already liked is free: the app may replay it safely.
  async checkLike(userId: number, targetUserId: number): Promise<LikeVerdict> {
    if (await this.ledger.hasLiked(userId, targetUserId)) return { allowed: true };
    const allowance = await this.allowance(userId);
    return isExhausted(allowance) ? { allowed: false, allowance } : { allowed: true };
  }
}
