import { useState, type ReactElement } from "react";
import { buildHash } from "../app/router";
import { can } from "../app/permissions";
import { useMe, useSession } from "../app/session";
import { navigate } from "../app/use-route";
import type { MatchingParams, MatchingStateDto } from "../shared/api/contracts";
import { ErrorState, Skeleton } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { Tabs, tabButtonId, tabPanelId } from "../shared/ui/Tabs";
import { useAsync } from "../shared/ui/use-async";
import { HistoryTab } from "./HistoryTab";
import { ALGORITHM_TABS, type AlgorithmTab } from "./tabs";
import { TuneTab } from "./TuneTab";
import { UnderstandTab } from "./UnderstandTab";

const PREFIX = "algo";

function Loading(): ReactElement {
  return (
    <div className="stack" role="status" aria-label="Chargement des réglages du moteur">
      <div className="card">
        <Skeleton width="30%" height={18} />
      </div>
      <div className="card">
        <Skeleton width="50%" height={14} />
      </div>
    </div>
  );
}

export function AlgorithmScreen({ tab }: { readonly tab: AlgorithmTab }): ReactElement {
  const { api } = useSession();
  const me = useMe();
  const canTune = can(me, "matching.tune");
  const { state, reload } = useAsync(() => api.get<MatchingStateDto>("/matching"), [api]);
  // Réglages en cours d'édition ; null = ceux de la version active. Conservés quand on change d'onglet.
  const [draft, setDraft] = useState<MatchingParams | null>(null);
  const select = (next: AlgorithmTab): void => navigate(buildHash("algorithme", null, { onglet: next }));
  return (
    <>
      <PageHeader eyebrow="Rencontres" title="Algorithme" lead="Comprenez comment le moteur classe les profils, essayez d'autres réglages sur des membres fictifs, puis publiez une version. Chaque changement est daté, signé et réversible." />
      <div className="page-body">
        <Tabs label="Sections de l'algorithme" prefix={PREFIX} tabs={ALGORITHM_TABS} active={tab} onSelect={select} />
        <div role="tabpanel" id={tabPanelId(PREFIX)} aria-labelledby={tabButtonId(PREFIX, tab)} className="tabpanel">
          {state.status === "loading" ? (
            <Loading />
          ) : state.status === "error" ? (
            <ErrorState message={state.message} onRetry={reload} />
          ) : tab === "comprendre" ? (
            <UnderstandTab state={state.data} />
          ) : tab === "regler" ? (
            <TuneTab
              state={state.data}
              canTune={canTune}
              draft={draft ?? state.data.active.params}
              onDraft={setDraft}
              onReset={() => setDraft(null)}
              onChanged={reload}
            />
          ) : (
            <HistoryTab
              state={state.data}
              canTune={canTune}
              onChanged={reload}
              onUseAsBase={(params) => {
                setDraft(params);
                select("regler");
              }}
            />
          )}
        </div>
      </div>
    </>
  );
}
