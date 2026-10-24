import { useCallback, useEffect, useState, type ReactElement } from "react";
import { navigate } from "../app/use-route";
import { buildHash } from "../app/router";
import { useSession } from "../app/session";
import { MemberCell } from "../members/MemberCell";
import type { Priority, ReportListItemDto, ReportPageDto, ReportReason, ReportStatus } from "../shared/api/contracts";
import { dueLabel, formatNumber, relativeTime } from "../shared/format";
import { isTypingTarget, nextIndex } from "../shared/keyboard";
import { PRIORITY_LABELS, PRIORITY_ORDER, REASON_LABELS, REASON_ORDER, STATUS_LABELS, STATUS_ORDER } from "../shared/labels";
import { Badge, PriorityBadge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { EmptyState, ErrorState, SkeletonRows } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { Select } from "../shared/ui/Select";
import { Table, type Column } from "../shared/ui/Table";
import { useAsync } from "../shared/ui/use-async";
import { ReportDetailPanel } from "./ReportDetailPanel";

type Assigned = "me" | "none" | "all";
const PAGE = 25;

interface Filters {
  readonly status: ReportStatus | "";
  readonly priority: Priority | "";
  readonly assigned: Assigned;
  readonly reason: ReportReason | "";
}

const ASSIGNED_OPTIONS = [
  { value: "all", label: "Tous" },
  { value: "me", label: "À moi" },
  { value: "none", label: "Non assignés" },
] as const;

const columns: readonly Column<ReportListItemDto>[] = [
  { key: "priority", header: "Priorité", width: "118px", render: (row) => <PriorityBadge priority={row.priority} /> },
  {
    key: "reason",
    header: "Motif",
    width: "19%",
    render: (row) => (
      <span className="cell-stack">
        <span>{REASON_LABELS[row.reason]}</span>
        {row.status !== "pending" ? <span className="cell-sub">{STATUS_LABELS[row.status]}</span> : null}
      </span>
    ),
  },
  { key: "reported", header: "Membre signalé", width: "24%", render: (row) => <MemberCell member={row.reported} /> },
  { key: "age", header: "Signalé", width: "11%", render: (row) => relativeTime(row.createdAt) },
  {
    key: "due",
    header: "Échéance",
    width: "15%",
    render: (row) => {
      const due = dueLabel(row.dueAt);
      const late = row.overdue || due.late;
      return <span className={late && (row.status === "pending" || row.status === "in_review") ? "is-late" : undefined}>{due.text}</span>;
    },
  },
  { key: "assignee", header: "Assigné", width: "14%", render: (row) => row.assignedTo ?? <span className="muted">Non assigné</span> },
  { key: "others", header: "Autres", width: "8%", align: "right", render: (row) => (row.otherOpenReports > 0 ? <Badge tone="warning">+{row.otherOpenReports}</Badge> : <span className="muted">—</span>) },
];

export function ReportsScreen({ selectedId }: { readonly selectedId: number | null }): ReactElement {
  const { api } = useSession();
  const [filters, setFilters] = useState<Filters>({ status: "", priority: "", assigned: "all", reason: "" });
  const [offset, setOffset] = useState(0);
  const { state, reload } = useAsync(
    () => api.get<ReportPageDto>("/reports", { status: filters.status, priority: filters.priority, assigned: filters.assigned, reason: filters.reason, limit: PAGE, offset }),
    [api, filters, offset],
  );
  const rows = state.status === "ok" ? state.data.reports : [];

  const open = useCallback((id: number): void => navigate(buildHash("signalements", id)), []);
  const close = useCallback((): void => navigate(buildHash("signalements")), []);

  useEffect(() => {
    const onKey = (event: KeyboardEvent): void => {
      if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey || isTypingTarget(event.target)) return;
      if (event.key !== "j" && event.key !== "k") return;
      if (document.querySelector("[aria-modal='true']") !== null) return;
      const current = rows.findIndex((row) => row.id === selectedId);
      const next = rows[nextIndex(current, event.key === "j" ? 1 : -1, rows.length)];
      if (next === undefined) return;
      event.preventDefault();
      open(next.id);
      document.querySelector(`[data-row-key='${next.id}']`)?.scrollIntoView({ block: "nearest" });
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [rows, selectedId, open]);

  const update = (changes: Partial<Filters>): void => {
    setOffset(0);
    setFilters((current) => ({ ...current, ...changes }));
  };
  const total = state.status === "ok" ? state.data.total : 0;

  return (
    <>
      <PageHeader
        eyebrow="Modération"
        title="Signalements"
        lead="Triés par priorité puis par échéance. Utilisez j et k pour parcourir la file, Entrée pour ouvrir, Échap pour fermer."
        actions={
          <Button icon="refresh" onClick={reload}>
            Actualiser
          </Button>
        }
      />
      <div className="page-body">
        {state.status === "ok" ? (
          <ul className="count-chips" aria-label="Signalements ouverts par priorité">
            {PRIORITY_ORDER.map((priority) => (
              <li key={priority}>
                <PriorityBadge priority={priority} short /> <span className="chip-count">{formatNumber(state.data.counts[priority])}</span>
              </li>
            ))}
            <li className={state.data.overdue > 0 ? "is-late" : undefined}>
              <span>En retard</span> <span className="chip-count">{formatNumber(state.data.overdue)}</span>
            </li>
          </ul>
        ) : null}
        <div className="filters" role="search" aria-label="Filtres de la file">
          <Select label="Statut" compact value={filters.status} placeholder="Ouverts" options={STATUS_ORDER.map((value) => ({ value, label: STATUS_LABELS[value] }))} onChange={(status) => update({ status })} />
          <Select label="Priorité" compact value={filters.priority} placeholder="Toutes" options={PRIORITY_ORDER.map((value) => ({ value, label: PRIORITY_LABELS[value] }))} onChange={(priority) => update({ priority })} />
          <Select label="Assignation" compact value={filters.assigned} options={ASSIGNED_OPTIONS} onChange={(assigned) => update({ assigned: assigned === "" ? "all" : assigned })} />
          <Select label="Motif" compact value={filters.reason} placeholder="Tous" options={REASON_ORDER.map((value) => ({ value, label: REASON_LABELS[value] }))} onChange={(reason) => update({ reason })} />
        </div>

        {state.status === "loading" ? (
          <SkeletonRows rows={9} label="Chargement des signalements" />
        ) : state.status === "error" ? (
          <ErrorState message={state.message} onRetry={reload} />
        ) : rows.length === 0 ? (
          <EmptyState icon="check" title="Aucun signalement">
            Rien ne correspond à ces filtres. La file est à jour.
          </EmptyState>
        ) : (
          <>
            <Table caption="File des signalements" columns={columns} rows={rows} rowKey={(row) => row.id} selectedKey={selectedId} onRowActivate={(row) => open(row.id)} />
            <nav className="pager" aria-label="Pagination">
              <span className="muted">
                {formatNumber(offset + 1)}–{formatNumber(Math.min(offset + PAGE, total))} sur {formatNumber(total)}
              </span>
              <span className="pager-buttons">
                <Button size="s" disabled={offset === 0} onClick={() => setOffset(Math.max(0, offset - PAGE))}>
                  Précédents
                </Button>
                <Button size="s" disabled={offset + PAGE >= total} onClick={() => setOffset(offset + PAGE)}>
                  Suivants
                </Button>
              </span>
            </nav>
          </>
        )}
      </div>
      {selectedId !== null ? <ReportDetailPanel key={selectedId} reportId={selectedId} onClose={close} onChanged={reload} /> : null}
    </>
  );
}
