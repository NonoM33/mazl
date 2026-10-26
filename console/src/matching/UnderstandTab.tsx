import type { ReactElement, ReactNode } from "react";
import type { MatchingParams, MatchingStateDto, ScaleName } from "../shared/api/contracts";
import { formatDateTime } from "../shared/format";
import { Badge } from "../shared/ui/Badge";
import {
  CRITERION_LABELS,
  explorationSlots,
  exposureFactor,
  freshnessFactor,
  fuse,
  MULTIPLIER_LABELS,
  newcomerFactor,
  safetyFactor,
  scaleRows,
  weightShares,
} from "./explain";
import { RECIPROCITY_LABELS, RECIPROCITY_ORDER } from "./specs";

const nf = new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 2 });
const n = (value: number): string => nf.format(value);
const pct = (ratio: number): string => `${new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 1 }).format(ratio * 100)} %`;
const times = (factor: number): string => `× ${n(factor)}`;
const PAGE_SIZE_SIMULATION = 30;

function Section({ id, step, title, lead, children }: { readonly id: string; readonly step: number; readonly title: string; readonly lead: string; readonly children: ReactNode }): ReactElement {
  return (
    <section className="card explain" aria-labelledby={id}>
      <div className="explain-head">
        <span className="explain-step" aria-hidden="true">
          {step}
        </span>
        <div>
          <h2 id={id}>{title}</h2>
          <p className="card-lead">{lead}</p>
        </div>
      </div>
      {children}
    </section>
  );
}

