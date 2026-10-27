import { useMemo, useState, type ReactElement } from "react";
import { buildHash } from "../app/router";
import { useSession } from "../app/session";
import { navigate } from "../app/use-route";
import { formatNumber } from "../shared/format";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { EmptyState, ErrorState, SkeletonRows } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { Select } from "../shared/ui/Select";
import { Table, type Column } from "../shared/ui/Table";
import { tabButtonId, tabPanelId, Tabs } from "../shared/ui/Tabs";
import { useAsync } from "../shared/ui/use-async";
import { CONCIERGE_CHANGED, conciergeApi } from "./api";
import { formatCoupleDuration, formatWantedDay } from "./dates";
import { RequestPanel } from "./RequestPanel";
import { inTab, isUrgent, sortByUrgency, STATUS_LABELS, STATUS_TONES, tabCounts, tabStatuses, TABS, type TabId } from "./status";
import type { RequestListItemDto, RequestStatus } from "./types";

const EMPTY_TEXT: Readonly<Record<TabId, string>> = {
  todo: "Aucune demande nouvelle ni idée choisie à confirmer. L'équipe est à jour.",
  ongoing: "Aucune demande en cours : rien n'attend une réponse du couple ni une date de réservation.",
  done: "Aucune demande terminée pour l'instant.",
};

function columnsFor(now: Date): readonly Column<RequestListItemDto>[] {
  return [
    {
      key: "couple",
      header: "Couple",
      width: "24%",
      render: (row) => (
        <span className="cell-stack">
          <strong>{row.couple.firstNames.join(" & ")}</strong>
          <span className="cell-sub">ensemble depuis {formatCoupleDuration(row.couple.months)}</span>
        </span>
      ),
    },
    {
      key: "title",
      header: "Demande",
      width: "34%",
      render: (row) => (
        <span className="cell-stack">
          <span>{row.title}</span>
          <span className="cell-sub">{row.assignedTo === null ? "Non assignée" : `Assignée à ${row.assignedTo}`}</span>
        </span>
      ),
    },
    {
      key: "wanted",
      header: "Pour le",
      width: "16%",
      render: (row) => (
        <span className="cell-stack">
          <span>{formatWantedDay(row.wantedAt)}</span>
          {isUrgent(row, now) ? <span className="urgent-flag">Urgent</span> : null}
        </span>
      ),
    },
    {
      key: "state",
      header: "État",
      render: (row) => (
        <Badge tone={STATUS_TONES[row.status]}>
          <span className="status-dot" aria-hidden="true" />
          {STATUS_LABELS[row.status]}
        </Badge>
      ),
    },
  ];
}

export function ConciergeScreen({ selectedId, tab }: { readonly selectedId: number | null; readonly tab: TabId }): ReactElement {
  const { api } = useSession();
  const store = conciergeApi(api);
  const [statusFilter, setStatusFilter] = useState<RequestStatus | "">("");
  const { state, reload } = useAsync(() => store.list(), [api]);
  const now = new Date();

  const all: readonly RequestListItemDto[] = state.status === "ok" ? state.data.requests : [];
  const counts = tabCounts(all);
  const rows = useMemo(() => {
    const inside = inTab(all, tab);
    return sortByUrgency(statusFilter === "" ? inside : inside.filter((row) => row.status === statusFilter), new Date());
  }, [all, tab, statusFilter]);

  const go = (nextTab: TabId, id: number | null): void => navigate(buildHash("conciergerie", id, { onglet: nextTab }));
  const statuses = tabStatuses(tab);

  return (
    <>
      <PageHeader
        eyebrow="MAZL Couple"
        title="Conciergerie"
        lead="Les demandes des couples abonnés. L'assistant propose trois idées au plus ; c'est l'équipe qui confirme et réserve. Vos demandes sont lues par un assistant automatique puis par l'équipe MAZL."
        actions={
          <Button icon="refresh" onClick={reload}>
            Actualiser
          </Button>
        }
      />
      <div className="page-body">
        <Tabs
          label="État des demandes"
          prefix="concierge"
          tabs={TABS.map((entry) => ({ id: entry.id, label: `${entry.label}${state.status === "ok" ? ` · ${formatNumber(counts[entry.id])}` : ""}` }))}
          active={tab}
          onSelect={(next) => {
            setStatusFilter("");
            go(next, null);
          }}
        />
        <div className="filters filters-single" role="search" aria-label="Filtre des demandes">
          <Select
            label="Statut"
            compact
            value={statusFilter}
            placeholder="Tous les statuts de l'onglet"
            options={statuses.map((value) => ({ value, label: STATUS_LABELS[value] }))}
            onChange={setStatusFilter}
          />
        </div>
        <div role="tabpanel" id={tabPanelId("concierge")} aria-labelledby={tabButtonId("concierge", tab)} className="stack">
          {state.status === "loading" ? <SkeletonRows rows={6} label="Chargement des demandes" /> : null}
          {state.status === "error" ? <ErrorState message={state.message} onRetry={reload} /> : null}
          {state.status === "ok" && rows.length === 0 ? (
            <EmptyState icon="check" title="Rien à afficher">
              {statusFilter === "" ? EMPTY_TEXT[tab] : "Aucune demande ne correspond à ce statut dans cet onglet."}
            </EmptyState>
          ) : null}
          {state.status === "ok" && rows.length > 0 ? (
            <Table caption={`Demandes de conciergerie : ${TABS.find((entry) => entry.id === tab)?.label ?? ""}`} columns={columnsFor(now)} rows={rows} rowKey={(row) => row.id} selectedKey={selectedId} onRowActivate={(row) => go(tab, row.id)} />
          ) : null}
        </div>
      </div>
      {selectedId !== null ? <RequestPanel key={selectedId} requestId={selectedId} onClose={() => go(tab, null)} onChanged={() => {
          reload();
          window.dispatchEvent(new Event(CONCIERGE_CHANGED));
        }} /> : null}
    </>
  );
}
