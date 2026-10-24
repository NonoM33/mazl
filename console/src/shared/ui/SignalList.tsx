import type { ReactElement } from "react";
import type { RiskSignal } from "../api/contracts";

/** Signaux faibles de risque : libellé, poids (barre relative + valeur) et preuve. Aucun ne décide seul. */
export function SignalList({ signals }: { readonly signals: readonly RiskSignal[] }): ReactElement {
  if (signals.length === 0) return <p className="muted">Aucun signal détecté.</p>;
  const max = Math.max(...signals.map((signal) => signal.weight), 1);
  return (
    <ul className="signals">
      {signals.map((signal) => (
        <li key={signal.code}>
          <div className="signal-head">
            <strong>{signal.label}</strong>
            <span className="signal-weight">
              <span className="signal-bar" aria-hidden="true">
                <i style={{ width: `${Math.max(8, (signal.weight / max) * 100)}%` }} />
              </span>
              <span>poids&nbsp;{signal.weight}</span>
            </span>
          </div>
          <p className="muted">{signal.evidence}</p>
        </li>
      ))}
    </ul>
  );
}
