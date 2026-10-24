import { useState } from "react";
import { Bookmark, Clock, MapPin, Star, X } from "lucide-react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import { useResource } from "../../shared/hooks/use-resource";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { Photo } from "../../shared/ui/photo";
import type { Activity, ActivitiesResponse } from "./couple-api";
import { ACTIVITY_CATEGORIES, activityPrice, categoryLabel, durationLabel, num } from "./couple-format";
import { useAction } from "./use-action";

type Tab = "discover" | "saved";

function ActivityCard({ activity, mode, onChanged }: { readonly activity: Activity; readonly mode: Tab; readonly onChanged: () => Promise<void> }) {
  const { busy, run } = useAction();
  const price = activityPrice(activity);
  const duration = durationLabel(activity.duration_minutes);
  const act = (path: string, method: "post" | "delete", done?: string) => void run(() => (method === "post" ? api.post(path) : api.delete(path)), { after: onChanged, done });
  return (
    <li className="card activity-card">
      <div className="event-cover"><Photo src={activity.image_url} alt="" seed={activity.id} radius={0} style={{ position: "absolute", inset: 0 }} />{price && <span className="tag">{price}</span>}</div>
      <div className="activity-body">
        <p className="eyebrow">{categoryLabel(activity.category)}</p>
        <h2 className="title-l">{activity.title}</h2>
        {activity.description && <p className="body-s">{activity.description}</p>}
        <div className="event-card-meta">
          {activity.location && <span className="body-s"><MapPin size={14} aria-hidden="true" />{activity.location}</span>}
          {duration && <span className="body-s"><Clock size={14} aria-hidden="true" />{duration}</span>}
          {num(activity.rating) > 0 && <span className="body-s"><Star size={14} aria-hidden="true" />{num(activity.rating).toFixed(1)}</span>}
        </div>
        <div className="activity-actions">
          {mode === "discover" ? (
            <>
              <button type="button" className="btn btn-accent btn-sm" disabled={busy} onClick={() => act(`/api/couple/activities/${activity.id}/save`, "post", "Activité enregistrée")}><Bookmark size={16} aria-hidden="true" />Enregistrer</button>
              <button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => act(`/api/couple/activities/${activity.id}/pass`, "post")}><X size={16} aria-hidden="true" />Passer</button>
            </>
          ) : (
            <button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => act(`/api/couple/saved/${activity.id}`, "delete", "Activité retirée")}>Retirer</button>
          )}
        </div>
      </div>
    </li>
  );
}

function Feed({ tab, category }: { readonly tab: Tab; readonly category: string | null }) {
  const path = tab === "saved" ? "/api/couple/saved" : `/api/couple/activities?limit=60${category ? `&category=${encodeURIComponent(category)}` : ""}`;
  const { state, reload } = useResource(`couple-activities:${path}`, (signal) => api.get<ActivitiesResponse>(path, signal), null);
  const activities = state.data?.activities;
  if (!activities) {
    if (state.status === "error") return <EmptyState title="Chargement impossible" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void reload()}>Réessayer</button>}>{describeError(state.error)}</EmptyState>;
    return <div className="cards-grid" aria-busy="true">{[0, 1, 2].map((key) => <Skeleton key={key} height={300} radius={24} />)}</div>;
  }
  if (activities.length === 0) {
    return tab === "saved"
      ? <EmptyState title="Aucune activité enregistrée">Enregistrez les idées qui vous plaisent, elles apparaîtront ici.</EmptyState>
      : <EmptyState title="Aucune idée à afficher">Vous avez parcouru toutes les idées de cette catégorie.</EmptyState>;
  }
  return <ul className="cards-grid list" aria-label={tab === "saved" ? "Activités enregistrées" : "Activités proposées"}>{activities.map((activity) => <ActivityCard key={activity.id} activity={activity} mode={tab} onChanged={reload} />)}</ul>;
}

export function ActivitiesScreen() {
  const [tab, setTab] = useState<Tab>("discover");
  const [category, setCategory] = useState<string | null>(null);
  return (
    <div className="stack gap-24">
      <div role="tablist" aria-label="Activités" className="tabs">
        <button type="button" role="tab" aria-selected={tab === "discover"} onClick={() => setTab("discover")}>Idées</button>
        <button type="button" role="tab" aria-selected={tab === "saved"} onClick={() => setTab("saved")}>Enregistrées</button>
      </div>
      {tab === "discover" && (
        <div className="chips" role="group" aria-label="Catégorie">
          {ACTIVITY_CATEGORIES.map((entry) => <button key={entry.label} type="button" className="chip" aria-pressed={category === entry.key} onClick={() => setCategory(entry.key)}>{entry.label}</button>)}
        </div>
      )}
      <Feed tab={tab} category={category} />
    </div>
  );
}
