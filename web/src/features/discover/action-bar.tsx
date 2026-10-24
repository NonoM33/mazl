import { Heart, Star, X } from "lucide-react";
import type { SwipeAction } from "../../shared/api/types";

interface ActionBarProps {
  readonly disabled: boolean;
  readonly superLikes: number | null;
  readonly likesLeft: number | null;
  readonly onAct: (action: SwipeAction) => void;
}

export function ActionBar({ disabled, superLikes, likesLeft, onAct }: ActionBarProps) {
  return (
    <div className="stack gap-12" style={{ alignItems: "center" }}>
      <div className="inline gap-16 deck-actions">
        <button type="button" className="action-btn" aria-label="Passer" disabled={disabled} onClick={() => onAct("pass")}><X size={28} /></button>
        <button type="button" className="action-btn super" aria-label="Super Like" disabled={disabled} onClick={() => onAct("super_like")}><Star size={24} fill="currentColor" /></button>
        <button type="button" className="action-btn like" aria-label="Like" disabled={disabled} onClick={() => onAct("like")}><Heart size={28} fill="currentColor" /></button>
      </div>
      <p className="label-m tabular" aria-live="polite">
        {superLikes !== null && `${superLikes} Super Like${superLikes > 1 ? "s" : ""} restant${superLikes > 1 ? "s" : ""}`}
        {superLikes !== null && likesLeft !== null && " · "}
        {likesLeft !== null && `${likesLeft} like${likesLeft > 1 ? "s" : ""} aujourd'hui`}
      </p>
    </div>
  );
}
