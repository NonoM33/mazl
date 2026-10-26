import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import type { MatchingParams, MatchingStateDto, VersionPageDto } from "../shared/api/contracts";
import { formatDateTime, formatNumber, relativeTime } from "../shared/format";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { EmptyState, ErrorState, SkeletonRows } from "../shared/ui/Feedback";
import { Table, type Column } from "../shared/ui/Table";
import { useAsync } from "../shared/ui/use-async";
import { AbStartModal, AbStopModal, ActivateModal } from "./HistoryDialogs";
import { VersionDetail } from "./VersionDetail";

type Row = VersionPageDto["versions"][number];
const PAGE = 15;

interface Props {
  readonly state: MatchingStateDto;
  readonly canTune: boolean;
  readonly onChanged: () => void;
  readonly onUseAsBase: (params: MatchingParams) => void;
}

type Dialog =
  | { readonly kind: "detail"; readonly row: Row }
  | { readonly kind: "activate"; readonly row: Row }
  | { readonly kind: "ab-start"; readonly variantId: number | null }
  | { readonly kind: "ab-stop" }
  | null;

function AbCard({ state, canTune, onStart, onStop }: { readonly state: MatchingStateDto; readonly canTune: boolean; readonly onStart: () => void; readonly onStop: () => void }): ReactElement {
  const { abTest, active } = state;
  return (
    <section className="card" aria-labelledby="h-ab">
      <div className="card-head">
        <h2 id="h-ab">Test A/B</h2>
        {abTest === null ? <Badge>Aucun test en cours</Badge> : <Badge tone="warning">En cours</Badge>}
      </div>
      {abTest === null ? (
        <p className="card-lead">Faites classer une part des membres (1 à 50 %) avec une autre version, sans toucher à la version active n°&nbsp;{active.id}. La part est fixée par le numéro du membre : un membre voit toujours la même version pendant le test.</p>
      ) : (
        <div className="stack">
          <p>
            <strong>{abTest.sharePercent}&nbsp;% des membres</strong> sont classés avec la version n°&nbsp;{abTest.variant.id} ; les autres avec la version active n°&nbsp;{active.id}.
          </p>
          <p className="muted">
            Lancé par {abTest.startedBy}, {relativeTime(abTest.startedAt)} ({formatDateTime(abTest.startedAt)}). Note de la variante : « {abTest.variant.note} »
          </p>
        </div>
      )}
      {canTune ? (
        <div className="row-actions row-actions-start ab-actions">
          {abTest === null ? (
            <Button icon="chart" onClick={onStart}>
              Démarrer un test A/B
            </Button>
          ) : (
            <Button variant="danger" onClick={onStop}>
              Arrêter le test
            </Button>
          )}
        </div>
      ) : null}
    </section>
  );
}

export function HistoryTab({ state, canTune, onChanged, onUseAsBase }: Props): ReactElement {
  const { api } = useSession();
  const [offset, setOffset] = useState(0);
  const [dialog, setDialog] = useState<Dialog>(null);
  const { state: list, reload } = useAsync(() => api.get<VersionPageDto>("/matching/versions", { limit: PAGE, offset }), [api, offset]);
  const abVariantId = state.abTest?.variant.id ?? null;
  const done = (): void => {
    setDialog(null);
    reload();
    onChanged();
  };

  const columns: readonly Column<Row>[] = [
    { key: "id", header: "Version", width: "92px", render: (row) => <span className="mono">n°&nbsp;{row.id}</span> },
    { key: "note", header: "Note", width: "38%", render: (row) => row.note },
    { key: "author", header: "Auteur", width: "20%", render: (row) => row.author },
    {
      key: "created",
      header: "Créée",
      width: "16%",
      render: (row) => (
        <span className="cell-stack">
          <span>{relativeTime(row.createdAt)}</span>
          <span className="cell-sub">{formatDateTime(row.createdAt)}</span>
        </span>
      ),
    },
    {
      key: "status",
      header: "Statut",
      width: "16%",
      render: (row) =>
        row.id === state.active.id ? (
          <Badge tone="success">Active</Badge>
        ) : row.id === abVariantId ? (
          <Badge tone="warning">Test A/B</Badge>
        ) : row.activatedAt !== null ? (
          <Badge>Déjà activée</Badge>
        ) : (
          <Badge>Jamais activée</Badge>
        ),
    },
  ];

  return (
    <div className="stack">
      <AbCard state={state} canTune={canTune} onStart={() => setDialog({ kind: "ab-start", variantId: null })} onStop={() => setDialog({ kind: "ab-stop" })} />
      <section aria-labelledby="h-versions" className="stack">
        <h2 id="h-versions" className="section-title">
          Versions des réglages
        </h2>
        {list.status === "loading" ? (
          <SkeletonRows rows={5} label="Chargement de l'historique" />
        ) : list.status === "error" ? (
          <ErrorState message={list.message} onRetry={reload} />
        ) : list.data.versions.length === 0 ? (
          <EmptyState icon="log" title="Aucune version">
            Les versions enregistrées apparaîtront ici.
          </EmptyState>
        ) : (
          <>
            <Table caption="Versions des réglages du moteur" columns={columns} rows={list.data.versions} rowKey={(row) => row.id} onRowActivate={(row) => setDialog({ kind: "detail", row })} />
            <nav className="pager" aria-label="Pagination de l'historique">
              <span className="muted">
                {formatNumber(offset + 1)}–{formatNumber(Math.min(offset + PAGE, list.data.total))} sur {formatNumber(list.data.total)}
              </span>
              <span className="pager-buttons">
                <Button size="s" disabled={offset === 0} onClick={() => setOffset(Math.max(0, offset - PAGE))}>
                  Précédentes
                </Button>
                <Button size="s" disabled={offset + PAGE >= list.data.total} onClick={() => setOffset(offset + PAGE)}>
                  Suivantes
                </Button>
              </span>
            </nav>
          </>
        )}
      </section>
      {dialog?.kind === "detail" ? (
        <VersionDetail
          row={dialog.row}
          state={state}
          canTune={canTune}
          onClose={() => setDialog(null)}
          onActivate={() => setDialog({ kind: "activate", row: dialog.row })}
          onAb={() => setDialog({ kind: "ab-start", variantId: dialog.row.id })}
          onUseAsBase={() => onUseAsBase(dialog.row.params)}
        />
      ) : null}
      {dialog?.kind === "activate" ? <ActivateModal version={dialog.row} activeId={state.active.id} onClose={() => setDialog(null)} onDone={done} /> : null}
      {dialog?.kind === "ab-start" ? (
        <AbStartModal
          versions={list.status === "ok" ? list.data.versions : []}
          activeId={state.active.id}
          initial={dialog.variantId}
          onClose={() => setDialog(null)}
          onDone={done}
        />
      ) : null}
      {dialog?.kind === "ab-stop" && state.abTest !== null ? <AbStopModal variantId={state.abTest.variant.id} onClose={() => setDialog(null)} onDone={done} /> : null}
    </div>
  );
}
