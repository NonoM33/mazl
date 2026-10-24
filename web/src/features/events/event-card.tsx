import { CalendarDays, MapPin, Users } from "lucide-react";
import type { EventRow } from "../../shared/api/types";
import { Link } from "../../shared/router";
import { Photo } from "../../shared/ui/photo";
import { eventTypeLabel, priceLabel, spotsLabel, whenLabel } from "./event-format";

export function EventCover({ event }: { readonly event: EventRow }) {
  return <Photo src={event.image_url} alt="" seed={event.id} radius={0} style={{ position: "absolute", inset: 0 }} />;
}

export function EventCard({ event }: { readonly event: EventRow }) {
  const spots = spotsLabel(event);
  return (
    <Link to={`/evenements/${event.id}`} className="card event-card" aria-label={`${event.title}, ${whenLabel(event)}`}>
      <div className="event-cover">
        <EventCover event={event} />
        <span className="tag">{priceLabel(event)}</span>
      </div>
      <div className="event-card-body">
        <p className="eyebrow">{eventTypeLabel(event.event_type)}</p>
        <h2 className="title-l">{event.title}</h2>
        <div className="event-card-meta">
          <span className="body-s"><CalendarDays size={14} aria-hidden="true" />{whenLabel(event)}</span>
          {event.location && <span className="body-s"><MapPin size={14} aria-hidden="true" />{event.location}</span>}
          {spots && <span className="body-s"><Users size={14} aria-hidden="true" />{spots}</span>}
        </div>
      </div>
    </Link>
  );
}
