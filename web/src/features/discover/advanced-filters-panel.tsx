import { Lock } from "lucide-react";
import { Link } from "../../shared/router";
import { Switch } from "../../shared/ui/switch";
import { filterOptions, NO_FILTERS, type AdvancedFilters } from "./advanced-filters";
import type { PracticeKind } from "./practice";

// « Filtres avancés » (mazl+): they narrow the profiles already received.
// Without mazl+ they stay visible but locked.

const FIELDS: readonly { readonly kind: PracticeKind; readonly label: string }[] = [
  { kind: "denomination", label: "Courant" }, { kind: "kashrut", label: "Cacherout" },
  { kind: "shabbat", label: "Shabbat" }, { kind: "intention", label: "Intention" },
];

interface Props { readonly filters: AdvancedFilters; readonly plus: boolean; readonly onChange: (filters: AdvancedFilters) => void }

export function AdvancedFiltersPanel({ filters, plus, onChange }: Props) {
  return (
    <section className="stack gap-16" aria-label="Filtres avancés">
      <div className="spread">
        <p className="eyebrow">Filtres avancés</p>
        <span className="tag tag-accent">mazl+</span>
      </div>
      <p className="body-s">Affine les profils proposés.</p>
      {!plus && (
        <div className="banner banner-accent">
          <Lock size={16} aria-hidden="true" style={{ flex: "none", marginTop: 3 }} />
          <div className="stack gap-4">
            <span>Réservés aux membres mazl+.</span>
            <Link to="/premium" className="title-s">Découvrir mazl+</Link>
          </div>
        </div>
      )}
      <fieldset className="stack gap-16 filters-set" disabled={!plus}>
        {FIELDS.map(({ kind, label }) => (
          <div key={kind} className="field">
            <label htmlFor={`filter-${kind}`}>{label}</label>
            <select id={`filter-${kind}`} className="select" value={filters[kind] ?? ""} onChange={(event) => onChange({ ...filters, [kind]: event.target.value || null })}>
              <option value="">Tous</option>
              {filterOptions(kind).map((option) => <option key={option} value={option}>{option}</option>)}
            </select>
          </div>
        ))}
        <div className="spread">
          <span className="body-m" aria-hidden="true">Vérifiés uniquement</span>
          <Switch checked={filters.verifiedOnly} onChange={(verifiedOnly) => onChange({ ...filters, verifiedOnly })} label="Vérifiés uniquement" />
        </div>
        <button type="button" className="btn btn-ghost btn-sm" onClick={() => onChange(NO_FILTERS)}>Réinitialiser</button>
      </fieldset>
    </section>
  );
}
