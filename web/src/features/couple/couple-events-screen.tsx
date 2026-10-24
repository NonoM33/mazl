import { useState } from "react";
import { CalendarDays, MapPin, Users } from "lucide-react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import { useResource } from "../../shared/hooks/use-resource";
import { Dialog } from "../../shared/ui/dialog";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { Photo } from "../../shared/ui/photo";
import { clock, shortDay } from "../events/event-format";
import type { CoupleEvent, CoupleEventsResponse } from "./couple-api";
import { EVENT_CATEGORIES, centsLabel, coupleSpotsLabel, coupleSpotsLeft, eventCategoryLabel } from "./couple-format";
import { useAction } from "./use-action";

type Tab = "upcoming" | "registered";

function Details({ event }: { readonly event: CoupleEvent }) {
  const rows = [event.dress_code && `Tenue : ${event.dress_code}`, event.what_included && `Inclus : ${event.what_included}`].filter((row): row is string => Boolean(row));
  return rows.length === 0 ? null : <ul className="list stack gap-4">{rows.map((row) => <li key={row} className="body-s">{row}</li>)}</ul>;
}

function EventItem({ event, registered, onChanged }: { readonly event: CoupleEvent; readonly registered: boolean; readonly onChanged: () => Promise<void> }) {
  const { busy, run } = useAction();
  const [confirming, setConfirming] = useState(false);
  const full = coupleSpotsLeft(event) === 0;
  const paid = (event.price_cents ?? 0) > 0;
  const spots = coupleSpotsLabel(event);
  const when = [shortDay(event.event_date), clock(event.event_time)].filter(Boolean).join(" · ");
  return (
    <li className="card activity-card">
      <div className="event-cover"><Photo src={event.image_url} alt="" seed={event.id} radius={0} style={{ position: "absolute", inset: 0 }} />{centsLabel(event.price_cents) && <span className="tag">{centsLabel(event.price_cents)}</span>}</div>
      <div className="activity-body">
        <p className="eyebrow">{eventCategoryLabel(event.category)}</p>
        <h2 className="title-l">{event.title}</h2>
        {event.description && <p className="body-s">{event.description}</p>}
        <div className="event-card-meta">
          <span className="body-s"><CalendarDays size={14} aria-hidden="true" />{when}</span>
          {event.location && <span className="body-s"><MapPin size={14} aria-hidden="true" />{event.location}</span>}
          {spots && <span className="body-s"><Users size={14} aria-hidden="true" />{spots}</span>}
        </div>
        <Details event={event} />
        <div className="activity-actions">
          {registered
            ? <button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => setConfirming(true)}>Annuler l'inscription</button>
            : <button type="button" className="btn btn-accent btn-sm" disabled={busy || full || paid} onClick={() => void run(() => api.post(`/api/couple/events/${event.id}/register`), { after: onChanged, done: "Inscription confirmée" })}>{full ? "Complet" : paid ? "Paiement requis" : "S'inscrire"}</button>}
          {!registered && paid && <p className="body-s">Cet événement est payant : le serveur exige un paiement avant l'inscription.</p>}
        </div>
      </div>
      {confirming && (
        <Dialog title="Annuler l'inscription ?" onClose={() => setConfirming(false)}>
          <div className="stack gap-16">
            <p className="body-m">Voulez-vous vraiment annuler votre inscription à « {event.title} » ?</p>
            <button type="button" className="btn btn-danger" disabled={busy} onClick={() => void run(() => api.delete(`/api/couple/events/${event.id}/register`), { after: onChanged, done: "Inscription annulée" }).then(() => setConfirming(false))}>Oui, annuler</button>
            <button type="button" className="btn btn-ghost" onClick={() => setConfirming(false)}>Non</button>
          </div>
        </Dialog>
      )}
    </li>
  );
}

function Feed({ tab, category }: { readonly tab: Tab; readonly category: string | null }) {
  const upcoming = useResource(`couple-events:${category ?? "all"}`, (signal) => api.get<CoupleEventsResponse>(`/api/couple/events?limit=60${category ? `&category=${encodeURIComponent(category)}` : ""}`, signal), null);
  const registered = useResource("couple-events-registered", (signal) => api.get<CoupleEventsResponse>("/api/couple/events/registered", signal), null);
  const active = tab === "registered" ? registered : upcoming;
  const events = active.state.data?.events;
  const refresh = async () => { await Promise.all([upcoming.reload(), registered.reload()]); };
  const ids = new Set(registered.state.data?.events.map((event) => event.id));
  if (!events) {
    if (active.state.status === "error") return <EmptyState title="Chargement impossible" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void active.reload()}>Réessayer</button>}>{describeError(active.state.error)}</EmptyState>;
    return <div className="cards-grid" aria-busy="true">{[0, 1, 2].map((key) => <Skeleton key={key} height={300} radius={24} />)}</div>;
  }
  if (events.length === 0) {
    return tab === "registered"
      ? <EmptyState title="Aucune inscription">Vous n'êtes inscrits à aucun événement pour le moment.</EmptyState>
      : <EmptyState title="Aucun événement disponible">Aucun événement pour couples n'est programmé pour le moment.</EmptyState>;
  }
  return <ul className="cards-grid list" aria-label="Événements pour couples">{events.map((event) => <EventItem key={event.id} event={event} registered={tab === "registered" || ids.has(event.id)} onChanged={refresh} />)}</ul>;
}

export function CoupleEventsScreen() {
  const [tab, setTab] = useState<Tab>("upcoming");
  const [category, setCategory] = useState<string | null>(null);
  return (
    <div className="stack gap-24">
      <div role="tablist" aria-label="Événements" className="tabs">
        <button type="button" role="tab" aria-selected={tab === "upcoming"} onClick={() => setTab("upcoming")}>À venir</button>
        <button type="button" role="tab" aria-selected={tab === "registered"} onClick={() => setTab("registered")}>Mes inscriptions</button>
      </div>
      {tab === "upcoming" && (
        <div className="chips" role="group" aria-label="Catégorie">
          {EVENT_CATEGORIES.map((entry) => <button key={entry.label} type="button" className="chip" aria-pressed={category === entry.key} onClick={() => setCategory(entry.key)}>{entry.label}</button>)}
        </div>
      )}
      <Feed tab={tab} category={category} />
    </div>
  );
}
