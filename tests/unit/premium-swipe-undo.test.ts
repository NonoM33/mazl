import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { SwipeUndoService } from "../../src/features/swipe-undo/application/swipe-undo-service";
import type { UndoStore } from "../../src/features/swipe-undo/application/ports";
import { FREE_UNDOS_PER_DAY, UNDO_WINDOW_MINUTES, type UndoOutcome } from "../../src/features/swipe-undo/domain/rules";
import { registerSwipeUndoRoute } from "../../src/features/swipe-undo/presentation/undo.routes";
import type { AppVariables } from "../../src/shared/http/middleware";

// docs/premium/MONETISATION.md section 7: one rewind a day without a
// subscription, as many as wanted with mazl+; the server counts.

function setup(outcome: UndoOutcome, plus: boolean) {
  const asked: Array<{ userId: number; freePerDay: number | null; windowMinutes: number }> = [];
  const store: UndoStore = { undoLast: async (userId, rules) => { asked.push({ userId, ...rules }); return outcome; } };
  const app = new Hono<{ Variables: AppVariables }>();
  registerSwipeUndoRoute(app, {
    authenticate: createMiddleware<{ Variables: AppVariables }>(async (c, next) => { c.set("userId", 7); await next(); }),
    undo: new SwipeUndoService(store, { isPlus: async () => plus }),
  });
  return { asked, post: () => app.request("/api/swipes/undo", { method: "POST" }) };
}

describe("POST /api/swipes/undo", () => {
  test("a free member gets one a day and a ten minutes window", async () => {
    const { asked, post } = setup({ kind: "nothing_to_undo" }, false);
    await post();
    expect(asked).toEqual([{ userId: 7, freePerDay: FREE_UNDOS_PER_DAY, windowMinutes: UNDO_WINDOW_MINUTES }]);
    expect([FREE_UNDOS_PER_DAY, UNDO_WINDOW_MINUTES]).toEqual([1, 10]);
  });

  test("a mazl+ member has no limit", async () => {
    const { asked, post } = setup({ kind: "nothing_to_undo" }, true);
    await post();
    expect(asked[0]?.freePerDay).toBeNull();
  });

  test("200 tells which card comes back and how many free undos are left", async () => {
    const free = setup({ kind: "undone", targetUserId: 41, action: "pass", remainingFreeUndos: 0 }, false);
    const res = await free.post();
    expect([res.status, await res.json()]).toEqual([200, { success: true, data: { target_user_id: 41, action: "pass", remaining_free_undos: 0 } }]);
    const plus = setup({ kind: "undone", targetUserId: 41, action: "like", remainingFreeUndos: null }, true);
    expect(await (await plus.post()).json()).toEqual({ success: true, data: { target_user_id: 41, action: "like", remaining_free_undos: null } });
  });

  test("402 undo_limit_reached, 404 nothing_to_undo, 409 undo_not_possible", async () => {
    const cases: Array<[UndoOutcome, number, string]> = [
      [{ kind: "limit_reached" }, 402, "undo_limit_reached"],
      [{ kind: "nothing_to_undo" }, 404, "nothing_to_undo"],
      [{ kind: "not_possible" }, 409, "undo_not_possible"],
    ];
    for (const [outcome, status, error] of cases) {
      const res = await setup(outcome, false).post();
      expect([res.status, await res.json()]).toEqual([status, { success: false, error }]);
    }
  });

  test("a failing store is a plain 500 internal_error", async () => {
    const app = new Hono<{ Variables: AppVariables }>();
    registerSwipeUndoRoute(app, {
      authenticate: createMiddleware<{ Variables: AppVariables }>(async (c, next) => { c.set("userId", 7); await next(); }),
      undo: new SwipeUndoService({ undoLast: async () => { throw new Error("db down"); } }, { isPlus: async () => false }),
    });
    const original = console.error;
    console.error = () => undefined;
    try {
      const res = await app.request("/api/swipes/undo", { method: "POST" });
      expect([res.status, await res.json()]).toEqual([500, { success: false, error: "internal_error" }]);
    } finally {
      console.error = original;
    }
  });
});
