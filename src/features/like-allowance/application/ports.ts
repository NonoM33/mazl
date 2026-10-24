// The day's like ledger, in server calendar days (same day as the credits).
export type Reservation = "reserved" | "already_counted" | "exhausted";

export interface LikeLedger {
  likesToday(userId: number): Promise<number>;
  // A like already given to this target: sending it again costs nothing.
  hasLiked(userId: number, targetUserId: number): Promise<boolean>;
  // Counts the like in the day's ledger unless `limit` is reached, atomically
  // for the member: concurrent likes cannot all see the same count.
  reserve(userId: number, targetUserId: number, limit: number): Promise<Reservation>;
  // Gives the day's like back when the swipe itself was refused.
  release(userId: number, targetUserId: number): Promise<void>;
  resetsAt(): Promise<Date>;
}
