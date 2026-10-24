import type { ReactElement, ReactNode } from "react";

export function PageHeader({ eyebrow, title, actions, lead }: { readonly eyebrow: string; readonly title: string; readonly actions?: ReactNode; readonly lead?: string }): ReactElement {
  return (
    <header className="page-header">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        {lead !== undefined ? <p className="page-lead">{lead}</p> : null}
      </div>
      {actions !== undefined ? <div className="page-actions">{actions}</div> : null}
    </header>
  );
}
