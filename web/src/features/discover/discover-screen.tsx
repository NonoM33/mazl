import { useCallback, useEffect, useRef, useState } from "react";
import { ScreenHeader } from "../../app/shell";
import type { ProfileCard, SwipeAction } from "../../shared/api/types";
import { useHotkeys } from "../../shared/hooks/use-hotkeys";
import { displayName } from "../../shared/lib/format";
import { useMe } from "../../shared/session";
import { Dialog } from "../../shared/ui/dialog";
import { ProfilePanel } from "../../shared/ui/profile-panel";
import { ActionBar } from "./action-bar";
import { matchesFilters, NO_FILTERS, type AdvancedFilters } from "./advanced-filters";
import { AdvancedFiltersPanel } from "./advanced-filters-panel";
import { BoostButton } from "./boost-button";
import { cardPhotos } from "./photos";
import { DeckEmpty, DeckError, DeckSkeleton, IncompleteProfile } from "./deck-states";
import { DeckStage, type Leaving } from "./deck-stage";
import { PreferencesPanel } from "./preferences-panel";
import { loadDiscoverLot } from "./load-lot";
import { useLikeAllowance, usePlus, useSuperLikeCredits } from "./use-discover-data";
import { useDeck } from "./use-deck";
import { usePhotoIndex } from "./use-photo-index";
import "./discover.css";

const EXIT_MS = 260;

export function DiscoverScreen() {
  const me = useMe();
  const plus = usePlus();
  const credits = useSuperLikeCredits();
  const allowance = useLikeAllowance();
  const [filters, setFilters] = useState<AdvancedFilters>(NO_FILTERS);
  const keep = useCallback((profile: ProfileCard) => !plus || matchesFilters(profile, filters), [filters, plus]);
  const deck = useDeck({ load: loadDiscoverLot, autoReload: true, keep });
  const top = deck.visible[0];
  const photos = usePhotoIndex(top?.user_id, top ? cardPhotos(top).length : 0);
  const [leaving, setLeaving] = useState<Leaving | null>(null);
  const [detail, setDetail] = useState(false);
  const column = useRef<HTMLElement>(null);
  const nonce = useRef(0);

  useEffect(() => {
    if (!leaving) return undefined;
    const timer = window.setTimeout(() => setLeaving(null), EXIT_MS);
    return () => window.clearTimeout(timer);
  }, [leaving]);

  const decide = useCallback((action: SwipeAction) => {
    if (!top) return;
    nonce.current += 1;
    setLeaving({ profile: top, action, photoIndex: photos.index, nonce: nonce.current });
    void deck.act(top, action).then((outcome) => {
      if (outcome === null) return;
      if (outcome.kind === "ok") { void allowance.reload(); void credits.reload(); } else setLeaving(null);
    });
  }, [top, photos.index, deck, allowance, credits]);

  const blocked = detail || deck.overlayOpen;
  useHotkeys({ arrowleft: () => decide("pass"), arrowright: () => decide("like"), arrowup: () => decide("super_like"), z: deck.undo, " ": () => photos.step(1, true) }, !blocked);
  useHotkeys({ i: () => setDetail((open) => !open) }, !deck.overlayOpen && top !== undefined);

  const closeDetail = useCallback(() => setDetail(false), []);
  const reload = useCallback(() => { deck.refresh(); void allowance.reload(); }, [deck, allowance]);

  return (
    <>
      <ScreenHeader title="Découvrir" actions={<BoostButton />} />
      <div className="screen-body">
        <div className="cols cols-discover">
          <aside ref={column} className="stack gap-32 col-scroll discover-filters" tabIndex={-1} aria-label="Filtres">
            <PreferencesPanel profile={me.profile} onSaved={reload} />
            <AdvancedFiltersPanel filters={filters} plus={plus} onChange={setFilters} />
          </aside>
          <section className="stack gap-24" aria-label="Profils proposés">
            {top === undefined && deck.incomplete !== null && <IncompleteProfile missing={deck.incomplete} />}
            {top === undefined && deck.status === "error" && deck.incomplete === null && <DeckError message={deck.error ?? ""} onRetry={deck.refresh} />}
            {top === undefined && deck.status !== "error" && !deck.exhausted && <DeckSkeleton />}
            {top === undefined && deck.status !== "error" && deck.exhausted && <DeckEmpty onOpenFilters={() => column.current?.focus()} onRefresh={deck.refresh} />}
            {top !== undefined && <DeckStage visible={deck.visible} photoIndex={photos.index} leaving={leaving} onStep={photos.step} onExpired={deck.onExpired} />}
            {top !== undefined && (
              <ActionBar disabled={false} superLikes={credits.state.data?.credits.super_like.available ?? null} likesLeft={allowance.state.data?.remaining ?? null} onAct={decide} />
            )}
          </section>
          <aside className="col-scroll" aria-label="Profil">
            {top !== undefined && <ProfilePanel key={top.user_id} profile={top} onExpired={deck.onExpired} />}
          </aside>
        </div>
      </div>
      {detail && top !== undefined && (
        <Dialog title={`Détail du profil de ${displayName(top.display_name)}`} onClose={closeDetail} wide>
          <ProfilePanel profile={top} onExpired={deck.onExpired} />
        </Dialog>
      )}
      {deck.overlays}
    </>
  );
}
