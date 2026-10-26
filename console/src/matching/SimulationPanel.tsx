import { useEffect, useRef, useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import type { MatchingParams, MatchProfile, PreviewResponse, RankedCandidate, RankingResult } from "../shared/api/contracts";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Field } from "../shared/ui/Field";
import { Select } from "../shared/ui/Select";
import { ScoreDetail, formatScore } from "./ScoreDetail";
import { DEFAULT_PREVIEW_SIZE, PREVIEW_SIZES, previewBody } from "./requests";
import { EXCLUSION_LABELS, exclusionCounts, labelOf, movementOf, movementText, sameRanking, droppedOut } from "./simulation";

const DEBOUNCE_MS = 350;
const SHOWN = 12;
const WINDOW = 30;

type Run =
  | { readonly status: "idle"; readonly reason: string }
  | { readonly status: "loading"; readonly previous: PreviewResponse | null }
  | { readonly status: "error"; readonly message: string; readonly previous: PreviewResponse | null }
  | { readonly status: "ok"; readonly response: PreviewResponse };

interface Props {
  readonly draft: MatchingParams;
  readonly active: MatchingParams;
  readonly activeId: number;
  /** Réglages valides ? Sinon la simulation attend. */
  readonly draftValid: boolean;
}

function viewerLine(viewer: MatchProfile, response: PreviewResponse): string {
  const { name, city } = labelOf(response, viewer.userId);
  const bits = [viewer.age === null ? null : `${viewer.age} ans`, `cherche ${viewer.ageMin}–${viewer.ageMax} ans`, viewer.denomination, viewer.distanceMaxKm === null ? "sans limite de distance" : `jusqu'à ${viewer.distanceMaxKm} km`];
  return `${name}, ${city} · ${bits.filter((bit) => bit !== null && bit !== "").join(" · ")}`;
}

