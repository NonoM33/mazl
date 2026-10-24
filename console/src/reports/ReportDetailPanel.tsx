import { useState, type ReactElement } from "react";
import { can } from "../app/permissions";
import { useMe, useSession } from "../app/session";
import { MemberCell } from "../members/MemberCell";
import { AppealCodeCard } from "../sanctions/AppealCodeCard";
import { DecisionForm } from "../sanctions/DecisionForm";
import { toReportDecisionBody, type DecisionForm as FormState } from "../sanctions/form-model";
import type { ApiResult } from "../shared/api/client";
import type { DecisionResultDto, ReportDetailDto } from "../shared/api/contracts";
import { dueLabel, formatAccountAge, formatDateTime, memberName, relativeTime } from "../shared/format";
import { REASON_LABELS, SANCTION_LABELS, STATUS_LABELS, VERIFICATION_LABELS } from "../shared/labels";
import { Badge, PriorityBadge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Drawer } from "../shared/ui/Drawer";
import { ErrorState, Skeleton } from "../shared/ui/Feedback";
import { SignalList } from "../shared/ui/SignalList";
import { useToast } from "../shared/ui/Toast";
import { useAsync } from "../shared/ui/use-async";
import { buildHash } from "../app/router";
import { ConversationModal } from "./ConversationModal";

interface PanelProps {
  readonly reportId: number;
  readonly onClose: () => void;
  readonly onChanged: () => void;
}

function Section({ title, children }: { readonly title: string; readonly children: React.ReactNode }): ReactElement {
  return (
    <section className="panel-section">
      <h3 className="eyebrow">{title}</h3>
      {children}
    </section>
  );
}

