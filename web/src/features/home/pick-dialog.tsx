import { Heart, X } from "lucide-react";
import type { ProfileCard } from "../../shared/api/types";
import { displayName } from "../../shared/lib/format";
import { Dialog } from "../../shared/ui/dialog";
import { ProfilePanel } from "../../shared/ui/profile-panel";

interface PickDialogProps {
  readonly profile: ProfileCard;
  readonly onPass: () => void;
  readonly onLike: () => void;
  readonly onClose: () => void;
  readonly onExpired: () => void;
}

export function PickDialog({ profile, onPass, onLike, onClose, onExpired }: PickDialogProps) {
  return (
    <Dialog title={`Profil de ${displayName(profile.display_name)}`} onClose={onClose} hideTitle>
      <ProfilePanel profile={profile} onExpired={onExpired} />
      <div className="inline gap-8 pick-actions">
        <button type="button" className="btn btn-outline grow" onClick={onPass}><X size={18} aria-hidden="true" />Passer</button>
        <button type="button" className="btn btn-accent grow" onClick={onLike}><Heart size={18} fill="currentColor" aria-hidden="true" />Like</button>
      </div>
    </Dialog>
  );
}
