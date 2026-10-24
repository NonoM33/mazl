import type { ReactElement, ReactNode } from "react";

export function Wordmark({ size = 28 }: { readonly size?: number }): ReactElement {
  return (
    <span className="wordmark" style={{ fontSize: size }} aria-label="mazl">
      mazl.
    </span>
  );
}

export function AuthLayout({ title, lead, children }: { readonly title: string; readonly lead?: string; readonly children: ReactNode }): ReactElement {
  return (
    <main className="auth-page" id="contenu">
      <section className="auth-card" aria-labelledby="auth-title">
        <div className="auth-brand">
          <Wordmark size={34} />
          <span className="eyebrow">Staff</span>
        </div>
        <h1 id="auth-title">{title}</h1>
        {lead !== undefined ? <p className="auth-lead">{lead}</p> : null}
        {children}
      </section>
      <p className="auth-foot">Accès réservé à l'équipe MAZL. Chaque action est journalisée.</p>
    </main>
  );
}
