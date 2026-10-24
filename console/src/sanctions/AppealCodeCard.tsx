import type { ReactElement } from "react";
import { Button } from "../shared/ui/Button";
import { Icon } from "../shared/ui/Icon";
import { useToast } from "../shared/ui/Toast";

/** Code de contestation : montré une seule fois, il n'est plus récupérable ensuite. */
export function AppealCodeCard({ code, reference }: { readonly code: string; readonly reference: string | undefined }): ReactElement {
  const toast = useToast();
  const copy = async (): Promise<void> => {
    try {
      await navigator.clipboard.writeText(code);
      toast.notify("Code de contestation copié.", "success");
    } catch {
      toast.notify("Copie impossible : sélectionnez le code à la main.", "error");
    }
  };
  return (
    <div className="appeal-card" role="status">
      <div className="appeal-head">
        <Icon name="alert" />
        <strong>Code de contestation, affiché une seule fois</strong>
      </div>
      <p>Il accompagne l'exposé des motifs envoyé au membre. Il ne pourra plus être consulté après avoir quitté cette page : conservez-le si le membre le demande.</p>
      <div className="appeal-code-row">
        <code className="appeal-code">{code}</code>
        <Button size="s" icon="copy" onClick={() => void copy()}>
          Copier
        </Button>
      </div>
      {reference !== undefined ? <p className="muted">Référence de la décision&nbsp;: {reference}</p> : null}
    </div>
  );
}
