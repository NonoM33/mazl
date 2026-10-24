import type { ReactElement, ReactNode } from "react";
import { Skeleton } from "./Feedback";

export function Stat({ label, value, note, tone = "neutral" }: { readonly label: string; readonly value: ReactNode; readonly note?: string; readonly tone?: "neutral" | "error" | "warning" }): ReactElement {
  return (
    <div className={`stat stat-${tone}`}>
      <span className="eyebrow">{label}</span>
      <span className="stat-value">{value}</span>
      {note !== undefined ? <span className="stat-note">{note}</span> : null}
    </div>
  );
}

export function StatSkeleton(): ReactElement {
  return (
    <div className="stat" aria-hidden="true">
      <Skeleton width="60%" height={11} />
      <Skeleton width="45%" height={30} radius={8} />
    </div>
  );
}
