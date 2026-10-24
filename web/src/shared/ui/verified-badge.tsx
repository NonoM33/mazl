import { BadgeCheck } from "lucide-react";

export function VerifiedBadge({ size = 18, label = "Profil vérifié" }: { readonly size?: number; readonly label?: string }) {
  return (
    <span className="verified" title={label}>
      <BadgeCheck size={size} strokeWidth={2.2} aria-hidden="true" />
      <span className="visually-hidden">{label}</span>
    </span>
  );
}
