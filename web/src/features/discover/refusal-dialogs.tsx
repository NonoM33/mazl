import type { LikeAllowance } from "../../shared/api/types";
import { Link } from "../../shared/router";
import { Dialog } from "../../shared/ui/dialog";
import { formatHms, remainingMs } from "./clock";
import { useNow } from "./use-now";
import "./swipe.css";

// 402 answers of the swipe route: no more likes today, no more Super Likes.

export function LikesExhaustedDialog({ allowance, onClose }: { readonly allowance: LikeAllowance | null; readonly onClose: () => void }) {
  const now = useNow();
  const total = allowance?.daily_allowance ?? null;
  return (
    <Dialog title={total === null ? "Vous avez utilisé vos likes du jour" : `Vous avez utilisé vos ${total} likes du jour`} onClose={onClose}>
      <div className="refusal-body">
        {allowance && (
          <div className="stack gap-4">
            <p className="body-s">Vos likes reviennent dans</p>
            <p className="refusal-clock tabular" aria-label="Temps avant le renouvellement des likes">{formatHms(remainingMs(allowance.resets_at, now))}</p>
          </div>
        )}
        <p className="body-m">Avec mazl+, likez sans limite.</p>
        <div className="refusal-actions">
          <Link to="/premium" className="btn btn-accent">Découvrir mazl+</Link>
          <button type="button" className="btn btn-ghost" onClick={onClose}>Plus tard</button>
        </div>
      </div>
    </Dialog>
  );
}

export function SuperLikesExhaustedDialog({ onClose }: { readonly onClose: () => void }) {
  return (
    <Dialog title="Vous n'avez plus de Super Like" onClose={onClose}>
      <div className="refusal-body">
        <p className="body-m">Un pack de Super Likes vous permet de vous démarquer auprès des profils qui vous plaisent.</p>
        <div className="refusal-actions">
          <Link to="/premium" className="btn btn-accent">Voir les packs</Link>
          <button type="button" className="btn btn-ghost" onClick={onClose}>Plus tard</button>
        </div>
      </div>
    </Dialog>
  );
}
