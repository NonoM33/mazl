import { Layers, UserRound } from "lucide-react";
import { describeMissingField, type MissingProfileField } from "../../shared/api/errors";
import { Link } from "../../shared/router";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";

export function DeckSkeleton() {
  return (
    <div className="deck-stage" role="status" aria-label="Chargement des profils">
      <Skeleton width="100%" height="100%" radius={24} />
    </div>
  );
}

interface EmptyProps { readonly onOpenFilters: () => void; readonly onRefresh: () => void }

export function DeckEmpty({ onOpenFilters, onRefresh }: EmptyProps) {
  return (
    <EmptyState
      icon={<Layers size={40} aria-hidden="true" />}
      title="Vous avez tout vu."
      action={(
        <div className="inline gap-8">
          <button type="button" className="btn btn-outline btn-sm" onClick={onOpenFilters}>Ouvrir les filtres</button>
          <button type="button" className="btn btn-primary btn-sm" onClick={onRefresh}>Actualiser</button>
        </div>
      )}
    >
      Revenez plus tard ou élargissez vos filtres pour voir de nouveaux profils.
    </EmptyState>
  );
}

export function DeckError({ message, onRetry }: { readonly message: string; readonly onRetry: () => void }) {
  return (
    <EmptyState title="Les profils ne se sont pas chargés." action={<button type="button" className="btn btn-primary btn-sm" onClick={onRetry}>Réessayer</button>}>
      {message}
    </EmptyState>
  );
}

export const INCOMPLETE_TITLE = "Complétez votre profil pour découvrir des profils";
export const INCOMPLETE_ACTION = "Compléter mon profil";
export const PROFILE_EDIT_PATH = "/profil/modifier";

export function IncompleteProfile({ missing }: { readonly missing: readonly MissingProfileField[] }) {
  return (
    <EmptyState
      icon={<UserRound size={40} aria-hidden="true" />}
      title={INCOMPLETE_TITLE}
      action={<Link to={PROFILE_EDIT_PATH} className="btn btn-primary btn-sm">{INCOMPLETE_ACTION}</Link>}
    >
      {missing.length > 0 && (
        <>
          <p>Il manque encore :</p>
          <ul style={{ listStyle: "none", padding: 0, margin: "8px 0 0" }}>
            {missing.map((field) => <li key={field}>{describeMissingField(field)}</li>)}
          </ul>
        </>
      )}
    </EmptyState>
  );
}
