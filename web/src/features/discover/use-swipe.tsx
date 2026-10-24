import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { LikeAllowance, MatchesResponse, ProfileCard, SwipeAction } from "../../shared/api/types";
import { realtime } from "../../shared/realtime/socket";
import { useToast } from "../../shared/ui/toast";
import { cardPhotos } from "./photos";
import { MatchSheet } from "./match-sheet";
import { parseMatchEvent, type MatchEvent } from "./match-event";
import { LikesExhaustedDialog, SuperLikesExhaustedDialog } from "./refusal-dialogs";
import { classifySwipeError, okOutcome, type SwipeOutcome } from "./swipe-outcome";
import { postSwipe } from "./swipe-client";

// The swipe rules shared by Découvrir and Accueil: send a like or a Super
// Like, and turn the answer into the right sheet or message.

type Refusal = { readonly kind: "likes"; readonly allowance: LikeAllowance | null } | { readonly kind: "super" };

export interface SwipeApi {
  readonly send: (card: ProfileCard, action: Exclude<SwipeAction, "pass">) => Promise<SwipeOutcome>;
  readonly overlays: ReactNode;
  // A sheet or dialog is open: the keyboard must not swipe behind it.
  readonly overlayOpen: boolean;
}

export function useSwipe(): SwipeApi {
  const toast = useToast();
  const [refusal, setRefusal] = useState<Refusal | null>(null);
  const [match, setMatch] = useState<MatchEvent | null>(null);
  const shown = useRef(new Set<number>());

  // A match can arrive twice (our own answer, then the socket frame): show it once.
  const openMatch = useCallback((incoming: MatchEvent) => {
    setMatch((current) => {
      if (current?.userId === incoming.userId) return { ...current, conversationId: incoming.conversationId ?? current.conversationId };
      if (shown.current.has(incoming.userId)) return current;
      shown.current.add(incoming.userId);
      return incoming;
    });
  }, []);

  useEffect(() => realtime.on("match:new", (payload) => {
    const event = parseMatchEvent(payload);
    if (event) openMatch(event);
  }), [openMatch]);

  const findConversation = useCallback(async (userId: number) => {
    try {
      const { matches } = await api.get<MatchesResponse>("/api/matches");
      const conversationId = matches.find((item) => item.profile.user_id === userId)?.conversationId ?? null;
      if (conversationId !== null) setMatch((current) => (current?.userId === userId ? { ...current, conversationId } : current));
    } catch {
      // The sheet still works: « Envoyer un message » then opens the inbox.
    }
  }, []);

  const send = useCallback(async (card: ProfileCard, action: Exclude<SwipeAction, "pass">): Promise<SwipeOutcome> => {
    let outcome: SwipeOutcome;
    try {
      outcome = okOutcome(await postSwipe(card.user_id, action));
    } catch (error) {
      outcome = classifySwipeError(error);
    }
    if (outcome.kind === "ok" && outcome.match) {
      openMatch({ userId: card.user_id, name: card.display_name ?? "", picture: cardPhotos(card)[0] ?? null, conversationId: null });
      void findConversation(card.user_id);
    } else if (outcome.kind === "likes_exhausted") setRefusal({ kind: "likes", allowance: outcome.allowance });
    else if (outcome.kind === "super_likes_exhausted") setRefusal({ kind: "super" });
    else if (outcome.kind === "rate_limited" || outcome.kind === "failed") toast.show(outcome.kind === "failed" ? describeError(outcome.error) : `Doucement : réessayez dans ${outcome.retryAfter ?? 60} s.`);
    return outcome;
  }, [findConversation, openMatch, toast]);

  const closeRefusal = useCallback(() => setRefusal(null), []);
  const closeMatch = useCallback(() => setMatch(null), []);
  const overlays = (
    <>
      {refusal?.kind === "likes" && <LikesExhaustedDialog allowance={refusal.allowance} onClose={closeRefusal} />}
      {refusal?.kind === "super" && <SuperLikesExhaustedDialog onClose={closeRefusal} />}
      {match && <MatchSheet match={match} onClose={closeMatch} />}
    </>
  );
  return { send, overlays, overlayOpen: refusal !== null || match !== null };
}
