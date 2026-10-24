import { CalendarDays, Clock, MapPin, Tag, Users } from "lucide-react";
import type { ReactNode } from "react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { EventResponse, EventRow } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Link } from "../../shared/router";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { Photo } from "../../shared/ui/photo";
import { attendeesLabel, clock, eventTypeLabel, longDay, priceLabel, spotsLabel } from "./event-format";
import { RsvpPanel } from "./rsvp-panel";
import "./events.css";

function Fact({ icon, label, children }: { readonly icon: ReactNode; readonly label: string; readonly children: ReactNode }) {
  return (
    <div className="event-fact">
      {icon}
      <div className="stack gap-4"><span className="label-m">{label}</span><span className="body-m">{children}</span></div>
    </div>
  );
}

function Facts({ event }: { readonly event: EventRow }) {
  const start = clock(event.time);
  const end = clock(event.end_time);
  const spots = spotsLabel(event);
  const place = [event.location, event.address].filter(Boolean).join(" · ");
  return (
    <>
      <Fact icon={<CalendarDays size={18} aria-hidden="true" />} label="Date">{longDay(event.date)}</Fact>
      {start && <Fact icon={<Clock size={18} aria-hidden="true" />} label="Heure">{end ? `${start} – ${end}` : start}</Fact>}
      {place !== "" && <Fact icon={<MapPin size={18} aria-hidden="true" />} label="Lieu">{place}</Fact>}
      <Fact icon={<Tag size={18} aria-hidden="true" />} label="Prix">{priceLabel(event)}</Fact>
      <Fact icon={<Users size={18} aria-hidden="true" />} label="Participants">{attendeesLabel(event)}{spots ? ` · ${spots}` : ""}</Fact>
    </>
  );
}

export function EventDetailScreen({ eventId }: { readonly eventId: number }) {
  const { state, reload } = useResource(`event:${eventId}`, (signal) => api.get<EventResponse>(`/api/events/${eventId}`, signal), null);
  const data = state.data;
  if (state.status === "error" && !data) {
    const missing = state.error instanceof ApiError && (state.error.isNotFound || state.error.status === 400);
    return (
      <>
        <ScreenHeader eyebrow="Événements" title={missing ? "Événement introuvable" : "Chargement impossible"} />
        <div className="screen-body page-narrow">
          <EmptyState title={missing ? "Événement introuvable" : describeError(state.error)} action={<Link to="/evenements" className="btn btn-outline btn-sm">Retour aux événements</Link>} />
        </div>
      </>
    );
  }
  if (!data) {
    return (<><ScreenHeader eyebrow="Événements" title="Événement" /><div className="screen-body page" aria-busy="true"><Skeleton height={320} radius={24} /></div></>);
  }
  const { event } = data;
  return (
    <>
      <ScreenHeader eyebrow={eventTypeLabel(event.event_type)} title={event.title} actions={<Link to="/evenements" className="btn btn-ghost btn-sm">Retour</Link>} />
      <div className="screen-body page event-detail">
        <div>
          <div className="event-detail-cover" style={{ position: "relative" }}>
            <Photo src={event.image_url} alt="" seed={event.id} radius={0} style={{ position: "absolute", inset: 0 }} />
          </div>
          {event.description && (<section className="stack gap-12"><h2 className="headline-s">Description</h2><p className="body-l event-description">{event.description}</p></section>)}
        </div>
        <aside className="card event-facts" aria-label="Informations pratiques">
          <Facts event={event} />
          <RsvpPanel event={event} status={data.userRsvp?.status ?? null} onChanged={reload} />
        </aside>
      </div>
    </>
  );
}
