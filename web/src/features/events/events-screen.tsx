import { useState } from "react";
import { CalendarX } from "lucide-react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { EventsResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { EventCard } from "./event-card";
import { EVENT_TYPES } from "./event-format";
import "./events.css";

function Filters({ value, onChange }: { readonly value: string | null; readonly onChange: (key: string | null) => void }) {
  return (
    <div className="chips" role="group" aria-label="Type d'événement">
      {EVENT_TYPES.map((entry) => (
        <button key={entry.label} type="button" className="chip" aria-pressed={value === entry.key} onClick={() => onChange(entry.key)}>{entry.label}</button>
      ))}
    </div>
  );
}

export function EventsScreen() {
  const [type, setType] = useState<string | null>(null);
  const path = type ? `/api/events?type=${encodeURIComponent(type)}` : "/api/events";
  const { state, reload } = useResource(`events:${type ?? "all"}`, (signal) => api.get<EventsResponse>(path, signal), null);
  const events = state.data?.events;
  const count = events?.length;
  return (
    <>
      <ScreenHeader eyebrow="Rencontres" title="Événements" />
      <div className="screen-body page stack gap-24">
        <Filters value={type} onChange={setType} />
        {state.status === "loading" && <div className="events-grid" aria-busy="true">{[0, 1, 2].map((key) => <Skeleton key={key} height={260} radius={24} />)}</div>}
        {state.status === "error" && !events && (
          <EmptyState title="Chargement impossible" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void reload()}>Réessayer</button>}>{describeError(state.error)}</EmptyState>
        )}
        {count === 0 && (
          <EmptyState title="Aucun événement" icon={<CalendarX size={32} aria-hidden="true" />}>Revenez bientôt pour découvrir de nouveaux événements.</EmptyState>
        )}
        {events && count !== 0 && <div className="events-grid">{events.map((event) => <EventCard key={event.id} event={event} />)}</div>}
      </div>
    </>
  );
}
