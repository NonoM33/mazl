import type { Sql } from "postgres";
import type { UndoStore } from "../application/ports";
import type { UndoOutcome, UndoneAction } from "../domain/rules";

// Key space of the advisory locks of the undo (one lock per member).
const LOCK_SPACE = 7_270_002;

interface LastSwipe {
  readonly id: number;
  readonly target_user_id: number;
  readonly action: string;
  readonly recent: boolean;
}

export class PgUndoStore implements UndoStore {
  constructor(private readonly sql: Sql) {}

  async undoLast(userId: number, rules: { readonly freePerDay: number | null; readonly windowMinutes: number }): Promise<UndoOutcome> {
    // The postgres types do not see a transaction as callable (same cast as the like ledger).
    return (await this.sql.begin((transaction) => this.undoIn(transaction as unknown as Sql, userId, rules))) as UndoOutcome;
  }

  private async undoIn(tx: Sql, userId: number, rules: { readonly freePerDay: number | null; readonly windowMinutes: number }): Promise<UndoOutcome> {
    await tx`SELECT pg_advisory_xact_lock(${LOCK_SPACE}, ${userId})`;
    const [last] = await tx<LastSwipe[]>`
      SELECT id, target_user_id, action, created_at > NOW() - make_interval(mins => ${rules.windowMinutes}) AS recent
      FROM swipes WHERE user_id = ${userId} ORDER BY created_at DESC, id DESC LIMIT 1
    `;
    if (last === undefined || !last.recent) return { kind: "nothing_to_undo" };
    if (last.action !== "like" && last.action !== "pass") return { kind: "not_possible" };
    if (await this.formedAMatch(tx, userId, last.target_user_id)) return { kind: "not_possible" };

    let remaining: number | null = null;
    if (rules.freePerDay !== null) {
      const used = await this.takeFreeUndo(tx, userId, rules.freePerDay);
      if (used === null) return { kind: "limit_reached" };
      remaining = rules.freePerDay - used;
    }
    await tx`DELETE FROM swipes WHERE id = ${last.id}`;
    return { kind: "undone", targetUserId: last.target_user_id, action: last.action as UndoneAction, remainingFreeUndos: remaining };
  }

  private async formedAMatch(tx: Sql, userId: number, targetUserId: number): Promise<boolean> {
    const rows = await tx`
      SELECT 1 FROM matches
      WHERE (user1_id = ${userId} AND user2_id = ${targetUserId}) OR (user1_id = ${targetUserId} AND user2_id = ${userId})
    `;
    return rows.length > 0;
  }

  // The count after taking one, or null when the day's free undos are all used.
  private async takeFreeUndo(tx: Sql, userId: number, freePerDay: number): Promise<number | null> {
    await tx`DELETE FROM swipe_undo_ledger WHERE user_id = ${userId} AND day < CURRENT_DATE - 1`;
    const [row] = await tx<{ used: number }[]>`
      INSERT INTO swipe_undo_ledger (user_id, day, used) VALUES (${userId}, CURRENT_DATE, 1)
      ON CONFLICT (user_id, day) DO UPDATE SET used = swipe_undo_ledger.used + 1
        WHERE swipe_undo_ledger.used < ${freePerDay}
      RETURNING used
    `;
    return row?.used ?? null;
  }
}
