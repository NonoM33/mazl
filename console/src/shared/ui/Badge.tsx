import type { ReactElement, ReactNode } from "react";
import type { Priority } from "../api/contracts";
import { PRIORITY_LABELS } from "../labels";

export type Tone = "neutral" | "accent" | "error" | "warning" | "success";

export function Badge({ tone = "neutral", children }: { readonly tone?: Tone; readonly children: ReactNode }): ReactElement {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}

const PRIORITY_TONE: Readonly<Record<Priority, Tone>> = { P1: "error", P2: "warning", P3: "accent", P4: "neutral" };

/** La priorité est toujours écrite en toutes lettres, jamais portée par la seule couleur. */
export function PriorityBadge({ priority, short = false }: { readonly priority: Priority; readonly short?: boolean }): ReactElement {
  return <Badge tone={PRIORITY_TONE[priority]}>{short ? priority : PRIORITY_LABELS[priority]}</Badge>;
}

export const PRIORITY_VAR: Readonly<Record<Priority, string>> = {
  P1: "var(--error)",
  P2: "var(--warning)",
  P3: "var(--accent)",
  P4: "var(--text-2)",
};
