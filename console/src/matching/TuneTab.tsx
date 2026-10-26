import type { ReactElement } from "react";
import type { MatchingParams, MatchingStateDto, ReciprocityMode } from "../shared/api/contracts";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Select } from "../shared/ui/Select";
import { RECIPROCITY_LABELS, RECIPROCITY_ORDER, diffParams, groupSpecs, hasErrors, readValue, validateDraft, writeValue } from "./specs";
import { weightShares } from "./explain";
import { ChangeList, SaveCard } from "./SaveCard";
import { SimulationPanel } from "./SimulationPanel";
import { SpecField } from "./SpecField";

interface Props {
  readonly state: MatchingStateDto;
  readonly canTune: boolean;
  readonly draft: MatchingParams;
  readonly onDraft: (params: MatchingParams) => void;
  /** Revient aux réglages de la version active. */
  readonly onReset: () => void;
  readonly onChanged: () => void;
}

const pct = (ratio: number): string => `${new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 }).format(ratio * 100)} %`;

function ReciprocityCard({ draft, active, onDraft }: { readonly draft: MatchingParams; readonly active: MatchingParams; readonly onDraft: (params: MatchingParams) => void }): ReactElement {
  const options = RECIPROCITY_ORDER.map((value) => ({ value, label: RECIPROCITY_LABELS[value] }));
  return (
    <section className="card" aria-labelledby="g-reciprocity">
      <h2 id="g-reciprocity">Réciprocité et filtres</h2>
      <p className="card-lead">Comment fusionner les deux sens du score, et si l'âge et la distance souhaités par le candidat comptent aussi.</p>
      <div className="stack">
        <Select<ReciprocityMode>
          label="Mode de réciprocité"
          value={draft.reciprocity.mode}
          options={options}
          onChange={(mode) => mode !== "" && onDraft({ ...draft, reciprocity: { mode } })}
          hint={draft.reciprocity.mode !== active.reciprocity.mode ? `Version active : ${RECIPROCITY_LABELS[active.reciprocity.mode]}.` : "Harmonique : un sens faible tire fortement le résultat vers le bas."}
        />
        <label className="check check-accent">
          <input type="checkbox" checked={draft.filters.mutualAge} onChange={(event) => onDraft({ ...draft, filters: { ...draft.filters, mutualAge: event.target.checked } })} />
          <span>
            Âge réciproque : le membre doit aussi être dans la tranche d'âge du candidat
            {draft.filters.mutualAge !== active.filters.mutualAge ? <Badge tone="accent">modifié</Badge> : null}
          </span>
        </label>
        <label className="check check-accent">
          <input type="checkbox" checked={draft.filters.mutualDistance} onChange={(event) => onDraft({ ...draft, filters: { ...draft.filters, mutualDistance: event.target.checked } })} />
          <span>
            Distance réciproque : le membre doit aussi être dans la distance maximale du candidat
            {draft.filters.mutualDistance !== active.filters.mutualDistance ? <Badge tone="accent">modifié</Badge> : null}
          </span>
        </label>
      </div>
    </section>
  );
}

export function TuneTab({ state, canTune, draft, onDraft, onReset, onChanged }: Props): ReactElement {
  const { active, defaults, specs } = state;
  const groups = groupSpecs(specs);
  const errors = validateDraft(draft, specs);
  const invalid = hasErrors(errors);
  const changes = diffParams(active.params, draft, specs);
  const fromDefaults = diffParams(defaults, draft, specs);
  const shares = weightShares(draft.weights);

  return (
    <div className="tune">
      <div className="tune-form">
        {!canTune ? (
          <p className="notice notice-warning" role="status">
            <strong>Lecture seule.</strong> Votre rôle permet de lire et de simuler, pas d'enregistrer ni d'activer une version (permission « matching.tune »). Vous pouvez essayer des réglages : rien n'est conservé.
          </p>
        ) : null}
        <section className="card" aria-labelledby="g-summary">
          <div className="card-head summary-head">
            <h2 id="g-summary">Vos modifications</h2>
            <span className="row-actions">
              <Button size="s" disabled={changes.length === 0} onClick={onReset}>
                Annuler mes modifications
              </Button>
              <Button size="s" icon="refresh" disabled={fromDefaults.length === 0} onClick={() => onDraft(structuredClone(defaults))}>
                Revenir aux valeurs par défaut
              </Button>
            </span>
          </div>
          {changes.length === 0 ? (
            <p className="muted">Aucun écart avec la version active n°&nbsp;{active.id}. Déplacez un curseur : la simulation à droite se met à jour.</p>
          ) : (
            <>
              <p className="card-lead">Écarts avec la version active n°&nbsp;{active.id}.</p>
              <ChangeList changes={changes} />
            </>
          )}
          {fromDefaults.length > 0 ? <p className="muted spec-defaults">{fromDefaults.length} réglage{fromDefaults.length > 1 ? "s" : ""} diffère{fromDefaults.length > 1 ? "nt" : ""} des valeurs par défaut de la maison.</p> : <p className="muted spec-defaults">Tous les réglages sont aux valeurs par défaut.</p>}
          {errors.general.map((message) => (
            <p key={message} className="field-error" role="alert">
              {message}
            </p>
          ))}
        </section>
        {groups.map((group) => (
          <section key={group.group} className="card" aria-labelledby={`g-${group.group}`}>
            <h2 id={`g-${group.group}`}>{group.title}</h2>
            <p className="card-lead">{group.lead}</p>
            <div className="spec-list">
              {group.specs.map((spec) => {
                const value = readValue(draft, spec.path);
                const share = group.group === "weights" ? shares.find((row) => `weights.${row.criterion}` === spec.path) : undefined;
                return (
                  <SpecField
                    key={spec.path}
                    spec={spec}
                    value={value ?? Number.NaN}
                    active={readValue(active.params, spec.path)}
                    fallback={readValue(defaults, spec.path)}
                    extra={share === undefined ? undefined : `${pct(share.share)} du score`}
                    onChange={(next) => onDraft(writeValue(draft, spec.path, next))}
                  />
                );
              })}
            </div>
          </section>
        ))}
        <ReciprocityCard draft={draft} active={active.params} onDraft={onDraft} />
        {canTune ? (
          <SaveCard
            draft={draft}
            changes={changes}
            blocked={invalid}
            activeId={active.id}
            onSaved={(_version, activated) => {
              if (activated) onReset();
              onChanged();
            }}
          />
        ) : null}
      </div>
      <aside className="tune-sim" aria-label="Simulation">
        <SimulationPanel draft={draft} active={active.params} activeId={active.id} draftValid={!invalid} />
      </aside>
    </div>
  );
}
