import { FREE_UNDOS_PER_DAY, UNDO_WINDOW_MINUTES, type UndoOutcome } from "../domain/rules";
import type { PlusLookup, UndoStore } from "./ports";

export class SwipeUndoService {
  constructor(
    private readonly store: UndoStore,
    private readonly plus: PlusLookup,
  ) {}

  async undo(userId: number): Promise<UndoOutcome> {
    const freePerDay = (await this.plus.isPlus(userId)) ? null : FREE_UNDOS_PER_DAY;
    return this.store.undoLast(userId, { freePerDay, windowMinutes: UNDO_WINDOW_MINUTES });
  }
}
