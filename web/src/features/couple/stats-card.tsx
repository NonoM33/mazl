import { api } from "../../shared/api/client";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { CoupleCard } from "./card";
import type { CoupleStats, StatsResponse } from "./couple-api";
import { num } from "./couple-format";
import { Loaded } from "./loaded";

function figures(stats: CoupleStats): readonly { readonly label: string; readonly value: number }[] {
  return [
    { label: "Activités enregistrées", value: num(stats.saved_activities) },
    { label: "Événements à venir", value: num(stats.events_registered) },
    { label: "Souvenirs créés", value: num(stats.memories_count) },
    { label: "Réservations", value: num(stats.total_bookings) },
    { label: "Rêves accomplis", value: num(stats.bucket_completed) },
    { label: "Rêves au total", value: num(stats.bucket_total) },
  ];
}

export function StatsCard() {
  const resource = useResource("couple-stats", (signal) => api.get<StatsResponse>("/api/couple/stats", signal), null);
  return (
    <CoupleCard title="Statistiques">
      <Loaded resource={resource} height={120}>
        {({ stats, achievements }) => (
          <>
            <ul className="stats couple-list" aria-label="Statistiques du couple">
              {figures(stats).map((figure) => <li key={figure.label} className="stat"><strong>{figure.value}</strong><span className="body-s">{figure.label}</span></li>)}
            </ul>
            <h3 className="eyebrow">Nos badges</h3>
            {achievements.length === 0
              ? <p className="empty-note">Faites des activités ensemble pour débloquer des badges.</p>
              : <ul className="couple-list">{achievements.map((badge) => <li key={badge.id} className="row"><div className="row-main"><span className="row-title">{badge.achievement_name}</span><span className="row-sub">{formatDate(badge.unlocked_at)}</span></div></li>)}</ul>}
          </>
        )}
      </Loaded>
    </CoupleCard>
  );
}
