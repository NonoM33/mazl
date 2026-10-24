import { useState, type ReactElement } from "react";
import { can } from "../app/permissions";
import { buildHash } from "../app/router";
import { useMe, useSession } from "../app/session";
import { AppealCodeCard } from "../sanctions/AppealCodeCard";
import { DecisionForm } from "../sanctions/DecisionForm";
import { toMemberSanctionBody, type DecisionForm as FormState } from "../sanctions/form-model";
import type { ApiResult } from "../shared/api/client";
import type { DecisionResultDto, MemberFileDto, ReportListItemDto, SanctionDto } from "../shared/api/contracts";
import { formatAccountAge, formatDate, formatDateTime, formatNumber, memberName, relativeTime } from "../shared/format";
import { GROUND_LABELS, REASON_LABELS, SANCTION_LABELS, STATUS_LABELS, VERIFICATION_LABELS } from "../shared/labels";
import { Badge, PriorityBadge } from "../shared/ui/Badge";
import { BlurredImage } from "../shared/ui/BlurredImage";
import { Button } from "../shared/ui/Button";
import { Drawer } from "../shared/ui/Drawer";
import { EmptyState, ErrorState, Skeleton } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { SignalList } from "../shared/ui/SignalList";
import { Stat } from "../shared/ui/Stat";
import { Table, type Column } from "../shared/ui/Table";
import { navigate } from "../app/use-route";
import { useAsync } from "../shared/ui/use-async";

const reportColumns: readonly Column<ReportListItemDto>[] = [
  { key: "priority", header: "Priorité", width: "130px", render: (row) => <PriorityBadge priority={row.priority} /> },
  { key: "reason", header: "Motif", render: (row) => REASON_LABELS[row.reason] },
  { key: "status", header: "Statut", render: (row) => STATUS_LABELS[row.status] },
  { key: "date", header: "Reçu", render: (row) => relativeTime(row.createdAt) },
];

function SanctionItem({ sanction }: { readonly sanction: SanctionDto }): ReactElement {
  const { statement } = sanction;
  const active = sanction.revokedAt === null && (sanction.endsAt === null || Date.parse(sanction.endsAt) > Date.now());
  return (
    <li className="sanction-item">
      <div className="sanction-head">
        <strong>{SANCTION_LABELS[sanction.kind]}</strong>
        <Badge tone={sanction.revokedAt !== null ? "neutral" : active ? "warning" : "neutral"}>{sanction.revokedAt !== null ? "Révoquée" : active ? "En cours" : "Terminée"}</Badge>
        <span className="muted">
          {GROUND_LABELS[sanction.ground]} · {formatDate(sanction.startsAt)} · par {sanction.decidedBy}
        </span>
      </div>
      {sanction.appeal !== null ? (
        <p className="muted">
          Contestation {sanction.appeal.status === "pending" ? "en attente" : sanction.appeal.status === "upheld" ? "rejetée (décision maintenue)" : "acceptée (décision annulée)"} · {relativeTime(sanction.appeal.createdAt)}
        </p>
      ) : null}
      <details className="statement-details">
        <summary>Exposé des motifs {statement.reference}</summary>
        <dl className="statement-list">
          <div>
            <dt>Portée</dt>
            <dd>{statement.scope}</dd>
          </div>
          <div>
            <dt>Faits</dt>
            <dd>{statement.facts}</dd>
          </div>
          <div>
            <dt>Fondement</dt>
            <dd>{statement.groundText}</dd>
          </div>
          <div>
            <dt>Voies de recours</dt>
            <dd>{statement.redress}</dd>
          </div>
        </dl>
      </details>
    </li>
  );
}

