import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import type { MatchingParams, ParamsVersionDto } from "../shared/api/contracts";
import { Button } from "../shared/ui/Button";
import { Modal } from "../shared/ui/Modal";
import { Textarea } from "../shared/ui/Field";
import { useToast } from "../shared/ui/Toast";
import { createVersionBody, NOTE_MAX, validateNote } from "./requests";
import type { ParamChange } from "./specs";

interface Props {
  readonly draft: MatchingParams;
  readonly changes: readonly ParamChange[];
  readonly blocked: boolean;
  readonly activeId: number;
  readonly onSaved: (version: ParamsVersionDto, activated: boolean) => void;
}

export function ChangeList({ changes }: { readonly changes: readonly ParamChange[] }): ReactElement {
  return (
    <ul className="change-list">
      {changes.map((change) => (
        <li key={change.key}>
          <span>{change.label}</span>
          <span className="change-values">
            {change.from} <span aria-hidden="true">→</span>
            <span className="sr-only"> devient </span> <strong>{change.to}</strong>
          </span>
        </li>
      ))}
    </ul>
  );
}

/** Enregistre une version : note obligatoire, activation facultative et confirmée. */
export function SaveCard({ draft, changes, blocked, activeId, onSaved }: Props): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const [note, setNote] = useState("");
  const [activate, setActivate] = useState(false);
  const [noteError, setNoteError] = useState<string | undefined>(undefined);
  const [serverError, setServerError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState(false);
  const [saving, setSaving] = useState(false);

  const save = async (): Promise<void> => {
    setSaving(true);
    setServerError(null);
    const result = await api.post<ParamsVersionDto>("/matching/versions", createVersionBody(draft, note, activate));
    setSaving(false);
    setConfirming(false);
    if (!result.ok) {
      setServerError(result.code === "invalid_params" ? `Réglages refusés par le serveur : ${result.message}` : result.message);
      return;
    }
    toast.notify(activate ? `Version n°${result.data.id} enregistrée et activée.` : `Version n°${result.data.id} enregistrée, non activée.`, "success");
    setNote("");
    setActivate(false);
    onSaved(result.data, activate);
  };

  const submit = (): void => {
    const error = validateNote(note);
    setNoteError(error ?? undefined);
    if (error !== null) return;
    if (activate) setConfirming(true);
    else void save();
  };

  return (
    <section className="card save-card" aria-labelledby="save-title">
      <h2 id="save-title">Enregistrer une version</h2>
      <p className="card-lead">
        {changes.length === 0 ? "Aucun écart avec la version active n°" + activeId + " : rien à enregistrer." : `${changes.length} réglage${changes.length > 1 ? "s" : ""} diffère${changes.length > 1 ? "nt" : ""} de la version active n°${activeId}.`}
      </p>
      <div className="stack">
        <Textarea label="Note de version (obligatoire)" value={note} onChange={setNote} max={NOTE_MAX} rows={3} hint="Pourquoi ce changement ? Elle apparaît dans l'historique et le journal d'audit." error={noteError} placeholder="Ex. Moins de poids à la distance pour les petites villes." />
        <label className="check check-accent">
          <input type="checkbox" checked={activate} onChange={(event) => setActivate(event.target.checked)} />
          <span>Activer cette version tout de suite (tous les membres seront classés avec elle)</span>
        </label>
        {serverError !== null ? (
          <p className="notice notice-error" role="alert">
            {serverError}
          </p>
        ) : null}
        <div className="row-actions row-actions-start">
          <Button variant="primary" icon="check" loading={saving} disabled={blocked || changes.length === 0} onClick={submit}>
            {activate ? "Enregistrer et activer…" : "Enregistrer la version"}
          </Button>
          {blocked ? <span className="muted">Corrigez d'abord les réglages signalés en rouge.</span> : null}
        </div>
      </div>
      {confirming ? (
        <Modal title="Activer cette version maintenant ?" onClose={() => setConfirming(false)} wide>
          <div className="stack">
            <p className="notice notice-warning">
              <strong>Effet immédiat sur tous les membres.</strong> Le classement de la découverte change dès l'activation. Vous pourrez revenir en arrière en activant à nouveau la version n°&nbsp;{activeId} depuis l'historique.
            </p>
            <ChangeList changes={changes} />
            <p>
              <span className="muted">Note :</span> « {note.trim()} »
            </p>
            <div className="row-actions">
              <Button onClick={() => setConfirming(false)}>Annuler</Button>
              <Button variant="primary" loading={saving} onClick={() => void save()}>
                Enregistrer et activer
              </Button>
            </div>
          </div>
        </Modal>
      ) : null}
    </section>
  );
}
