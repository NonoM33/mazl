import type { ReactNode } from "react";

// One block of the settings column: eyebrow title, anchor, a filled card.
export function Section({ id, title, children, plain = false }: { readonly id: string; readonly title: string; readonly children: ReactNode; readonly plain?: boolean }) {
  return (
    <section id={id} className="stack gap-12" aria-labelledby={`${id}-titre`} style={{ scrollMarginTop: 24 }}>
      <h2 id={`${id}-titre`} className="eyebrow">{title}</h2>
      <div className={plain ? "stack gap-12" : "card-surface settings-card"}>{children}</div>
    </section>
  );
}

export function Row({ title, sub, action }: { readonly title: string; readonly sub?: ReactNode; readonly action?: ReactNode }) {
  return (
    <div className="row">
      <div className="row-main"><span className="row-title">{title}</span>{sub && <span className="row-sub">{sub}</span>}</div>
      {action}
    </div>
  );
}
