// Read-only view of the swipes journal, in server calendar days (same day as the credits).
export interface LikeLedger {
  likesToday(userId: number): Promise<number>;
  // A like already given to this target: sending it again costs nothing.
  hasLiked(userId: number, targetUserId: number): Promise<boolean>;
  resetsAt(): Promise<Date>;
}
