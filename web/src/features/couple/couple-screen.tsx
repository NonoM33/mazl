import { ScreenHeader } from "../../app/shell";

export type CoupleSection = "espace" | "activites" | "calendrier" | "evenements";

// Placeholder, replaced in lot 5.
export function CoupleScreen({ section }: { readonly section: CoupleSection }) {
  return <ScreenHeader title={`Couple · ${section}`} />;
}
