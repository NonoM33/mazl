import type { ReactElement, ReactNode } from "react";
import { Button } from "./Button";
import { Icon, type IconName } from "./Icon";

export function EmptyState({ icon = "inbox", title, children, action }: { readonly icon?: IconName; readonly title: string; readonly children?: ReactNode; readonly action?: ReactNode }): ReactElement {
  return (
    <div className="empty">
      <span className="empty-icon">
        <Icon name={icon} size={22} />
      </span>
      <h3>{title}</h3>
      {children !== undefined ? <p>{children}</p> : null}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { readonly message: string; readonly onRetry?: () => void }): ReactElement {
  return (
    <div className="empty empty-error" role="alert">
      <span className="empty-icon">
        <Icon name="alert" size={22} />
      </span>
      <h3>Impossible de charger les données</h3>
      <p>{message}</p>
      {onRetry !== undefined ? (
        <Button icon="refresh" onClick={onRetry}>
          Réessayer
        </Button>
      ) : null}
    </div>
  );
}

export function Forbidden({ what }: { readonly what: string }): ReactElement {
  return (
    <EmptyState icon="lock" title="Accès refusé">
      Votre rôle ne donne pas accès à {what}. Si c'est une erreur, demandez une modification de rôle à un administrateur.
    </EmptyState>
  );
}

export function Skeleton({ width = "100%", height = 14, radius = 6 }: { readonly width?: string | number; readonly height?: number; readonly radius?: number }): ReactElement {
  return <span className="skeleton" style={{ width, height, borderRadius: radius }} aria-hidden="true" />;
}

export function SkeletonRows({ rows = 8, label = "Chargement" }: { readonly rows?: number; readonly label?: string }): ReactElement {
  return (
    <div className="skeleton-rows" role="status" aria-label={label}>
      {Array.from({ length: rows }, (_, index) => (
        <div className="skeleton-row" key={index}>
          <Skeleton width={48} height={20} radius={10} />
          <Skeleton width="22%" />
          <Skeleton width="26%" />
          <Skeleton width="12%" />
          <Skeleton width="16%" />
        </div>
      ))}
      <span className="sr-only">{label}…</span>
    </div>
  );
}
