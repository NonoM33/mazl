import { useCallback, useEffect, useMemo, useReducer, useRef, useState, type ReactNode } from "react";
import { describeError } from "../../shared/api/errors";
import type { ProfileCard, SwipeAction } from "../../shared/api/types";
import { SIGNED_URL_REFRESH_MS } from "../../shared/hooks/use-resource";
import { useToast } from "../../shared/ui/toast";
import { deckReducer, EMPTY_DECK, PASS_DELAY_MS } from "./deck";
import type { SwipeOutcome } from "./swipe-outcome";
import { usePassQueue } from "./use-pass-queue";
import { useSwipe } from "./use-swipe";

// One card queue with everything around it: loading lots, deferred passes,
// undo, likes with their refusals and the match sheet. Découvrir reloads when
// few cards remain; the daily picks load once.

const RELOAD_AT = 3;
const EXPIRED_COOLDOWN_MS = 30_000;

export interface DeckOptions {
  readonly load: (signal: AbortSignal) => Promise<readonly ProfileCard[]>;
  readonly autoReload: boolean;
  readonly keep?: (profile: ProfileCard) => boolean;
}

export interface DeckApi {
  readonly visible: readonly ProfileCard[];
  readonly status: "loading" | "ready" | "error";
  readonly error: string | null;
  readonly exhausted: boolean;
  readonly canUndo: boolean;
  readonly act: (card: ProfileCard, action: SwipeAction) => Promise<SwipeOutcome | null>;
  readonly undo: () => void;
  readonly refresh: () => void;
  readonly onExpired: () => void;
  readonly overlays: ReactNode;
  readonly overlayOpen: boolean;
}

export function useDeck({ load, autoReload, keep }: DeckOptions): DeckApi {
  const toast = useToast();
  const swipe = useSwipe();
  const [state, dispatch] = useReducer(deckReducer, EMPTY_DECK);
  const [status, setStatus] = useState<DeckApi["status"]>("loading");
  const [error, setError] = useState<string | null>(null);
  const loader = useRef(load);
  const alive = useRef(false);
  const busy = useRef(false);
  const generation = useRef(0);
  const lastExpired = useRef(0);
  const toasts = useRef(new Map<number, number>());
  useEffect(() => { loader.current = load; });

  const run = useCallback(async (force: boolean) => {
    if (busy.current && !force) return;
    const mine = force ? ++generation.current : generation.current;
    busy.current = true;
    const controller = new AbortController();
    try {
      const profiles = await loader.current(controller.signal);
      if (!alive.current || mine !== generation.current) return;
      dispatch({ type: "loaded", profiles });
      setStatus("ready");
      setError(null);
    } catch (failure) {
      if (!alive.current || mine !== generation.current) return;
      setStatus("error");
      setError(describeError(failure));
    } finally {
      if (mine === generation.current) busy.current = false;
    }
  }, []);

  useEffect(() => {
    alive.current = true;
    const first = window.setTimeout(() => void run(false), 0);
    const timer = window.setInterval(() => void run(false), SIGNED_URL_REFRESH_MS);
    return () => {
      alive.current = false;
      window.clearTimeout(first);
      window.clearInterval(timer);
    };
  }, [run]);

  const visible = useMemo(() => (keep ? state.cards.filter(keep) : state.cards), [state.cards, keep]);
  useEffect(() => {
    if (!autoReload || status !== "ready" || state.exhausted || visible.length > RELOAD_AT) return undefined;
    const timer = window.setTimeout(() => void run(false), 0);
    return () => window.clearTimeout(timer);
  }, [autoReload, status, state.exhausted, visible.length, run]);

  usePassQueue({ pending: state.pending, onSettled: (userIds) => dispatch({ type: "settled", userIds }), onFailure: (message) => toast.show(message) });

  const undoCard = useCallback((userId: number) => {
    dispatch({ type: "undo", userId });
    const shown = toasts.current.get(userId);
    if (shown !== undefined) toast.dismiss(shown);
  }, [toast]);

  const act = useCallback(async (card: ProfileCard, action: SwipeAction): Promise<SwipeOutcome | null> => {
    dispatch({ type: "decided", userId: card.user_id, action, now: Date.now() });
    if (action === "pass") {
      toasts.current.set(card.user_id, toast.show("Profil passé", { durationMs: PASS_DELAY_MS, action: { label: "Annuler", key: "Z", run: () => undoCard(card.user_id) } }));
      return null;
    }
    const outcome = await swipe.send(card, action);
    if (outcome.kind !== "ok") dispatch({ type: "restored", card });
    return outcome;
  }, [swipe, toast, undoCard]);

  const lastPassed = state.pending.at(-1)?.card.user_id;
  const undo = useCallback(() => { if (lastPassed !== undefined) undoCard(lastPassed); }, [lastPassed, undoCard]);

  const refresh = useCallback(() => {
    dispatch({ type: "reset" });
    setStatus("loading");
    void run(true);
  }, [run]);

  const onExpired = useCallback(() => {
    if (Date.now() - lastExpired.current < EXPIRED_COOLDOWN_MS) return;
    lastExpired.current = Date.now();
    void run(false);
  }, [run]);

  return { visible, status, error, exhausted: state.exhausted, canUndo: lastPassed !== undefined, act, undo, refresh, onExpired, overlays: swipe.overlays, overlayOpen: swipe.overlayOpen };
}
