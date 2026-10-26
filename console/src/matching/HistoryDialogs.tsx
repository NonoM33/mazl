import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import type { MatchingStateDto, ParamsVersionDto } from "../shared/api/contracts";
import { Button } from "../shared/ui/Button";
import { Field, Textarea } from "../shared/ui/Field";
import { Modal } from "../shared/ui/Modal";
import { Select } from "../shared/ui/Select";
import { useToast } from "../shared/ui/Toast";
import { abTestBody, activateBody, AB_SHARE_MAX, AB_SHARE_MIN, NOTE_MAX, validateNote } from "./requests";

function Failure({ message }: { readonly message: string | null }): ReactElement | null {
  return message === null ? null : (
    <p className="notice notice-error" role="alert">
      {message}
    </p>
  );
}

export function ActivateModal({ version, activeId, onClose, onDone }: { readonly version: ParamsVersionDto; readonly activeId: number; readonly onClose: () => void; readonly onDone: () => void }): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const [note, setNote] = useState("");
  const [noteError, setNoteError] = useState<string | undefined>(undefined);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const rollback = version.id < activeId;
  const submit = async (): Promise<void> => {
    const problem = validateNote(note);
    setNoteError(problem ?? undefined);
    if (problem !== null) return;
    setBusy(true);
    setError(null);
    const result = await api.post<MatchingStateDto>(`/matching/versions/${version.id}/activate`, activateBody(note));
    setBusy(false);
    if (!result.ok) {
      setError(result.message);
      return;
    }
    toast.notify(`Version n°${version.id} activée.`, "success");
    onDone();
  };
  return (
    <Modal title={rollback ? `Revenir à la version n°${version.id}` : `Activer la version n°${version.id}`} onClose={onClose}>
      <div className="stack">
        <p className="notice notice-warning">
          <strong>Effet immédiat sur tous les membres.</strong> {rollback ? "Réactiver une ancienne version sert de retour arrière : aucune donnée n'est perdue." : "Le classement change dès l'activation."} Si un test A/B porte sur cette version, il prend fin.
        </p>
        <Textarea label="Note (obligatoire)" value={note} onChange={setNote} max={NOTE_MAX} rows={3} error={noteError} hint="Pourquoi activer cette version maintenant ? Elle est conservée dans l'historique et le journal d'audit." autoFocus />
        <Failure message={error} />
        <div className="row-actions">
          <Button onClick={onClose}>Annuler</Button>
          <Button variant="primary" loading={busy} onClick={() => void submit()}>
            {rollback ? "Revenir à cette version" : "Activer la version"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}

export function AbStartModal({
  versions,
  activeId,
  initial,
  onClose,
  onDone,
}: {
  readonly versions: readonly ParamsVersionDto[];
  readonly activeId: number;
  readonly initial: number | null;
  readonly onClose: () => void;
  readonly onDone: () => void;
}): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const choices = versions.filter((version) => version.id !== activeId);
  const [variant, setVariant] = useState<string>(initial === null ? "" : String(initial));
  const [share, setShare] = useState("10");
  const [error, setError] = useState<string | null>(null);
  const [fieldError, setFieldError] = useState<string | undefined>(undefined);
  const [busy, setBusy] = useState(false);
  const submit = async (): Promise<void> => {
    const body = abTestBody(variant === "" ? null : Number(variant), share);
    if (!body.ok) {
      setFieldError(body.error);
      return;
    }
    setFieldError(undefined);
    setBusy(true);
    setError(null);
    const result = await api.post<MatchingStateDto>("/matching/ab-test", body.value);
    setBusy(false);
    if (!result.ok) {
      setError(result.message);
      return;
    }
    toast.notify(`Test A/B lancé : ${body.value.sharePercent} % des membres avec la version n°${body.value.variantId}.`, "success");
    onDone();
  };
  return (
    <Modal title="Démarrer un test A/B" onClose={onClose}>
      <div className="stack">
        <p className="muted">Une part des membres sera classée avec la version choisie, le reste avec la version active n°&nbsp;{activeId}. Un seul test peut tourner à la fois.</p>
        <Select
          label="Version à tester"
          value={variant}
          placeholder="Choisir une version"
          options={choices.map((version) => ({ value: String(version.id), label: `n° ${version.id} · ${version.note}` }))}
          onChange={setVariant}
          error={variant === "" ? fieldError : undefined}
        />
        <Field label={`Part des membres (${AB_SHARE_MIN} à ${AB_SHARE_MAX} %)`} hint="Les membres sont répartis selon leur numéro : un membre reste dans le même groupe." error={variant === "" ? undefined : fieldError}>
          {({ id, describedBy, invalid }) => <input id={id} className="input input-narrow" inputMode="numeric" value={share} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => setShare(event.target.value)} />}
        </Field>
        <Failure message={error} />
        <div className="row-actions">
          <Button onClick={onClose}>Annuler</Button>
          <Button variant="primary" loading={busy} onClick={() => void submit()}>
            Démarrer le test
          </Button>
        </div>
      </div>
    </Modal>
  );
}

export function AbStopModal({ variantId, onClose, onDone }: { readonly variantId: number; readonly onClose: () => void; readonly onDone: () => void }): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const stop = async (): Promise<void> => {
    setBusy(true);
    setError(null);
    const result = await api.delete<MatchingStateDto>("/matching/ab-test");
    setBusy(false);
    if (!result.ok) {
      setError(result.message);
      return;
    }
    toast.notify("Test A/B arrêté : tous les membres reviennent à la version active.", "success");
    onDone();
  };
  return (
    <Modal title="Arrêter le test A/B ?" onClose={onClose}>
      <div className="stack">
        <p>Tous les membres reviennent à la version active. La version n°&nbsp;{variantId} reste dans l'historique et peut être testée de nouveau.</p>
        <Failure message={error} />
        <div className="row-actions">
          <Button onClick={onClose}>Garder le test</Button>
          <Button variant="danger" loading={busy} onClick={() => void stop()}>
            Arrêter le test
          </Button>
        </div>
      </div>
    </Modal>
  );
}
