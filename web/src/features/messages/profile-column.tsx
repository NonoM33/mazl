import { useState } from "react";
import { Ban, Flag, Heart } from "lucide-react";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { ProfileResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Dialog } from "../../shared/ui/dialog";
import { Skeleton } from "../../shared/ui/empty-state";
import { MobileOnly } from "../../shared/ui/mobile-only";
import { ProfilePanel } from "../../shared/ui/profile-panel";
import { useToast } from "../../shared/ui/toast";
import { displayName } from "../../shared/lib/format";
import { ReportFlow } from "./report-flow";

// Right column: the other member's profile and the actions on them.

function coupleErrorMessage(error: unknown): string {
  if (error instanceof ApiError && error.status === 403) return "Le mode couple se propose entre deux personnes qui ont fait match.";
  if (error instanceof ApiError && error.status === 409) return "Une demande est déjà en cours avec cette personne.";
  return describeError(error);
}

function BlockDialog({ name, busy, onConfirm, onClose }: { readonly name: string; readonly busy: boolean; readonly onConfirm: () => void; readonly onClose: () => void }) {
  return (
    <Dialog title={`Bloquer ${name} ?`} onClose={onClose}>
      <p className="body-m muted">Vous ne verrez plus cette personne et elle ne pourra plus vous écrire. Vous pourrez la débloquer depuis les réglages.</p>
      <div className="inline gap-8" style={{ justifyContent: "flex-end" }}>
        <button type="button" className="btn btn-outline btn-sm" onClick={onClose}>Annuler</button>
        <button type="button" className="btn btn-danger btn-sm" disabled={busy} onClick={onConfirm}>Bloquer</button>
      </div>
    </Dialog>
  );
}

export function ProfileColumn({ userId, fallbackName, onBlocked }: { readonly userId: number; readonly fallbackName: string; readonly onBlocked: () => void }) {
  const toast = useToast();
  const profile = useResource(`profile:${userId}`, (signal) => api.get<ProfileResponse>(`/api/profile/${userId}`, signal));
  const [dialog, setDialog] = useState<"block" | "report" | null>(null);
  const [busy, setBusy] = useState(false);
  const name = profile.state.data ? displayName(profile.state.data.profile.display_name) : fallbackName;

  const block = async () => {
    setBusy(true);
    try {
      await api.post(`/api/users/${userId}/block`);
      setDialog(null);
      toast.show(`${name} est bloqué.`);
      onBlocked();
    } catch (error) {
      toast.show(describeError(error));
    } finally {
      setBusy(false);
    }
  };
  const proposeCouple = async () => {
    setBusy(true);
    try {
      await api.post("/api/couple/request", { target_user_id: userId });
      toast.show(`Demande envoyée à ${name}.`);
    } catch (error) {
      toast.show(coupleErrorMessage(error));
    } finally {
      setBusy(false);
    }
  };

  return (
    <aside className="profile-col col-scroll" aria-label={`Profil de ${name}`}>
      {profile.state.status === "loading" && <div className="stack gap-16"><Skeleton height={28} width="60%" /><Skeleton height={120} /><Skeleton height={220} /></div>}
      {profile.state.status === "error" && profile.state.data === undefined && <p className="body-s" role="alert">Ce profil n'a pas pu être chargé.</p>}
      {profile.state.data && <ProfilePanel profile={profile.state.data.profile} onExpired={() => void profile.reload()} />}
      <div className="stack gap-8 profile-actions">
        <button type="button" className="btn btn-outline btn-sm btn-block" disabled={busy} onClick={() => void proposeCouple()}><Heart size={18} aria-hidden="true" />Proposer le mode couple</button>
        <MobileOnly compact title="Appel vidéo">Les appels vidéo se passent depuis l'application MAZL.</MobileOnly>
        <button type="button" className="btn btn-outline btn-sm btn-block" onClick={() => setDialog("report")}><Flag size={18} aria-hidden="true" />Signaler</button>
        <button type="button" className="btn btn-outline btn-sm btn-block danger-text" onClick={() => setDialog("block")}><Ban size={18} aria-hidden="true" />Bloquer</button>
      </div>
      {dialog === "block" && <BlockDialog name={name} busy={busy} onConfirm={() => void block()} onClose={() => setDialog(null)} />}
      {dialog === "report" && <ReportFlow target={{ kind: "member" }} userId={userId} name={name} onClose={() => setDialog(null)} onBlocked={onBlocked} />}
    </aside>
  );
}
