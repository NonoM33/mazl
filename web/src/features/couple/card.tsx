import type { ReactNode } from "react";

export function CoupleCard({ title, action, children, label }: { readonly title: string; readonly action?: ReactNode; readonly children: ReactNode; readonly label?: string }) {
  return (
    <section className="card couple-card" aria-label={label ?? title}>
      <div className="couple-card-head"><h2 className="eyebrow">{title}</h2>{action}</div>
      {children}
    </section>
  );
}
