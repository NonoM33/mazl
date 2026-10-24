import { Link } from "../../shared/router";
import { displayName } from "../../shared/lib/format";
import type { ProfileCard } from "../../shared/api/types";
import { Photo } from "../../shared/ui/photo";
import { Skeleton } from "../../shared/ui/empty-state";
import { VerifiedBadge } from "../../shared/ui/verified-badge";
import { cardPhotos } from "../discover/photos";

export function PickTile({ profile, onOpen, onExpired }: { readonly profile: ProfileCard; readonly onOpen: () => void; readonly onExpired: () => void }) {
  const name = displayName(profile.display_name);
  return (
    <button type="button" className="pick-tile" onClick={onOpen} aria-label={`Voir le profil de ${name}`}>
      <Photo src={cardPhotos(profile)[0]} alt="" seed={profile.user_id} radius={20} initial={name.charAt(0).toUpperCase()} style={{ position: "absolute", inset: 0 }} onExpired={onExpired} />
      <span className="pick-caption">
        <span className="inline gap-4 title-s">{name}{profile.age ? `, ${Math.floor(profile.age)}` : ""}{profile.is_verified && <VerifiedBadge size={15} />}</span>
        {profile.location && <span className="label-m">{profile.location}</span>}
      </span>
    </button>
  );
}

export function PicksSkeleton() {
  return (
    <div className="picks-grid" role="status" aria-label="Chargement des sélections">
      {Array.from({ length: 5 }, (_, index) => <Skeleton key={index} height="100%" radius={20} />)}
    </div>
  );
}

export function PicksDone({ countdown }: { readonly countdown: string | null }) {
  return (
    <div className="card-surface stack gap-12 picks-done">
      <h3 className="title-l">Vous avez vu toutes vos sélections.</h3>
      {countdown && <p className="body-m muted">Prochaines sélections dans <span className="tabular">{countdown}</span></p>}
      <div><Link to="/decouvrir" className="btn btn-primary btn-sm">Découvrir plus de profils</Link></div>
    </div>
  );
}
