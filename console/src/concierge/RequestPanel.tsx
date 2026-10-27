import { useState, type ReactElement, type ReactNode } from "react";
import { useMe, useSession } from "../app/session";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Drawer } from "../shared/ui/Drawer";
import { ErrorState, Skeleton } from "../shared/ui/Feedback";
import { Select } from "../shared/ui/Select";
import { useToast } from "../shared/ui/Toast";
import { useAsync } from "../shared/ui/use-async";
import { Textarea } from "../shared/ui/Field";
import type { ApiResult } from "../shared/api/client";
import { conciergeApi } from "./api";
import { ConfirmDialog, type ConfirmSpec } from "./ConfirmDialog";
import { Conversation } from "./Conversation";
import { formatCoupleDuration, formatStamp, formatWantedDayLong } from "./dates";
import { conciergeErrorMessage } from "./errors";
import { assignRequest, closeRequest, markBookedRequest, staffMessageRequest, staffNoteRequest } from "./request-bodies";
import { actionsFor, isUrgent, STATUS_LABELS, STATUS_TONES, STEP_LABELS, stepOf } from "./status";
import { STAFF_MESSAGE_MAX, STAFF_NOTE_MAX, type RequestDetailDto, type Step } from "./types";

function Section({ title, children }: { readonly title: string; readonly children: ReactNode }): ReactElement {
  return (
    <section className="panel-section">
      <h3 className="eyebrow">{title}</h3>
      {children}
    </section>
  );
}

function Steps({ current }: { readonly current: Step }): ReactElement {
  const steps: readonly Step[] = [1, 2, 3];
  return (
    <ol className="steps" aria-label="Avancement vu par le couple">
      {steps.map((step) => (
        <li key={step} className={`step${step <= current ? " is-done" : ""}`} aria-current={step === current ? "step" : undefined}>
          <span className="step-dot" aria-hidden="true">
            {step}
          </span>
          {STEP_LABELS[step]}
        </li>
      ))}
    </ol>
  );
}

interface BodyProps {
  readonly initial: RequestDetailDto;
  readonly onChanged: () => void;
}

