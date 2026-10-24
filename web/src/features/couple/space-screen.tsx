import type { CoupleView } from "../../shared/api/types";
import { BucketCard } from "./bucket-card";
import { DailyQuestionCard } from "./daily-question";
import { DatesCard } from "./dates-card";
import { LeaveCouple } from "./leave-couple";
import { MemoriesCard } from "./memories-card";
import { MilestonesCard } from "./milestones-card";
import { PartnerCard } from "./partner-card";
import { StatsCard } from "./stats-card";

// « Notre espace »: the couple at a glance, then what they keep together.
export function SpaceScreen({ couple }: { readonly couple: CoupleView }) {
  return (
    <div className="couple-cols">
      <div className="couple-col">
        <PartnerCard couple={couple} />
        <DailyQuestionCard couple={couple} />
        <MilestonesCard couple={couple} />
        <DatesCard />
      </div>
      <div className="couple-col">
        <MemoriesCard />
        <BucketCard />
        <StatsCard />
        <LeaveCouple couple={couple} />
      </div>
    </div>
  );
}
