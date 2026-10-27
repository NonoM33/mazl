import type { UndoOutcome } from "../domain/rules";

export interface UndoStore {
  // One transaction: finds the last swipe, checks it can be taken back, takes
  // one of the day's free undos when `freePerDay` is a number (null = unlimited),
  // and deletes it. Nothing changes unless it returns "undone". The member's
  // like of the day stays counted (the like ledger is append-only).
  undoLast(userId: number, rules: { readonly freePerDay: number | null; readonly windowMinutes: number }): Promise<UndoOutcome>;
}

export interface PlusLookup {
  isPlus(userId: number): Promise<boolean>;
}
