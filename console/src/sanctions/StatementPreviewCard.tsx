import type { ReactElement } from "react";
import type { StatementPreview } from "./statement";

/** Exposé des motifs (DSA, art. 17) tel que le membre le lira. */
export function StatementPreviewCard({ preview }: { readonly preview: StatementPreview }): ReactElement {
  return (
    <section className="statement" aria-label="Aperçu de l'exposé des motifs">
      <p className="eyebrow">Aperçu de l'exposé des motifs</p>
      <p className="statement-note">Voici ce que le membre recevra. Relisez-le avant de valider : une décision ne se modifie pas.</p>
      <dl className="statement-list">
        <div>
          <dt>Décision</dt>
          <dd>{preview.decision}</dd>
        </div>
        <div>
          <dt>Portée</dt>
          <dd>{preview.scope}</dd>
        </div>
        <div>
          <dt>Faits</dt>
          <dd>{preview.facts}</dd>
        </div>
        <div>
          <dt>Fondement</dt>
          <dd>{preview.groundText}</dd>
        </div>
        <div>
          <dt>Décision automatisée</dt>
          <dd>{preview.automated}</dd>
        </div>
        <div>
          <dt>Voies de recours</dt>
          <dd>{preview.redress}</dd>
        </div>
      </dl>
    </section>
  );
}
