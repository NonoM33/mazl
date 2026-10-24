import type { ReactNode } from "react";

export function EmptyState({ title, children, action, icon }: { readonly title: string; readonly children?: ReactNode; readonly action?: ReactNode; readonly icon?: ReactNode }) {
  return (
    <div className="stack gap-16" style={{ alignItems: "center", textAlign: "center", padding: "64px 24px", maxWidth: 420, margin: "0 auto" }}>
      {icon && <div style={{ color: "var(--muted)" }}>{icon}</div>}
      <h2 className="headline-s">{title}</h2>
      {children && <div className="body-m muted">{children}</div>}
      {action}
    </div>
  );
}

export function Skeleton({ width = "100%", height = 16, radius = 12 }: { readonly width?: number | string; readonly height?: number | string; readonly radius?: number }) {
  return <div className="skeleton" style={{ width, height, borderRadius: radius }} aria-hidden="true" />;
}
