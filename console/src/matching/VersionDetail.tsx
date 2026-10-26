import type { ReactElement } from "react";
import type { MatchingStateDto, VersionPageDto } from "../shared/api/contracts";
import { formatDateTime } from "../shared/format";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Drawer } from "../shared/ui/Drawer";
import { ChangeList } from "./SaveCard";
import { diffParams } from "./specs";

interface Props {
  readonly row: VersionPageDto["versions"][number];
  readonly state: MatchingStateDto;
  readonly canTune: boolean;
  readonly onClose: () => void;
  readonly onActivate: () => void;
  readonly onAb: () => void;
  readonly onUseAsBase: () => void;
}

/** Détail d'une version : qui, quand, pourquoi, et ce qui la distingue de la version active et des valeurs par défaut. */
export function VersionDetail({ row, state, canTune, onClose, onActivate, onAb, onUseAsBase }: Props): ReactElement {
  const isActive = row.id === state.active.id;
  const isVariant = state.abTest?.variant.id === row.id;
  const vsActive = diffParams(state.active.params, row.params, state.specs);
  const vsDefaults = diffParams(state.defaults, row.params, state.specs);
  return (
    <Drawer title={`Version n°${row.id}`} eyebrow="Historique des réglages" onClose={onClose} wide>
      <div className="stack">
        <div className="panel-badges">
          {isActive ? <Badge tone="success">Active</Badge> : null}
          {isVariant ? <Badge tone="warning">Variante du test A/B</Badge> : null}
          {!isActive && !isVariant ? <Badge>{row.activatedAt === null ? "Jamais activée" : "Déjà activée"}</Badge> : null}
        </div>
        <dl className="facts-list">
          <div>
            <dt>Note</dt>
            <dd>« {row.note} »</dd>
          </div>
          <div>
            <dt>Auteur</dt>
            <dd>{row.author}</dd>
          </div>
          <div>
            <dt>Créée</dt>
            <dd>{formatDateTime(row.createdAt)}</dd>
          </div>
          <div>
            <dt>Dernière activation</dt>
            <dd>{row.activatedAt === null ? "Jamais" : formatDateTime(row.activatedAt)}</dd>
          </div>
          <div>
            <dt>Dérivée de</dt>
            <dd>{row.parentId === null ? "Valeurs d'origine" : `version n° ${row.parentId}`}</dd>
          </div>
        </dl>
        <section aria-labelledby="vd-active">
          <h3 id="vd-active">Écarts avec la version active n°&nbsp;{state.active.id}</h3>
          <p className="diff-intro">Valeur de la version active → valeur de cette version.</p>
          {isActive ? <p className="muted">C'est la version active.</p> : vsActive.length === 0 ? <p className="muted">Réglages identiques à la version active.</p> : <ChangeList changes={vsActive} />}
        </section>
        <section aria-labelledby="vd-defaults">
          <h3 id="vd-defaults">Écarts avec les valeurs par défaut</h3>
          <p className="diff-intro">Valeur par défaut → valeur de cette version.</p>
          {vsDefaults.length === 0 ? <p className="muted">Toutes les valeurs par défaut.</p> : <ChangeList changes={vsDefaults} />}
        </section>
        <div className="row-actions row-actions-start">
          <Button icon="sliders" onClick={onUseAsBase}>
            Partir de cette version dans « Régler »
          </Button>
          {canTune && !isActive ? (
            <Button variant="primary" onClick={onActivate}>
              {row.id < state.active.id ? "Revenir à cette version…" : "Activer cette version…"}
            </Button>
          ) : null}
          {canTune && !isActive && !isVariant && state.abTest === null ? <Button onClick={onAb}>Tester en A/B…</Button> : null}
        </div>
      </div>
    </Drawer>
  );
}
