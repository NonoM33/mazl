import { useState, type ReactElement } from "react";
import { Button, type ButtonVariant } from "../shared/ui/Button";
import { Modal } from "../shared/ui/Modal";

export interface ConfirmSpec {
  readonly title: string;
  readonly lead: string;
  readonly quote?: string;
  readonly confirmLabel: string;
  readonly variant: Extract<ButtonVariant, "primary" | "danger">;
  /** Rend le message d'erreur du serveur, ou null quand l'action a réussi. */
  readonly run: () => Promise<string | null>;
}

/** On dit ce qui va se passer, on appelle, on affiche l'erreur du serveur si elle vient ; la fenêtre se ferme au succès. */
export function ConfirmDialog({ spec, onClose }: { readonly spec: ConfirmSpec; readonly onClose: () => void }): ReactElement {
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);
  const run = (): void => {
    setBusy(true);
    setFailure(null);
    void spec.run().then((message) => {
      setBusy(false);
      if (message === null) onClose();
      else setFailure(message);
    });
  };
  return (
    <Modal title={spec.title} onClose={onClose}>
      <div className="stack">
        <p className="modal-lead">{spec.lead}</p>
        {spec.quote !== undefined ? <blockquote className="quote">{spec.quote}</blockquote> : null}
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <div className="row-actions">
          <Button variant="ghost" onClick={onClose}>
            Pas maintenant
          </Button>
          <Button variant={spec.variant} loading={busy} onClick={run}>
            {spec.confirmLabel}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
