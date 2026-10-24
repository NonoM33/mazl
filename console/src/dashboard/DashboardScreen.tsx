import type { ReactElement } from "react";
import { useSession } from "../app/session";
import type { DashboardDto, Priority, SanctionKind } from "../shared/api/contracts";
import { formatHours, formatNumber, relativeTime } from "../shared/format";
import { PRIORITY_LABELS, PRIORITY_ORDER, SANCTION_LABELS, SANCTION_ORDER } from "../shared/labels";
import { PRIORITY_VAR } from "../shared/ui/Badge";
import { ErrorState, Skeleton } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { Stat, StatSkeleton } from "../shared/ui/Stat";
import { useAsync } from "../shared/ui/use-async";
import { LineChart } from "./LineChart";

function BarRows({ rows }: { readonly rows: readonly { readonly key: string; readonly label: string; readonly value: number; readonly color: string }[] }): ReactElement {
  const max = Math.max(1, ...rows.map((row) => row.value));
  return (
    <ul className="bars">
      {rows.map((row) => (
        <li key={row.key} className="bar-row">
          <span className="bar-label">{row.label}</span>
          <span className="bar-track" aria-hidden="true">
            <span className="bar-fill" style={{ width: `${(row.value / max) * 100}%`, background: row.color }} />
          </span>
          <span className="bar-value">{formatNumber(row.value)}</span>
        </li>
      ))}
    </ul>
  );
}

function Content({ data }: { readonly data: DashboardDto }): ReactElement {
  const { reports } = data;
  const priorityRows = PRIORITY_ORDER.map((priority: Priority) => ({ key: priority, label: PRIORITY_LABELS[priority], value: reports.byPriority[priority], color: PRIORITY_VAR[priority] }));
  const sanctionRows = SANCTION_ORDER.map((kind: SanctionKind) => ({ key: kind, label: SANCTION_LABELS[kind], value: data.sanctions30d[kind], color: kind === "ban" ? "var(--error)" : "var(--text)" }));
  const sanctionTotal = sanctionRows.reduce((sum, row) => sum + row.value, 0);
  return (
    <>
      <section aria-label="Chiffres clés" className="stats">
        <Stat label="Ouverts" value={formatNumber(reports.open)} note={`${formatNumber(reports.receivedLast7d)} reçus en 7 j`} />
        <Stat label="En retard" value={formatNumber(reports.overdue)} tone={reports.overdue > 0 ? "error" : "neutral"} note={reports.overdue > 0 ? "Échéance dépassée" : "Aucun retard"} />
        <Stat label="Délai médian" value={formatHours(reports.medianHandlingHours30d)} note="Traitement, 30 jours" />
        <Stat label="Contestations" value={formatNumber(data.appeals.pending)} note="En attente de décision" />
        <Stat label="Vérifications" value={formatNumber(data.verification.pending)} note="Dossiers en attente" />
        <Stat label="Membres actifs" value={formatNumber(data.members.active7d)} note="Sur 7 jours" />
      </section>
      <div className="grid-2">
        <section className="card" aria-labelledby="h-priorite">
          <h2 id="h-priorite">Répartition par priorité</h2>
          <p className="card-lead">Signalements ouverts</p>
          <BarRows rows={priorityRows} />
        </section>
        <section className="card" aria-labelledby="h-sanctions">
          <h2 id="h-sanctions">Sanctions sur 30 jours</h2>
          <p className="card-lead">{formatNumber(sanctionTotal)} au total, par type</p>
          <BarRows rows={sanctionRows} />
        </section>
      </div>
      <section className="card" aria-labelledby="h-courbe">
        <h2 id="h-courbe">Signalements reçus et traités</h2>
        <p className="card-lead">30 derniers jours</p>
        <LineChart data={reports.daily} />
      </section>
      <p className="page-foot">Chiffres agrégés, sans donnée personnelle · calculés {relativeTime(data.generatedAt)}</p>
    </>
  );
}

export function DashboardScreen(): ReactElement {
  const { api } = useSession();
  const { state, reload } = useAsync(() => api.get<DashboardDto>("/dashboard"), [api]);
  return (
    <>
      <PageHeader eyebrow="Vue d'ensemble" title="Tableau de bord" />
      <div className="page-body">
        {state.status === "loading" ? (
          <div role="status" aria-label="Chargement du tableau de bord">
            <div className="stats">
              {Array.from({ length: 6 }, (_, index) => (
                <StatSkeleton key={index} />
              ))}
            </div>
            <div className="grid-2">
              <div className="card">
                <Skeleton width="40%" height={16} />
              </div>
              <div className="card">
                <Skeleton width="40%" height={16} />
              </div>
            </div>
          </div>
        ) : state.status === "error" ? (
          <ErrorState message={state.message} onRetry={reload} />
        ) : (
          <Content data={state.data} />
        )}
      </div>
    </>
  );
}