function SampleTable({ caption, head, rows }: { readonly caption: string; readonly head: readonly string[]; readonly rows: readonly (readonly string[])[] }): ReactElement {
  return (
    <table className="mini-table">
      <caption className="sr-only">{caption}</caption>
      <thead>
        <tr>
          {head.map((cell) => (
            <th key={cell} scope="col">
              {cell}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row) => (
          <tr key={row.join("|")}>
            {row.map((cell, index) => (index === 0 ? <th key={cell} scope="row">{cell}</th> : <td key={`${index}-${cell}`}>{cell}</td>))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function Flag({ on }: { readonly on: boolean }): ReactElement {
  return <Badge tone={on ? "accent" : "neutral"}>{on ? "réciproque" : "sens unique"}</Badge>;
}

function Exclusions({ params }: { readonly params: MatchingParams }): ReactElement {
  return (
    <Section id="e-exclusions" step={1} title="Qui est écarté d'office" lead="Avant tout calcul, certains profils ne sont jamais montrés. Ce ne sont pas des scores faibles : ils n'entrent pas dans le classement.">
      <ul className="rules">
        <li>
          <strong>Personnes déjà vues ou bloquées</strong>, le membre lui-même et les comptes fermés : écartés quels que soient les réglages.
        </li>
        <li>
          <strong>Genre recherché</strong> : chacun doit correspondre à ce que l'autre cherche. « Tous » ou une réponse absente ne bloque rien.
        </li>
        <li>
          <strong>Âge</strong> : le candidat doit être dans la tranche du membre. <Flag on={params.filters.mutualAge} />{" "}
          {params.filters.mutualAge ? "Le membre doit aussi être dans la tranche du candidat." : "L'âge souhaité par le candidat n'est pas regardé."}
        </li>
        <li>
          <strong>Distance</strong> : le candidat doit être dans la distance maximale du membre. <Flag on={params.filters.mutualDistance} />{" "}
          {params.filters.mutualDistance ? "Le membre doit aussi être dans la distance maximale du candidat." : "La distance maximale du candidat n'est pas regardée."} Sans position ou sans limite, rien n'est écarté.
        </li>
        <li>
          <strong>Filtres avancés</strong> du membre (offre Mazl+, avec son consentement), quand il en a posé.
        </li>
      </ul>
    </Section>
  );
}

function criterionHow(criterion: keyof MatchingParams["weights"], p: MatchingParams): string {
  const unknown = `Réponse absente ou « autre » : ${n(p.religion.unknownScore)}.`;
  switch (criterion) {
    case "denomination":
      return `On compare le rang des deux réponses sur l'échelle. Même rang : 1 ; le score tombe à 0 à ${n(p.religion.denominationTolerance)} rangs d'écart. ${unknown}`;
    case "kashrut":
      return `Même principe : 0 à ${n(p.religion.kashrutTolerance)} niveaux d'écart. ${unknown}`;
    case "shabbat":
      return `Même principe : 0 à ${n(p.religion.shabbatTolerance)} niveaux d'écart. ${unknown}`;
    case "intention":
      return `Même principe : 0 à ${n(p.religion.intentionTolerance)} niveaux d'écart. ${unknown}`;
    case "age":
      return `1 au centre de la tranche souhaitée, ${n(p.age.edgeScore)} pile en bord de tranche, 0 hors tranche. Âge absent : ${n(p.religion.unknownScore)}.`;
    case "distance":
      return `1 / (1 + km / ${n(p.distance.halfScoreKm)}) : le score vaut 0,5 à ${n(p.distance.halfScoreKm)} km et baisse sans jamais s'annuler. Position absente : ${n(p.religion.unknownScore)}.`;
    case "profile":
      return "Un tiers pour les photos (4 comptent au maximum), un tiers pour la bio, un tiers pour les questions remplies (3 au maximum). Valeurs fixes du moteur.";
    case "verification":
      return "Non vérifié : 0 ; selfie vérifié : 0,7 ; identité vérifiée : 1. Valeurs fixes du moteur.";
  }
}

const SCALE_LABELS: Readonly<Record<ScaleName, string>> = { denomination: "Courant", kashrut: "Cashrout", shabbat: "Chabbat", intention: "Intention" };

function Criteria({ params }: { readonly params: MatchingParams }): ReactElement {
  const shares = weightShares(params.weights);
  const max = Math.max(0.0001, ...shares.map((row) => row.share));
  const scales = Object.keys(SCALE_LABELS) as ScaleName[];
  return (
    <Section id="e-criteres" step={2} title="Le score par critère" lead="Pour chaque profil restant, le moteur note huit critères entre 0 et 1, puis les additionne selon leur poids. Le calcul est fait dans les deux sens : ce que le membre peut aimer chez le candidat, et ce que le candidat peut aimer chez le membre.">
      <ul className="weights">
        {shares.map((row) => (
          <li key={row.criterion} className="weight-row">
            <div className="weight-head">
              <span className="weight-name">{CRITERION_LABELS[row.criterion]}</span>
              <span className="weight-bar" aria-hidden="true">
                <span className="weight-fill" style={{ width: `${(row.share / max) * 100}%` }} />
              </span>
              <span className="weight-share">{pct(row.share)}</span>
              <span className="weight-raw muted">poids {n(row.weight)}</span>
            </div>
            <p className="weight-how">{criterionHow(row.criterion, params)}</p>
          </li>
        ))}
      </ul>
      <p className="muted explain-note">Les poids sont ramenés à une somme de 100 % : doubler tous les poids ne change rien, seul leur rapport compte. Un critère à 0 est ignoré.</p>
      <details className="statement-details">
        <summary>Échelles de réponses (rang de chaque réponse possible)</summary>
        <div className="scales">
          {scales.map((name) => (
            <div key={name} className="scale">
              <h3>{SCALE_LABELS[name]}</h3>
              <ol>
                {scaleRows(params.scales[name]).map((row) => (
                  <li key={row.rank}>
                    <span className="scale-rank">{row.rank}</span> {row.answers.join(", ")}
                  </li>
                ))}
              </ol>
            </div>
          ))}
        </div>
      </details>
    </Section>
  );
}

const RECIPROCITY_TEXT: Readonly<Record<(typeof RECIPROCITY_ORDER)[number], string>> = {
  harmonic: "Très exigeante sur l'équilibre : si l'un des deux sens est faible, le résultat l'est aussi.",
  geometric: "Racine du produit des deux scores : un peu moins sévère que la harmonique pour les couples déséquilibrés.",
  min: "On garde le plus faible des deux scores.",
  forward_only: "Seul le sens « le membre aimera le candidat » compte ; ce que le candidat pense du membre est ignoré.",
};

function Reciprocity({ params }: { readonly params: MatchingParams }): ReactElement {
  const mode = params.reciprocity.mode;
  const forward = 0.8;
  const backward = 0.4;
  return (
    <Section id="e-reciprocite" step={3} title="La réciprocité" lead="Les deux scores (aller et retour) sont fusionnés en un seul : on veut montrer des profils qui ont des chances de se plaire dans les deux sens.">
      <p>
        Mode actif : <strong>{RECIPROCITY_LABELS[mode]}</strong>. {RECIPROCITY_TEXT[mode]}
      </p>
      <SampleTable
        caption="Résultat de chaque mode pour un exemple"
        head={["Mode", `Exemple : ${pct(forward)} aller, ${pct(backward)} retour`]}
        rows={RECIPROCITY_ORDER.map((candidate) => [candidate === mode ? `${RECIPROCITY_LABELS[candidate]} (actif)` : RECIPROCITY_LABELS[candidate], pct(fuse(forward, backward, candidate))])}
      />
    </Section>
  );
}

function Multipliers({ params }: { readonly params: MatchingParams }): ReactElement {
  const { freshness, newcomer, boost, exposure, safety } = params;
  const cap = exposure.popularityCap;
  return (
    <Section id="e-multiplicateurs" step={4} title="Les multiplicateurs" lead="Le score réciproque est ensuite multiplié par cinq facteurs, qui valent 1 quand ils n'ont aucun effet. Score final = réciprocité × fraîcheur × nouveau venu × boost × exposition × sécurité.">
      <div className="grid-2 multipliers">
        <article className="mult">
          <h3>{MULTIPLIER_LABELS.freshness}</h3>
          <p>
            Un profil perd la moitié de son score tous les <strong>{n(freshness.halfLifeDays)} jours</strong> sans connexion, sans jamais descendre sous <strong>{times(freshness.floor)}</strong>. Jamais connecté : {times(freshness.floor)}.
          </p>
          <SampleTable caption="Effet de l'inactivité" head={["Inactif depuis", "Facteur"]} rows={[0, 7, 14, 30, 60, 90].map((days) => [`${days} j`, times(freshnessFactor(days, freshness))])} />
        </article>
        <article className="mult">
          <h3>{MULTIPLIER_LABELS.newcomer}</h3>
          <p>
            Un compte de moins de <strong>{n(newcomer.days)} jours</strong> reçoit un bonus de <strong>+{pct(newcomer.bonus)}</strong> qui diminue de façon linéaire jusqu'à zéro.
          </p>
          <SampleTable
            caption="Effet de l'ancienneté du compte"
            head={["Compte de", "Facteur"]}
            rows={[0, newcomer.days / 2, newcomer.days].map((days) => [`${n(days)} j`, times(newcomerFactor(days, newcomer))])}
          />
        </article>
        <article className="mult">
          <h3>{MULTIPLIER_LABELS.boost}</h3>
          <p>
            Un membre dont le boost payant est en cours est multiplié par <strong>{times(boost.factor)}</strong>. Sans boost : {times(1)}.
          </p>
        </article>
        <article className="mult">
          <h3>{MULTIPLIER_LABELS.exposure}</h3>
          {exposure.strength === 0 ? (
            <p>
              Désactivée : la force d'amortissement est à 0, la popularité n'a aucun effet.
            </p>
          ) : (
            <p>
              Au-delà de <strong>{n(cap)} likes reçus en 7 jours</strong>, le score est divisé par 1 + {n(exposure.strength)} × (likes ÷ {n(cap)} − 1) : les profils très populaires sont moins montrés.
            </p>
          )}
          <SampleTable caption="Effet de la popularité" head={["Likes sur 7 j", "Facteur"]} rows={[1, 2, 4, 8].map((k) => [n(cap * k), times(exposureFactor(cap * k, exposure))])} />
        </article>
        <article className="mult">
          <h3>{MULTIPLIER_LABELS.safety}</h3>
          <p>
            Chaque signalement ouvert (90 derniers jours) retire <strong>{pct(safety.penaltyPerReport)}</strong> du score, cumulativement, sans passer sous <strong>{times(safety.floor)}</strong>. La sanction elle-même relève de la modération.
          </p>
          <SampleTable caption="Effet des signalements" head={["Signalements ouverts", "Facteur"]} rows={[0, 1, 2, 3, 5].map((k) => [String(k), times(safetyFactor(k, safety))])} />
        </article>
      </div>
    </Section>
  );
}

function Exploration({ params }: { readonly params: MatchingParams }): ReactElement {
  const { epsilon, minScore } = params.exploration;
  const slots = explorationSlots(epsilon, PAGE_SIZE_SIMULATION);
  return (
    <Section id="e-exploration" step={5} title="L'exploration" lead="Un classement strict enfermerait les mêmes profils en haut. Une petite part de chaque page est donc réservée à des profils plausibles, tirés au sort juste en dessous.">
      <p>
        Part d'exploration : <strong>{pct(epsilon)}</strong> de la page, soit <strong>{slots} place{slots > 1 ? "s" : ""}</strong> sur une page de {PAGE_SIZE_SIMULATION} profils (la taille de page de la simulation ; une page plus courte, faute de candidats, a moins de places). Ces places sont tirées parmi les profils classés après la page dont le score réciproque est d'au moins <strong>{n(minScore)}</strong>. Le tirage dépend d'une graine : à graine égale, même tirage. Ces profils sont repérés « Exploration » dans la simulation.
      </p>
    </Section>
  );
}

export function UnderstandTab({ state }: { readonly state: MatchingStateDto }): ReactElement {
  const { active, abTest } = state;
  return (
    <div className="stack">
      <section className="card" aria-labelledby="e-version">
        <div className="card-head">
          <h2 id="e-version">Réglages actifs : version n°&nbsp;{active.id}</h2>
          <Badge tone="success">Active</Badge>
        </div>
        <p className="card-lead">
          Enregistrée par {active.author} le {formatDateTime(active.createdAt)}. Tous les chiffres de cette page viennent de cette version.
        </p>
        <p className="version-note">« {active.note} »</p>
        {abTest !== null ? (
          <p className="notice notice-warning" role="status">
            <strong>Test A/B en cours</strong> : {abTest.sharePercent}&nbsp;% des membres sont classés avec la version n°&nbsp;{abTest.variant.id} au lieu de celle-ci. Cette page décrit la version active ; le détail du test est dans l'onglet Historique.
          </p>
        ) : null}
        <p className="muted explain-note">
          En résumé : le moteur écarte, note, fusionne les deux sens, pondère, puis laisse un peu de place au hasard. Ce que le membre voit est l'ordre ; les scores, eux, ne sont jamais montrés aux membres.
        </p>
      </section>
      <Exclusions params={active.params} />
      <Criteria params={active.params} />
      <Reciprocity params={active.params} />
      <Multipliers params={active.params} />
      <Exploration params={active.params} />
    </div>
  );
}