function Body({ initial, onChanged }: BodyProps): ReactElement {
  const me = useMe();
  const { api } = useSession();
  const toast = useToast();
  const store = conciergeApi(api);
  const [detail, setDetail] = useState(initial);
  const [note, setNote] = useState(initial.request.staffNote);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [failure, setFailure] = useState<string | null>(null);
  const [confirm, setConfirm] = useState<ConfirmSpec | null>(null);
  const { request, couple, messages } = detail;
  const actions = actionsFor(request.status);
  const urgent = isUrgent({ status: request.status, wantedAt: request.wantedAt }, new Date());
  const chosen = request.chosenIndex === null ? null : (request.options[request.chosenIndex] ?? null);
  const names = couple.firstNames.join(" & ");

  /** Appel d'écriture : met le détail à jour avec la réponse du serveur, ou affiche l'erreur en clair. */
  const write = async (key: string, call: () => Promise<ApiResult<RequestDetailDto>>, success: string): Promise<string | null> => {
    setBusy(key);
    setFailure(null);
    const result = await call();
    setBusy(null);
    if (!result.ok) {
      const text = conciergeErrorMessage(result);
      setFailure(text);
      return text;
    }
    setDetail(result.data);
    setNote(result.data.request.staffNote);
    toast.notify(success, "success");
    onChanged();
    return null;
  };

  const askBooked = (): void =>
    setConfirm({
      title: "Marquer comme réservé",
      lead: `Vous confirmez avoir réservé « ${chosen?.title ?? request.title} » pour ${names}. La demande passe à l'étape « Réservée » côté couple.`,
      confirmLabel: "Marquer réservé",
      variant: "primary",
      run: () => write("booked", () => store.patch(request.id, markBookedRequest()), "Demande marquée comme réservée."),
    });
  const askClose = (): void =>
    setConfirm({
      title: "Clore la demande",
      lead: `La demande de ${names} sera close : plus aucun message possible, et elle ne reviendra pas dans « À traiter ».`,
      confirmLabel: "Clore la demande",
      variant: "danger",
      run: () => write("closed", () => store.patch(request.id, closeRequest()), "Demande close."),
    });
  const askSend = (): void =>
    setConfirm({
      title: "Écrire au couple",
      lead: `Ce message est envoyé à ${names} dans leur conversation, avec une notification sur leurs téléphones. Relisez-le : il n'est pas modifiable.`,
      quote: message.trim(),
      confirmLabel: "Envoyer au couple",
      variant: "primary",
      run: async () => {
        const error = await write("message", () => store.sendMessage(request.id, staffMessageRequest(message)), "Message envoyé au couple.");
        if (error === null) setMessage("");
        return error;
      },
    });

  const assignees = [...new Set([me.email, ...(request.assignedTo === null ? [] : [request.assignedTo])])];
  const assign = (value: string | ""): void => {
    const next = value === "" ? null : value;
    if (next === request.assignedTo) return;
    void write("assign", () => store.patch(request.id, assignRequest(next)), next === null ? "Assignation retirée." : `Demande assignée à ${next}.`);
  };

  const noteChanged = note.trim() !== request.staffNote;
  const noteTooLong = note.length > STAFF_NOTE_MAX;
  const messageEmpty = message.trim() === "";
  const messageTooLong = message.length > STAFF_MESSAGE_MAX;

  return (
    <>
      <div className="panel-top">
        <div className="panel-badges">
          <Badge tone={STATUS_TONES[request.status]}>{STATUS_LABELS[request.status]}</Badge>
          {urgent ? <Badge tone="error">Urgent</Badge> : null}
        </div>
        <h3 className="panel-title">{request.title}</h3>
        <p className="panel-due">
          <strong>{names}</strong> · ensemble depuis {formatCoupleDuration(couple.months)}
        </p>
        <Steps current={stepOf(request.status)} />
        <div className="row-actions row-actions-start">
          {actions.canMarkBooked ? (
            <Button size="s" variant="primary" icon="check" loading={busy === "booked"} onClick={askBooked}>
              Marquer réservé
            </Button>
          ) : null}
          {actions.canWrite ? (
            <Button size="s" icon="message" onClick={() => document.getElementById("concierge-message")?.focus()}>
              Écrire au couple
            </Button>
          ) : null}
          {actions.canClose ? (
            <Button size="s" variant="danger" loading={busy === "closed"} onClick={askClose}>
              Clore
            </Button>
          ) : null}
        </div>
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
      </div>

      <Section title="La demande">
        <blockquote className="quote">{request.brief}</blockquote>
        <dl className="facts facts-wide">
          <div>
            <dt>Quand</dt>
            <dd>{formatWantedDayLong(request.wantedAt)}</dd>
          </div>
          <div>
            <dt>Où</dt>
            <dd>{request.city ?? "Non précisé"}</dd>
          </div>
          <div>
            <dt>Contraintes</dt>
            <dd>
              {request.constraints.kosher === true ? "Casher" : "Pas de contrainte casher"}
              {request.constraints.budget !== undefined ? ` · budget ${request.constraints.budget}` : ""}
            </dd>
          </div>
          <div>
            <dt>Choix du couple</dt>
            <dd>{chosen === null ? "Pas encore choisi" : chosen.title}</dd>
          </div>
        </dl>
        {request.options.length > 0 ? (
          <ol className="options" aria-label="Idées proposées par l'assistant">
            {request.options.map((option, index) => (
              <li key={option.title} className={index === request.chosenIndex ? "option is-chosen" : "option"}>
                <span className="option-head">
                  <strong>{option.title}</strong>
                  {index === request.chosenIndex ? <Badge tone="accent">Choisie par le couple</Badge> : null}
                </span>
                <span>{option.details}</span>
                <span className="cell-sub">{option.priceHint}</span>
              </li>
            ))}
          </ol>
        ) : (
          <p className="muted">L'assistant n'a proposé aucune idée : la demande est directement chez l'équipe.</p>
        )}
      </Section>

      <Section title="Assignation">
        <Select
          label="Responsable de la demande"
          compact
          value={request.assignedTo ?? ""}
          placeholder="Personne"
          options={assignees.map((email) => ({ value: email, label: email === me.email ? `Moi (${email})` : email }))}
          onChange={assign}
          hint="La liste des autres membres du staff est réservée aux super-administrateurs : ici, vous vous assignez la demande ou la libérez."
        />
      </Section>

      <Section title={`Conversation · ${messages.length}`}>
        <Conversation messages={messages} />
        {actions.canWrite ? (
          <div className="stack">
            <Textarea label="Écrire au couple" value={message} onChange={setMessage} max={STAFF_MESSAGE_MAX} rows={3} placeholder="Ex. : Bonne nouvelle, la table est disponible à 20 h." />
            <div className="row-actions">
              <Button variant="primary" icon="arrow-right" disabled={messageEmpty || messageTooLong} loading={busy === "message"} onClick={askSend}>
                Envoyer au couple
              </Button>
            </div>
          </div>
        ) : (
          <p className="muted">La demande est {request.status === "closed" ? "close" : "annulée"} : plus de message possible.</p>
        )}
      </Section>

      <Section title="Note interne">
        <Textarea
          label="Note visible du staff seulement"
          value={note}
          onChange={setNote}
          max={STAFF_NOTE_MAX}
          rows={3}
          hint="Jamais montrée au couple."
          error={noteTooLong ? `${STAFF_NOTE_MAX} caractères au plus.` : undefined}
        />
        <p className="muted">Mise à jour le {formatStamp(request.updatedAt)}</p>
        <div className="row-actions">
          <Button disabled={!noteChanged || noteTooLong} loading={busy === "note"} onClick={() => void write("note", () => store.patch(request.id, staffNoteRequest(note)), "Note enregistrée.")}>
            Enregistrer la note
          </Button>
        </div>
      </Section>
      {confirm !== null ? <ConfirmDialog spec={confirm} onClose={() => setConfirm(null)} /> : null}
    </>
  );
}

export function RequestPanel({ requestId, onClose, onChanged }: { readonly requestId: number; readonly onClose: () => void; readonly onChanged: () => void }): ReactElement {
  const { api } = useSession();
  const { state, reload } = useAsync(() => conciergeApi(api).get(requestId), [api, requestId]);
  return (
    <Drawer title={state.status === "ok" ? state.data.request.title : "Demande de conciergerie"} eyebrow={`Demande n° ${requestId}`} onClose={onClose} wide>
      {state.status === "loading" ? (
        <div className="stack" role="status" aria-label="Chargement de la demande">
          <Skeleton width="60%" height={26} />
          <Skeleton height={120} radius={12} />
          <Skeleton height={180} radius={12} />
        </div>
      ) : state.status === "error" ? (
        <ErrorState message={conciergeErrorMessage(state)} onRetry={reload} />
      ) : (
        <Body initial={state.data} onChanged={onChanged} />
      )}
    </Drawer>
  );
}