function Body({ report, onChanged, onResult, onReload }: { readonly report: ReportDetailDto; readonly onChanged: () => void; readonly onResult: (result: DecisionResultDto) => void; readonly onReload: () => void }): ReactElement {
  const me = useMe();
  const { api } = useSession();
  const toast = useToast();
  const [reading, setReading] = useState(false);
  const [assigning, setAssigning] = useState(false);
  const due = dueLabel(report.dueAt);
  const open = report.status === "pending" || report.status === "in_review";
  const mine = report.assignedTo === me.email;
  const canDecide = can(me, "reports.decide");

  const assign = async (): Promise<void> => {
    setAssigning(true);
    const result = await api.post<unknown>(`/reports/${report.id}/assign`, { to: "me" });
    setAssigning(false);
    if (result.ok) {
      toast.notify("Signalement assigné à vous.", "success");
      onReload();
      onChanged();
    } else {
      toast.notify(result.message, "error");
    }
  };

  const submit = async (form: FormState): Promise<ApiResult<DecisionResultDto>> => {
    const body = toReportDecisionBody(form);
    if (body === null) return { ok: false, status: 0, code: "invalid", message: "Formulaire incomplet." };
    const result = await api.post<DecisionResultDto>(`/reports/${report.id}/decision`, body);
    return result;
  };

  return (
    <>
      <div className="panel-top">
        <div className="panel-badges">
          <PriorityBadge priority={report.priority} />
          <Badge tone={open ? "neutral" : "success"}>{STATUS_LABELS[report.status]}</Badge>
        </div>
        <h3 className="panel-title">{REASON_LABELS[report.reason]}</h3>
        <p className={`panel-due${due.late && open ? " is-late" : ""}`}>
          Signalé {relativeTime(report.createdAt)} · échéance&nbsp;: {open ? due.text : formatDateTime(report.dueAt)}
        </p>
        <div className="row-actions row-actions-start">
          {open ? (
            <Button size="s" icon="user" onClick={() => void assign()} loading={assigning} disabled={mine || !canDecide}>
              {mine ? "Assigné à vous" : report.assignedTo === null ? "M'assigner" : "Me réassigner"}
            </Button>
          ) : null}
          {can(me, "conversations.read") ? (
            <Button size="s" icon="message" onClick={() => setReading(true)}>
              Lire la conversation
            </Button>
          ) : null}
        </div>
        {report.assignedTo !== null && !mine ? <p className="muted">Assigné à {report.assignedTo}</p> : null}
      </div>

      <Section title="Membre signalé">
        <div className="reported-member">
          <MemberCell member={report.reported} />
          <Badge>{VERIFICATION_LABELS[report.reported.verification]}</Badge>
          {can(me, "members.read") ? (
            <a className="link-arrow" href={buildHash("membres", report.reported.id)}>
              Ouvrir la fiche
            </a>
          ) : null}
        </div>
      </Section>

      <Section title="Détails du signaleur">
        <p className="muted">{report.reporterId === null ? "Signalement automatique ou compte supprimé." : `Membre n° ${report.reporterId}`}</p>
        {report.details !== null ? <blockquote className="quote">{report.details}</blockquote> : <p className="muted">Aucun détail fourni.</p>}
      </Section>

      {report.reportedMessage !== null ? (
        <Section title="Message signalé">
          <blockquote className="quote quote-reported">
            {report.reportedMessage.unsent ? <em>Message retiré par son auteur.</em> : (report.reportedMessage.content ?? <em>Contenu non textuel.</em>)}
            <footer>{formatDateTime(report.reportedMessage.sentAt)}</footer>
          </blockquote>
        </Section>
      ) : null}

      <Section title={`Signaux de risque · ${report.riskSignals.length}`}>
        <SignalList signals={report.riskSignals} />
      </Section>

      <Section title="Historique du membre">
        <dl className="facts">
          <div>
            <dt>Signalements</dt>
            <dd>{report.memberHistory.reports.length}</dd>
          </div>
          <div>
            <dt>Sanctions</dt>
            <dd>{report.memberHistory.sanctions.length}</dd>
          </div>
          <div>
            <dt>Blocages reçus</dt>
            <dd>{report.memberHistory.blocksReceived}</dd>
          </div>
          <div>
            <dt>Ancienneté</dt>
            <dd>{formatAccountAge(report.memberHistory.accountAgeDays)}</dd>
          </div>
        </dl>
        {report.memberHistory.sanctions.length > 0 ? (
          <ul className="history">
            {report.memberHistory.sanctions.map((sanction) => (
              <li key={sanction.id}>
                <strong>{SANCTION_LABELS[sanction.kind]}</strong> · {relativeTime(sanction.startsAt)}
                {sanction.revokedAt !== null ? " · révoquée" : ""}
              </li>
            ))}
          </ul>
        ) : null}
      </Section>

      {open ? (
        <>
          <Section title="Sanction suggérée">
            {report.suggestedSanction !== null ? (
              <div className="suggestion">
                <strong>{SANCTION_LABELS[report.suggestedSanction]}</strong>
                <span>La plus légère que l'échelle des sanctions propose au vu de l'historique. À vous de décider.</span>
              </div>
            ) : (
              <p className="muted">Aucune suggestion pour ce dossier.</p>
            )}
          </Section>
          <Section title="Décision">
            {canDecide ? (
              <DecisionForm
                mode="report"
                suggested={report.suggestedSanction}
                canBan={can(me, "sanctions.ban")}
                canSanction={can(me, "sanctions.apply")}
                onSubmit={submit}
                onDone={(result) => {
                  onResult(result);
                  onReload();
                  onChanged();
                }}
              />
            ) : (
              <p className="muted">Votre rôle permet de consulter ce signalement, pas de le trancher.</p>
            )}
          </Section>
        </>
      ) : (
        <Section title="Décision prise">
          <p>
            {STATUS_LABELS[report.status]}
            {report.handledBy !== null ? ` par ${report.handledBy}` : ""}
            {report.handledAt !== null ? ` · ${formatDateTime(report.handledAt)}` : ""}
          </p>
          {report.decisionNote !== null ? <blockquote className="quote">{report.decisionNote}</blockquote> : null}
        </Section>
      )}
      {reading ? <ConversationModal reportId={report.id} onClose={() => setReading(false)} /> : null}
    </>
  );
}

export function ReportDetailPanel({ reportId, onClose, onChanged }: PanelProps): ReactElement {
  const { api } = useSession();
  const { state, reload } = useAsync(() => api.get<ReportDetailDto>(`/reports/${reportId}`), [api, reportId]);
  const [result, setResult] = useState<DecisionResultDto | null>(null);
  return (
    <Drawer title={`Signalement n°\u00A0${reportId}`} eyebrow={state.status === "ok" ? `Contre ${memberName(state.data.reported)}` : "Signalement"} onClose={onClose}>
      {result?.appealCode !== undefined ? <AppealCodeCard code={result.appealCode} reference={result.reference} /> : null}
      {state.status === "loading" ? (
        <div className="stack" role="status" aria-label="Chargement du signalement">
          <Skeleton width="40%" height={22} radius={11} />
          <Skeleton width="70%" height={26} />
          <Skeleton height={90} radius={12} />
          <Skeleton height={140} radius={12} />
        </div>
      ) : state.status === "error" ? (
        <ErrorState message={state.message} onRetry={reload} />
      ) : (
        <Body key={state.data.id} report={state.data} onChanged={onChanged} onResult={setResult} onReload={reload} />
      )}
    </Drawer>
  );
}
