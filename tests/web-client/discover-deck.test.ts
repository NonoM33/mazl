import { describe, expect, test } from "bun:test";
import { deckReducer, duePasses, EMPTY_DECK, nextDueAt, PASS_DELAY_MS, type DeckEvent, type DeckState } from "../../web/src/features/discover/deck";
import { card } from "./discover-fixtures";

const run = (events: readonly DeckEvent[], from: DeckState = EMPTY_DECK): DeckState => events.reduce(deckReducer, from);
const ids = (state: DeckState): number[] => state.cards.map((item) => item.user_id);
const lot = (...numbers: number[]) => ({ type: "loaded", profiles: numbers.map((n) => card(n)) }) as const;

describe("deck queue", () => {
  test("a lot fills the queue and a second lot only appends new profiles", () => {
    const state = run([lot(1, 2, 3), lot(2, 3, 4)]);
    expect(ids(state)).toEqual([1, 2, 3, 4]);
    expect(state.exhausted).toBe(false);
  });

  test("a lot with nothing new marks the queue exhausted", () => {
    expect(run([lot(1, 2), lot(1, 2)]).exhausted).toBe(true);
    expect(run([lot()]).exhausted).toBe(true);
  });

  test("a like removes the card and nobody decided on comes back in a later lot", () => {
    const state = run([lot(1, 2), { type: "decided", userId: 1, action: "like", now: 0 }, lot(1, 2, 3)]);
    expect(ids(state)).toEqual([2, 3]);
    expect(state.pending).toEqual([]);
  });

  test("a pass is deferred by five seconds", () => {
    const state = run([lot(1, 2), { type: "decided", userId: 1, action: "pass", now: 1000 }]);
    expect(ids(state)).toEqual([2]);
    expect(state.pending.map((entry) => entry.dueAt)).toEqual([1000 + PASS_DELAY_MS]);
    expect(PASS_DELAY_MS).toBe(5000);
  });

  test("undo puts the last passed card back in front and cancels its pass", () => {
    const state = run([lot(1, 2, 3), { type: "decided", userId: 1, action: "pass", now: 0 }, { type: "decided", userId: 2, action: "pass", now: 10 }, { type: "undo" }]);
    expect(ids(state)).toEqual([2, 3]);
    expect(state.pending.map((entry) => entry.card.user_id)).toEqual([1]);
    expect(state.handled).toEqual([1]);
  });

  test("undo with nothing pending changes nothing", () => {
    const state = run([lot(1)]);
    expect(deckReducer(state, { type: "undo" })).toBe(state);
  });

  test("passes are purged once expired and sent exactly when due", () => {
    const state = run([lot(1, 2), { type: "decided", userId: 1, action: "pass", now: 0 }, { type: "decided", userId: 2, action: "pass", now: 3000 }]);
    expect(duePasses(state.pending, 4999)).toEqual([]);
    expect(duePasses(state.pending, 5000).map((entry) => entry.card.user_id)).toEqual([1]);
    expect(nextDueAt(state.pending)).toBe(5000);
    const settled = deckReducer(state, { type: "settled", userIds: [1] });
    expect(settled.pending.map((entry) => entry.card.user_id)).toEqual([2]);
    expect(deckReducer(settled, { type: "undo" }).cards.map((item) => item.user_id)).toEqual([2]);
    expect(nextDueAt([])).toBeNull();
  });

  test("a failed like restores the card in front", () => {
    const first = card(1);
    const state = run([lot(1, 2), { type: "decided", userId: 1, action: "like", now: 0 }, { type: "restored", card: first }]);
    expect(ids(state)).toEqual([1, 2]);
    expect(state.handled).toEqual([]);
  });

  test("a refreshed lot replaces the photos of cards already queued", () => {
    const state = run([lot(1), { type: "loaded", profiles: [card(1, { photos: ["fresh.jpg"] })] }]);
    expect(state.cards[0]?.photos).toEqual(["fresh.jpg"]);
  });

  test("reset empties the queue but keeps the pending passes and the handled list", () => {
    const state = run([lot(1, 2), { type: "decided", userId: 1, action: "pass", now: 0 }, { type: "reset" }, lot(1, 2, 3)]);
    expect(ids(state)).toEqual([2, 3]);
    expect(state.pending).toHaveLength(1);
  });

  test("deciding on a card that is not in the queue is ignored", () => {
    const state = run([lot(1)]);
    expect(deckReducer(state, { type: "decided", userId: 9, action: "like", now: 0 })).toBe(state);
  });
});
