import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import { BASE } from "../../shared/router";
import { useSession } from "../../shared/session";
import { Dialog } from "../../shared/ui/dialog";
import { Row, Section } from "./section";
import { REASON_MAX } from "./settings-model";

function DeleteDialog({ onClose }: { readonly onClose: () => void }) {
  const { signOut } = useSession();
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const remove = async () => {
    setBusy(true);
    setError(null);
    try {
      await api.delete("/api/users/me", reason.trim().length > 0 ? { reason: reason.trim() } : {});
    } catch (cause) {
      setError(describeError(cause));
      setBusy(false);
      return;
    }
    await signOut().catch((): void => window.location.assign(`${BASE}/connexion`));
  };
  return (
    <Dialog title="Supprimer mon compte" onClose={onClose}>
      <p className="body-m">Votre profil, vos photos, vos messages et vos matchs seront supprimés définitivement.</p>
      <p className="body-s">Un abonnement payé sur le site est résilié automatiquement. Un abonnement App Store se résilie dans les Réglages de l'iPhone (CGV, articles 5 et 9).</p>
      <div className="field">
        <label htmlFor="delete-reason">Pourquoi partez-vous ? (facultatif)</label>
        <textarea id="delete-reason" className="textarea" rows={3} maxLength={REASON_MAX} value={reason} onChange={(event) => setReason(event.target.value)} />
      </div>
      {error && <p className="field-error" role="alert">{error}</p>}
      <div className="inline gap-12">
        <button type="button" className="btn btn-outline" onClick={onClose}>Garder mon compte</button>
        <button type="button" className="btn btn-danger" disabled={busy} onClick={() => void remove()}>Supprimer</button>
      </div>
    </Dialog>
  );
}

export function DeleteAccountSection() {
  const [open, setOpen] = useState(false);
  return (
    <Section id="suppression" title="Supprimer mon compte">
      <Row title="Supprimer mon compte" sub="Définitif. Vos données sont effacées." action={<button type="button" className="btn btn-outline btn-sm" onClick={() => setOpen(true)}>Supprimer mon compte</button>} />
      {open && <DeleteDialog onClose={() => setOpen(false)} />}
    </Section>
  );
}