function Column({
  title,
  response,
  result,
  reference,
  selected,
  onSelect,
  showAll,
}: {
  readonly title: string;
  readonly response: PreviewResponse;
  readonly result: RankingResult;
  readonly reference: RankingResult | null;
  readonly selected: number | null;
  readonly onSelect: (userId: number) => void;
  readonly showAll: boolean;
}): ReactElement {
  const rows = result.ranked.slice(0, showAll ? WINDOW : SHOWN);
  return (
    <section className="sim-col" aria-label={title}>
      <h4>{title}</h4>
      <ol className="sim-list">
        {rows.map((candidate: RankedCandidate) => {
          const { name, city } = labelOf(response, candidate.userId);
          const move = movementOf(candidate, reference);
          return (
            <li key={candidate.userId}>
              <button type="button" className={`sim-row${selected === candidate.userId ? " is-selected" : ""}`} aria-pressed={selected === candidate.userId} onClick={() => onSelect(candidate.userId)}>
                <span className="sim-rank">{candidate.rank}</span>
                <span className="sim-who">
                  <span className="sim-name">{name}</span>
                  <span className="sim-city">{city}</span>
                </span>
                <span className="sim-score">{formatScore(candidate.score)}</span>
                <span className="sim-flags">
                  {candidate.explored ? <Badge tone="warning">Exploration</Badge> : null}
                  {reference !== null && move.kind !== "same" ? (
                    <span className={`sim-move sim-move-${move.kind}`}>
                      <span aria-hidden="true">{move.kind === "up" ? `▲${move.places}` : move.kind === "down" ? `▼${move.places}` : "●"}</span>
                      <span className="sr-only">{movementText(move)}</span>
                    </span>
                  ) : null}
                </span>
              </button>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

/** Simulation en direct : les réglages en cours contre la version active, sur des membres FICTIFS du serveur. */
export function SimulationPanel({ draft, active, activeId, draftValid }: Props): ReactElement {
  const { api } = useSession();
  const [seedText, setSeedText] = useState("42");
  const [indexText, setIndexText] = useState("0");
  const [size, setSize] = useState(DEFAULT_PREVIEW_SIZE);
  const [run, setRun] = useState<Run>({ status: "idle", reason: "Préparation de la simulation…" });
  const [selected, setSelected] = useState<number | null>(null);
  const [showAll, setShowAll] = useState(false);
  const latest = useRef(0);
  const body = previewBody(draft, active, { seedText, indexText, size });
  const inputError = body.ok ? null : body.error;
  const key = JSON.stringify(body.ok ? body.value : null);

  useEffect(() => {
    if (!body.ok) {
      setRun({ status: "idle", reason: body.error });
      return;
    }
    if (!draftValid) {
      setRun((current) => ({ status: "idle", reason: current.status === "ok" ? "Corrigez les réglages signalés en rouge pour relancer la simulation." : "Corrigez les réglages signalés en rouge pour lancer la simulation." }));
      return;
    }
    latest.current += 1;
    const mine = latest.current;
    setRun((current) => ({ status: "loading", previous: current.status === "ok" ? current.response : current.status === "loading" || current.status === "error" ? current.previous : null }));
    const timer = window.setTimeout(() => {
      void api.post<PreviewResponse>("/matching/preview", body.value).then((result) => {
        if (mine !== latest.current) return;
        setRun((current) =>
          result.ok
            ? { status: "ok", response: result.data }
            : { status: "error", message: result.message, previous: current.status === "loading" ? current.previous : null },
        );
      });
    }, DEBOUNCE_MS);
    return () => window.clearTimeout(timer);
    // `key` résume le contenu de la requête ; `body` en est dérivé à chaque rendu.
  }, [api, key, draftValid]);

  const shown = run.status === "ok" ? run.response : run.status === "loading" || run.status === "error" ? run.previous : null;
  const randomize = (): void => {
    setSeedText(String(Math.floor(Math.random() * 100_000)));
    setIndexText(String(Math.floor(Math.random() * size)));
    setSelected(null);
  };
  const result = shown?.result ?? null;
  const compare = shown?.compare ?? null;
  const chosen = result?.ranked.find((item) => item.userId === selected) ?? null;
  const chosenBefore = compare?.ranked.find((item) => item.userId === selected) ?? null;
  const dropped = result !== null ? droppedOut(result, compare, showAll ? WINDOW : SHOWN) : [];

  return (
    <section className="card sim" aria-labelledby="sim-title">
      <div className="card-head">
        <h2 id="sim-title">Simulation en direct</h2>
        <span className="row-actions">
          {run.status === "loading" ? (
            <span className="muted sim-busy" role="status">
              <span className="spinner" aria-hidden="true" /> Calcul…
            </span>
          ) : null}
          <Button size="s" icon="refresh" onClick={randomize}>
            Au hasard
          </Button>
        </span>
      </div>
      <p className="card-lead">Classement d'un membre fictif avec vos réglages, face à la version active n°&nbsp;{activeId}. Population entièrement inventée par le serveur : aucun vrai membre n'est utilisé.</p>
      <div className="sim-controls">
        <Field label="Graine" hint="Même graine, mêmes personnes.">
          {({ id, describedBy }) => <input id={id} className="input" inputMode="numeric" value={seedText} aria-describedby={describedBy} aria-invalid={inputError !== null && inputError.startsWith("Graine") ? true : undefined} onChange={(event) => setSeedText(event.target.value)} />}
        </Field>
        <Field label={`Membre (0 à ${size - 1})`} hint="Position du membre dans la population.">
          {({ id, describedBy }) => <input id={id} className="input" inputMode="numeric" value={indexText} aria-describedby={describedBy} aria-invalid={inputError !== null && inputError.startsWith("Index") ? true : undefined} onChange={(event) => setIndexText(event.target.value)} />}
        </Field>
        <Select
          label="Population"
          value={String(size)}
          options={PREVIEW_SIZES.map((value) => ({ value: String(value), label: `${value} pers.` }))}
          onChange={(value) => value !== "" && setSize(Number(value))}
        />
      </div>
      {inputError !== null ? (
        <p className="field-error" role="alert">
          {inputError}
        </p>
      ) : null}
      {run.status === "idle" && run.reason !== inputError ? (
        <p className="notice notice-warning" role="status">
          {run.reason}
        </p>
      ) : null}
      {run.status === "error" ? (
        <p className="notice notice-error" role="alert">
          <strong>Simulation impossible.</strong> {run.message}
        </p>
      ) : null}
      {shown === null || result === null ? (
        run.status === "loading" ? (
          <p className="muted" role="status">Calcul du classement…</p>
        ) : null
      ) : (
        <>
          <p className="sim-viewer">
            <span className="eyebrow">Membre fictif</span>
            {viewerLine(shown.viewer, shown)}
          </p>
          <p className="muted sim-excl">
            {result.exclusions.length} profil{result.exclusions.length > 1 ? "s" : ""} écarté{result.exclusions.length > 1 ? "s" : ""} sur {shown.population.length}
            {exclusionCounts(result).length > 0 ? ` (${exclusionCounts(result).map((row) => `${row.count} ${EXCLUSION_LABELS[row.reason]}`).join(", ")})` : ""}. {result.ranked.length} profil{result.ranked.length > 1 ? "s" : ""} classé{result.ranked.length > 1 ? "s" : ""}, dont les {WINDOW} premiers servent de page.
          </p>
          {compare !== null && sameRanking(result, compare) ? (
            <p className="notice notice-info" role="status">
              Vos réglages donnent exactement le même classement que la version active pour ce membre.
            </p>
          ) : null}
          <div className="sim-cols">
            {compare !== null ? <Column title={`Version active n°${activeId}`} response={shown} result={compare} reference={null} selected={selected} onSelect={setSelected} showAll={showAll} /> : null}
            <Column title="Vos réglages" response={shown} result={result} reference={compare} selected={selected} onSelect={setSelected} showAll={showAll} />
          </div>
          <div className="sim-more">
            <Button size="s" variant="ghost" onClick={() => setShowAll((value) => !value)}>
              {showAll ? `Réduire aux ${SHOWN} premiers` : `Afficher les ${WINDOW} premiers`}
            </Button>
            <span className="muted">▲ monte · ▼ descend · ● entre dans la page, par rapport à la version active. Cliquez un profil pour voir son score.</span>
          </div>
          {dropped.length > 0 ? (
            <p className="muted sim-dropped">
              Sortent de la liste avec vos réglages : {dropped.map((item) => labelOf(shown, item.userId).name).join(", ")}.
            </p>
          ) : null}
          {selected !== null ? (
            <div className="sim-detail">
              <h3>
                Détail du score : {labelOf(shown, selected).name}, {labelOf(shown, selected).city}
              </h3>
              <div className="sim-detail-cols">
                {compare !== null ? (
                  chosenBefore !== null ? (
                    <ScoreDetail candidate={chosenBefore} heading={`Version active n°${activeId}`} />
                  ) : (
                    <p className="muted">Hors des {WINDOW} premiers de la version active.</p>
                  )
                ) : null}
                {chosen !== null ? <ScoreDetail candidate={chosen} heading="Vos réglages" /> : <p className="muted">Hors des {WINDOW} premiers avec vos réglages.</p>}
              </div>
            </div>
          ) : null}
        </>
      )}
    </section>
  );
}
