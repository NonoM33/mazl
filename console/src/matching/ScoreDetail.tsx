import type { ReactElement } from "react";
import type { DirectionalScore, RankedCandidate } from "../shared/api/contracts";
import { CRITERION_LABELS, MULTIPLIER_LABELS } from "./explain";

const nf = new Intl.NumberFormat("fr-FR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const nf3 = new Intl.NumberFormat("fr-FR", { minimumFractionDigits: 3, maximumFractionDigits: 3 });
const pct = (ratio: number): string => `${new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 }).format(ratio * 100)} %`;
export const formatScore = (score: number): string => nf3.format(score);

function Directional({ title, score }: { readonly title: string; readonly score: DirectionalScore }): ReactElement {
  return (
    <table className="detail-table">
      <caption>
        {title} <span className="detail-total">{nf.format(score.total)}</span>
      </caption>
      <thead>
        <tr>
          <th scope="col">Critère</th>
          <th scope="col" className="cell-right">Note</th>
          <th scope="col" className="cell-right">Poids</th>
          <th scope="col" className="cell-right">Apport</th>
        </tr>
      </thead>
      <tbody>
        {score.criteria.map((row) => (
          <tr key={row.criterion}>
            <th scope="row">
              <span>{CRITERION_LABELS[row.criterion]}</span>
              <span className="detail-sub">{row.detail}</span>
            </th>
            <td className="cell-right">{nf.format(row.score)}</td>
            <td className="cell-right">{pct(row.weight)}</td>
            <td className="cell-right">{nf.format(row.contribution)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

/** Pourquoi ce profil est là, à cette place : critères dans les deux sens, réciprocité, multiplicateurs. */
export function ScoreDetail({ candidate, heading }: { readonly candidate: RankedCandidate; readonly heading: string }): ReactElement {
  return (
    <div className="detail">
      <h4>{heading}</h4>
      <p className="detail-final">
        <span>Place {candidate.rank}</span>
        <strong>{formatScore(candidate.score)}</strong>
        {candidate.explored ? <span className="badge badge-warning">Exploration</span> : null}
      </p>
      <Directional title="Le membre vers ce profil" score={candidate.forward} />
      <Directional title="Ce profil vers le membre" score={candidate.backward} />
      <dl className="detail-flow">
        <div>
          <dt>Réciprocité</dt>
          <dd>{nf.format(candidate.reciprocal)}</dd>
        </div>
        {candidate.multipliers.map((multiplier) => (
          <div key={multiplier.key}>
            <dt>
              {MULTIPLIER_LABELS[multiplier.key]}
              <span className="detail-sub">{multiplier.detail}</span>
            </dt>
            <dd>×&nbsp;{nf.format(multiplier.factor)}</dd>
          </div>
        ))}
        <div className="detail-result">
          <dt>Score final</dt>
          <dd>{formatScore(candidate.score)}</dd>
        </div>
      </dl>
    </div>
  );
}
