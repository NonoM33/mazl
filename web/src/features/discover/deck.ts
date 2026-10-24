import type { ProfileCard, SwipeAction } from "../../shared/api/types";

// The card queue of Découvrir and of the daily picks, as a pure reducer.
// « Passer » is deferred (docs/web/adr/W09): the card leaves at once, the pass
// is only sent PASS_DELAY_MS later, and Z puts the card back before that.

export const PASS_DELAY_MS = 5000;

export interface PendingPass { readonly card: ProfileCard; readonly dueAt: number }

export interface DeckState {
  readonly cards: readonly ProfileCard[];
  readonly pending: readonly PendingPass[];
  // Everyone already decided on in this visit: a new lot never brings them back.
  readonly handled: readonly number[];
  // The last lot brought nothing new: the server has no more to show.
  readonly exhausted: boolean;
}

export type DeckEvent =
  | { readonly type: "loaded"; readonly profiles: readonly ProfileCard[] }
  | { readonly type: "decided"; readonly userId: number; readonly action: SwipeAction; readonly now: number }
  | { readonly type: "restored"; readonly card: ProfileCard }
  | { readonly type: "undo"; readonly userId?: number }
  | { readonly type: "settled"; readonly userIds: readonly number[] }
  | { readonly type: "reset" };

export const EMPTY_DECK: DeckState = { cards: [], pending: [], handled: [], exhausted: false };

function load(state: DeckState, profiles: readonly ProfileCard[]): DeckState {
  const incoming = new Map(profiles.map((profile) => [profile.user_id, profile]));
  const known = new Set(state.cards.map((card) => card.user_id));
  const refreshed = state.cards.map((card) => incoming.get(card.user_id) ?? card);
  const fresh = profiles.filter((profile) => !known.has(profile.user_id) && !state.handled.includes(profile.user_id));
  return { ...state, cards: [...refreshed, ...fresh], exhausted: fresh.length === 0 };
}

function decide(state: DeckState, userId: number, action: SwipeAction, now: number): DeckState {
  const card = state.cards.find((candidate) => candidate.user_id === userId);
  if (!card) return state;
  const pending = action === "pass" ? [...state.pending, { card, dueAt: now + PASS_DELAY_MS }] : state.pending;
  return { ...state, cards: state.cards.filter((candidate) => candidate !== card), pending, handled: [...state.handled, userId] };
}

function restore(state: DeckState, card: ProfileCard): DeckState {
  return {
    ...state,
    cards: [card, ...state.cards.filter((candidate) => candidate.user_id !== card.user_id)],
    pending: state.pending.filter((entry) => entry.card.user_id !== card.user_id),
    handled: state.handled.filter((id) => id !== card.user_id),
  };
}

export function deckReducer(state: DeckState, event: DeckEvent): DeckState {
  switch (event.type) {
    case "loaded": return load(state, event.profiles);
    case "decided": return decide(state, event.userId, event.action, event.now);
    case "restored": return restore(state, event.card);
    case "undo": {
      const target = event.userId === undefined ? state.pending.at(-1) : state.pending.find((entry) => entry.card.user_id === event.userId);
      return target ? restore(state, target.card) : state;
    }
    case "settled": return { ...state, pending: state.pending.filter((entry) => !event.userIds.includes(entry.card.user_id)) };
    case "reset": return { ...state, cards: [], exhausted: false };
  }
}

export function duePasses(pending: readonly PendingPass[], now: number): readonly PendingPass[] {
  return pending.filter((entry) => entry.dueAt <= now);
}

export function nextDueAt(pending: readonly PendingPass[]): number | null {
  return pending.length === 0 ? null : Math.min(...pending.map((entry) => entry.dueAt));
}
