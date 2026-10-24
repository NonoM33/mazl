import type { ProfileCard, SwipeAction } from "../../shared/api/types";
import { DeckCard } from "./deck-card";

export interface Leaving { readonly profile: ProfileCard; readonly action: SwipeAction; readonly photoIndex: number; readonly nonce: number }

interface DeckStageProps {
  readonly visible: readonly ProfileCard[];
  readonly photoIndex: number;
  readonly leaving: Leaving | null;
  readonly onStep: (delta: 1 | -1) => void;
  readonly onExpired: () => void;
}

// The pile: the card on top, the next one behind at scale 0.96, and the card
// that was just decided on, flying out (240 ms) above both.
export function DeckStage({ visible, photoIndex, leaving, onStep, onExpired }: DeckStageProps) {
  return (
    <div className="deck-stage">
      {visible.slice(0, 2).map((profile, position) => (
        <div key={profile.user_id} className={position === 0 ? "deck-layer deck-front" : "deck-layer deck-back"}>
          <DeckCard profile={profile} photoIndex={position === 0 ? photoIndex : 0} onStep={position === 0 ? onStep : undefined} onExpired={onExpired} />
        </div>
      ))}
      {leaving && (
        <div key={leaving.nonce} className={`deck-layer deck-leaving deck-leaving-${leaving.action}`}>
          <DeckCard profile={leaving.profile} photoIndex={leaving.photoIndex} intent={leaving.action} />
        </div>
      )}
    </div>
  );
}
