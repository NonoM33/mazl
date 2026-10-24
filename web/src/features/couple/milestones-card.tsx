import { api } from "../../shared/api/client";
import type { CoupleView } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { CoupleCard } from "./card";
import type { MilestonesResponse } from "./couple-api";
import { daysTogether, milestoneStates, type MilestoneState } from "./couple-format";
import { Loaded } from "./loaded";

function caption(milestone: MilestoneState): string {
  if (milestone.achievedAt) return `Atteint le ${formatDate(milestone.achievedAt)}`;
  return milestone.reached ? "Atteint" : `Dans ${milestone.remaining} j`;
}

// The six milestones of the app: reached once the days together get there, or
// as soon as the server has recorded it (`/milestones`).
export function MilestonesCard({ couple }: { readonly couple: CoupleView }) {
  const resource = useResource(`couple-milestones:${couple.id}`, (signal) => api.get<MilestonesResponse>(`/api/couple/${couple.id}/milestones`, signal), null);
  const days = daysTogether(couple.started_at);
  return (
    <CoupleCard title="Jalons">
      <Loaded resource={resource}>
        {({ milestones }) => (
          <ul className="milestones couple-list" aria-label="Jalons de votre histoire">
            {milestoneStates(days, Object.fromEntries(milestones.map((entry) => [entry.milestone_type, entry.achieved_at]))).map((milestone) => (
              <li key={milestone.days} className="milestone" data-reached={milestone.reached}>
                <span className="title-m">{milestone.label}</span>
                <span className="body-s">{caption(milestone)}</span>
              </li>
            ))}
          </ul>
        )}
      </Loaded>
    </CoupleCard>
  );
}
