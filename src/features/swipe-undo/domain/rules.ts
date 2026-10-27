// The rewind (docs/premium/MONETISATION.md section 7): bring back the LAST card
// the member passed or liked. One a day without a subscription, as many as
// wanted with mazl+. The server counts; the app only asks.

export const FREE_UNDOS_PER_DAY = 1;
// Only a recent choice is taken back: it is a slip of the thumb, not a way to
// reopen the history of the member's decisions.
export const UNDO_WINDOW_MINUTES = 10;

export type UndoneAction = "like" | "pass";

export type UndoOutcome =
  | { readonly kind: "undone"; readonly targetUserId: number; readonly action: UndoneAction; readonly remainingFreeUndos: number | null }
  // The free one of the day is used (402 undo_limit_reached).
  | { readonly kind: "limit_reached" }
  // No swipe, or none recent enough (404 nothing_to_undo).
  | { readonly kind: "nothing_to_undo" }
  // A Super Like was paid for, a match already formed (409 undo_not_possible).
  | { readonly kind: "not_possible" };
