import { ScreenHeader } from "../../app/shell";
import { useCouple } from "../../shared/couple-context";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { ActivitiesScreen } from "./activities-screen";
import { CalendarScreen } from "./calendar-screen";
import { CoupleEventsScreen } from "./couple-events-screen";
import { SpaceScreen } from "./space-screen";
import "../events/events.css";
import "./couple.css";

export type CoupleSection = "espace" | "activites" | "calendrier" | "evenements";

const TITLES: Readonly<Record<CoupleSection, string>> = {
  espace: "Notre espace",
  activites: "Activités",
  calendrier: "Calendrier",
  evenements: "Événements",
};

export function CoupleScreen({ section }: { readonly section: CoupleSection }) {
  const { couple, ready } = useCouple();
  return (
    <>
      <ScreenHeader eyebrow="Couple" title={TITLES[section]} />
      <div className="screen-body page">
        {couple === null ? (
          ready ? <EmptyState title="Le mode couple n'est pas activé">Il s'active à deux, depuis une demande acceptée.</EmptyState> : <Skeleton height={200} radius={24} />
        ) : (
          <>
            {section === "espace" && <SpaceScreen couple={couple} />}
            {section === "activites" && <ActivitiesScreen />}
            {section === "calendrier" && <CalendarScreen />}
            {section === "evenements" && <CoupleEventsScreen />}
          </>
        )}
      </div>
    </>
  );
}
