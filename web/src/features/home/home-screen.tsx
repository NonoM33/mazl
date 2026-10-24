import { useCallback, useEffect, useMemo, useState } from "react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import type { DailyPicksResponse } from "../../shared/api/types";
import { useHotkeys } from "../../shared/hooks/use-hotkeys";
import { useMe } from "../../shared/session";
import { formatHms, remainingMs } from "../discover/clock";
import { chooseShadchan } from "../discover/shadchan";
import { useDeck } from "../discover/use-deck";
import { useNow } from "../discover/use-now";
import { PickDialog } from "./pick-dialog";
import { PickTile, PicksDone, PicksSkeleton } from "./picks-grid";
import { ShadchanCard } from "./shadchan-card";
import { ShortcutsRow } from "./shortcuts-row";
import "./home.css";

function firstName(name: string | null | undefined): string {
  return name?.trim().split(/\s+/)[0] ?? "";
}

export function HomeScreen() {
  const me = useMe();
  const [refreshesAt, setRefreshesAt] = useState<string | null>(null);
  const load = useCallback(async (signal: AbortSignal) => {
    const response = await api.get<DailyPicksResponse>("/api/daily-picks", signal);
    setRefreshesAt(response.refreshesAt);
    return response.picks;
  }, []);
  const deck = useDeck({ load, autoReload: false });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const now = useNow();
  const left = refreshesAt === null ? null : remainingMs(refreshesAt, now);
  const { refresh } = deck;
  useEffect(() => { if (left === 0) refresh(); }, [left, refresh]);

  const selected = deck.visible.find((profile) => profile.user_id === selectedId);
  const shadchan = useMemo(() => chooseShadchan(me.profile, deck.visible), [me.profile, deck.visible]);
  const name = firstName(me.profile?.display_name ?? me.user.name);
  const countdown = left === null ? null : formatHms(left);
  useHotkeys({ z: deck.undo }, !deck.overlayOpen);
  const closeDialog = useCallback(() => setSelectedId(null), []);

  return (
    <>
      <ScreenHeader title={name ? `Bonjour ${name}` : "Bonjour"} />
      <div className="screen-body">
        <div className="page stack gap-32">
          {shadchan && <ShadchanCard choice={shadchan} onOpen={() => setSelectedId(shadchan.pick.user_id)} onExpired={deck.onExpired} />}
          <section className="stack gap-16" aria-label="Sélections du jour">
            <div className="spread">
              <h2 className="headline-s">Sélections du jour</h2>
              {countdown && deck.visible.length > 0 && <p className="label-m tabular">Mis à jour dans {countdown}</p>}
            </div>
            {deck.status === "loading" && <PicksSkeleton />}
            {deck.status === "error" && deck.visible.length === 0 && <p className="banner banner-error" role="alert">{deck.error}</p>}
            {deck.status === "ready" && deck.visible.length === 0 && <PicksDone countdown={countdown} />}
            {deck.visible.length > 0 && (
              <div className="picks-grid">
                {deck.visible.map((profile) => <PickTile key={profile.user_id} profile={profile} onOpen={() => setSelectedId(profile.user_id)} onExpired={deck.onExpired} />)}
              </div>
            )}
          </section>
          <ShortcutsRow />
        </div>
      </div>
      {selected && (
        <PickDialog
          profile={selected}
          onClose={closeDialog}
          onExpired={deck.onExpired}
          onPass={() => void deck.act(selected, "pass")}
          onLike={() => void deck.act(selected, "like")}
        />
      )}
      {deck.overlays}
    </>
  );
}
