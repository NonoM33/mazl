import type { PlusStatus } from "../../credits/application/ports";
import { buildAllowance, FREE_DAILY_LIKES, type LikeAllowance } from "../domain/allowance";
import type { LikeLedger } from "./ports";

export type LikeVerdict =
  | { readonly allowed: true; readonly reserved: boolean }
  | { readonly allowed: false; readonly allowance: LikeAllowance };

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

  // Takes one of the day's likes, or refuses. A like to someone already liked
  // is free: the app may replay it safely. `reserved` tells the caller to give
  // the like back if the swipe itself fails.
  async checkLike(userId: number, targetUserId: number): Promise<LikeVerdict> {
    if (await this.plus.isPlus(userId)) return { allowed: true, reserved: false };
    if (await this.ledger.hasLiked(userId, targetUserId)) return { allowed: true, reserved: false };
    const outcome = await this.ledger.reserve(userId, targetUserId, FREE_DAILY_LIKES);
    if (outcome === "exhausted") return { allowed: false, allowance: await this.allowance(userId) };
    return { allowed: true, reserved: outcome === "reserved" };
  }

  release(userId: number, targetUserId: number): Promise<void> {
    return this.ledger.release(userId, targetUserId);
  }
}