function File({ file, onSanction }: { readonly file: MemberFileDto; readonly onSanction: () => void }): ReactElement {
  const me = useMe();
  const { member } = file;
  const name = memberName(member);
  return (
    <>
      {file.activeSanction !== null ? (
        <div className="notice notice-warning" role="status">
          <strong>{SANCTION_LABELS[file.activeSanction.kind]} en cours</strong>
          {file.activeSanction.endsAt !== null ? ` jusqu'au ${formatDate(file.activeSanction.endsAt)}` : ""} · {file.activeSanction.statement.scope}
        </div>
      ) : null}

      <section className="stats stats-4" aria-label="Statistiques du membre">
        <Stat label="Matchs" value={formatNumber(file.stats.matches)} />
        <Stat label="Blocages reçus" value={formatNumber(file.stats.blocksReceived)} tone={file.stats.blocksReceived >= 3 ? "warning" : "neutral"} />
        <Stat label="J'aime reçus, 7 j" value={formatNumber(file.stats.likesReceived7d)} />
        <Stat label="Signalements faits" value={formatNumber(file.reportsMade)} />
      </section>

      <div className="grid-member">
        <section className="card" aria-labelledby="h-identite">
          <h2 id="h-identite">Identité</h2>
          <div className="photo-strip">
            {member.photos.length === 0 ? <p className="muted">Aucune photo.</p> : member.photos.map((photo, index) => <BlurredImage key={photo} src={photo} name={`${name}, photo ${index + 1}`} size={88} />)}
          </div>
          <p className="photo-note">Photos floutées par défaut : cliquez pour afficher.</p>
          <dl className="facts facts-wide">
            <div>
              <dt>Adresse e-mail</dt>
              <dd>{member.email}</dd>
            </div>
            <div>
              <dt>Âge</dt>
              <dd>{member.age === null ? "—" : `${member.age} ans`}</dd>
            </div>
            <div>
              <dt>Ville</dt>
              <dd>{member.city ?? "—"}</dd>
            </div>
            <div>
              <dt>Genre</dt>
              <dd>{member.gender ?? "—"}</dd>
            </div>
            <div>
              <dt>Pratique</dt>
              <dd>{member.denomination ?? "—"}</dd>
            </div>
            <div>
              <dt>Vérification</dt>
              <dd>{VERIFICATION_LABELS[member.verification]}</dd>
            </div>
            <div>
              <dt>Inscription</dt>
              <dd>{formatDate(member.createdAt)}</dd>
            </div>
            <div>
              <dt>Dernière activité</dt>
              <dd>{member.lastActiveAt === null ? "—" : relativeTime(member.lastActiveAt)}</dd>
            </div>
          </dl>
          {member.bio !== null ? <blockquote className="quote">{member.bio}</blockquote> : null}
        </section>

        <section className="card" aria-labelledby="h-signaux">
          <h2 id="h-signaux">Signaux de risque</h2>
          <SignalList signals={file.riskSignals} />
          <p className="muted signal-foot">Les signaux sont indicatifs : aucun ne décide seul.</p>
        </section>
      </div>

      <section className="card" aria-labelledby="h-signalements">
        <h2 id="h-signalements">Signalements reçus · {file.reportsReceived.length}</h2>
        {file.reportsReceived.length === 0 ? (
          <p className="muted">Aucun signalement reçu.</p>
        ) : (
          <Table caption="Signalements reçus par le membre" columns={reportColumns} rows={file.reportsReceived} rowKey={(row) => row.id} onRowActivate={(row) => navigate(buildHash("signalements", row.id))} />
        )}
      </section>

      <section className="card" aria-labelledby="h-sanctions">
        <div className="card-head">
          <h2 id="h-sanctions">Sanctions · {file.sanctions.length}</h2>
          {can(me, "sanctions.apply") ? (
            <Button variant="primary" size="s" onClick={onSanction}>
              Sanctionner
            </Button>
          ) : null}
        </div>
        {file.sanctions.length === 0 ? <p className="muted">Aucune sanction.</p> : <ul className="sanctions">{file.sanctions.map((sanction) => <SanctionItem key={sanction.id} sanction={sanction} />)}</ul>}
      </section>
      <p className="page-foot">Dernière activité {member.lastActiveAt === null ? "inconnue" : formatDateTime(member.lastActiveAt)} · ancienneté {formatAccountAge(Math.max(0, Math.round((Date.now() - Date.parse(member.createdAt)) / 86_400_000)))}</p>
    </>
  );
}

export function MemberFileScreen({ memberId }: { readonly memberId: number }): ReactElement {
  const me = useMe();
  const { api } = useSession();
  const { state, reload } = useAsync(() => api.get<MemberFileDto>(`/members/${memberId}`), [api, memberId]);
  const [sanctioning, setSanctioning] = useState(false);
  const [result, setResult] = useState<DecisionResultDto | null>(null);

  const submit = async (form: FormState): Promise<ApiResult<DecisionResultDto>> => {
    const body = toMemberSanctionBody(form);
    if (body === null) return { ok: false, status: 0, code: "invalid", message: "Formulaire incomplet." };
    return api.post<DecisionResultDto>(`/members/${memberId}/sanctions`, body);
  };

  return (
    <>
      <PageHeader
        eyebrow="Fiche membre"
        title={state.status === "ok" ? memberName(state.data.member) : `Membre n° ${memberId}`}
        actions={
          <a className="btn btn-secondary btn-m" href={buildHash("membres")}>
            Retour à la recherche
          </a>
        }
      />
      <div className="page-body">
        {result?.appealCode !== undefined ? <AppealCodeCard code={result.appealCode} reference={result.reference} /> : null}
        {state.status === "loading" ? (
          <div className="stack" role="status" aria-label="Chargement de la fiche">
            <Skeleton height={90} radius={14} />
            <Skeleton height={260} radius={14} />
          </div>
        ) : state.status === "error" ? (
          state.code === "not_found" ? (
            <EmptyState icon="users" title="Membre introuvable">
              Ce numéro ne correspond à aucun membre.
            </EmptyState>
          ) : (
            <ErrorState message={state.message} onRetry={reload} />
          )
        ) : (
          <File file={state.data} onSanction={() => setSanctioning(true)} />
        )}
      </div>
      {sanctioning ? (
        <Drawer title="Sanctionner le membre" eyebrow={`Membre n° ${memberId}`} onClose={() => setSanctioning(false)}>
          <DecisionForm
            mode="member"
            suggested={null}
            canBan={can(me, "sanctions.ban")}
            canSanction={can(me, "sanctions.apply")}
            onSubmit={submit}
            onDone={(done) => {
              setResult(done);
              setSanctioning(false);
              reload();
            }}
          />
        </Drawer>
      ) : null}
    </>
  );
}
