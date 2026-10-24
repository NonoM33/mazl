import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import { validateJustification, JUSTIFICATION_MAX } from "../sanctions/form-model";
import type { ConversationDto } from "../shared/api/contracts";
import { formatDateTime, memberName } from "../shared/format";
import { Button } from "../shared/ui/Button";
import { Icon } from "../shared/ui/Icon";
import { Modal } from "../shared/ui/Modal";
import { Textarea } from "../shared/ui/Field";

function Conversation({ data }: { readonly data: ConversationDto }): ReactElement {
  const names = new Map(data.participants.map((participant) => [participant.id, memberName(participant)]));
  const firstSender = data.participants[0]?.id;
  if (data.messages.length === 0) return <p className="muted">Aucun message dans cette conversation.</p>;
  return (
    <ol className="chat" aria-label="Messages de la conversation signalée">
      {data.messages.map((message) => (
        <li key={message.id} className={`bubble-row${message.senderId === firstSender ? "" : " is-right"}`}>
          <div className={`bubble${message.reported ? " is-reported" : ""}${message.unsent ? " is-unsent" : ""}`}>
            <div className="bubble-meta">
              <span>{names.get(message.senderId) ?? `Membre n° ${message.senderId}`}</span>
              <time dateTime={message.sentAt}>{formatDateTime(message.sentAt)}</time>
            </div>
            <p>
              {message.unsent
                ? "Message retiré par son auteur"
                : message.type === "text"
                  ? (message.content ?? "")
                  : message.type === "photo"
                    ? "Photo envoyée"
                    : "Message vocal envoyé"}
            </p>
            {message.reported ? <span className="bubble-flag">Message signalé</span> : null}
          </div>
        </li>
      ))}
    </ol>
  );
}

export function ConversationModal({ reportId, onClose }: { readonly reportId: number; readonly onClose: () => void }): ReactElement {
  const { api } = useSession();
  const [justification, setJustification] = useState("");
  const [touched, setTouched] = useState(false);
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);
  const [data, setData] = useState<ConversationDto | null>(null);

  const error = touched ? validateJustification(justification) : null;

  const read = async (): Promise<void> => {
    setTouched(true);
    if (validateJustification(justification) !== null) return;
    setBusy(true);
    setFailure(null);
    const result = await api.get<ConversationDto>(`/reports/${reportId}/conversation`, { justification: justification.trim() });
    setBusy(false);
    if (result.ok) setData(result.data);
    else setFailure(result.message);
  };

  return (
    <Modal title={data === null ? "Lire la conversation signalée" : "Conversation signalée"} onClose={onClose} wide={data !== null}>
      {data === null ? (
        <form
          className="stack"
          noValidate
          onSubmit={(event) => {
            event.preventDefault();
            void read();
          }}
        >
          <p className="modal-lead">
            <Icon name="lock" size={16} /> Cette conversation est privée. Votre lecture et le motif ci-dessous sont inscrits au journal d'audit.
          </p>
          <Textarea
            label="Motif de la lecture"
            hint="Expliquez pourquoi vous avez besoin de lire cette conversation (10 à 500 caractères)."
            value={justification}
            onChange={setJustification}
            max={JUSTIFICATION_MAX}
            rows={4}
            error={error ?? undefined}
            autoFocus
          />
          {failure !== null ? (
            <p className="notice notice-error" role="alert">
              {failure}
            </p>
          ) : null}
          <div className="row-actions">
            <Button variant="ghost" onClick={onClose}>
              Annuler
            </Button>
            <Button type="submit" variant="primary" loading={busy}>
              Lire la conversation
            </Button>
          </div>
        </form>
      ) : (
        <div className="stack">
          <p className="modal-lead">
            <Icon name="info" size={16} /> Lecture inscrite au journal d'audit avec votre motif. Ne copiez pas ces messages hors de la console.
          </p>
          <Conversation data={data} />
          <div className="row-actions">
            <Button variant="primary" onClick={onClose}>
              Fermer
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}
