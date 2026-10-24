import type { ReactNode } from "react";

// SectionLabel of the app: Geist Mono 11, upper case, muted.
export function Eyebrow({ children, as: Tag = "p" }: { readonly children: ReactNode; readonly as?: "p" | "h2" | "h3" }) {
  return <Tag className="eyebrow">{children}</Tag>;
}
