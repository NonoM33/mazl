import { Heart, Star, X } from "lucide-react";
import type { ProfileCard, SwipeAction } from "../../shared/api/types";
import { displayName } from "../../shared/lib/format";
import { Photo } from "../../shared/ui/photo";
import { PhotoDots } from "../../shared/ui/photo-dots";
import { practiceChips } from "../../shared/ui/profile-panel";
import { VerifiedBadge } from "../../shared/ui/verified-badge";
import { cardPhotos } from "./photos";

// One card of the deck: full-bleed photo, tap the left or right half to change
// photo (MOUVEMENT.md: never by swiping), name, age, city and practice chips.

const INTENT_ICON = { like: <Heart size={26} fill="currentColor" />, pass: <X size={26} />, super_like: <Star size={26} fill="currentColor" /> } as const;

interface DeckCardProps {
  readonly profile: ProfileCard;
  readonly photoIndex: number;
  readonly onStep?: (delta: 1 | -1) => void;
  readonly onExpired?: () => void;
  readonly intent?: SwipeAction;
}

export function DeckCard({ profile, photoIndex, onStep, onExpired, intent }: DeckCardProps) {
  const name = displayName(profile.display_name);
  const photos = cardPhotos(profile);
  const chips = practiceChips(profile);
  return (
    <article className="deck-card" aria-label={`Carte de ${name}`} aria-hidden={onStep ? undefined : true}>
      <Photo src={photos[photoIndex]} alt={`Photo de ${name}`} seed={profile.user_id + photoIndex} radius={24} initial={name.charAt(0).toUpperCase()} style={{ position: "absolute", inset: 0 }} onExpired={onExpired} />
      <PhotoDots count={photos.length} index={photoIndex} />
      {onStep && (
        <>
          <button type="button" className="deck-hit deck-hit-prev" aria-label="Photo précédente" tabIndex={-1} onClick={() => onStep(-1)} />
          <button type="button" className="deck-hit deck-hit-next" aria-label="Photo suivante" tabIndex={-1} onClick={() => onStep(1)} />
        </>
      )}
      <div className="deck-info">
        <div className="inline gap-8">
          <h2 className="headline-s">{name}{profile.age ? `, ${Math.floor(profile.age)}` : ""}</h2>
          {profile.is_verified && <VerifiedBadge />}
        </div>
        {profile.location && <p className="body-s">{profile.location}</p>}
        {chips.length > 0 && <div className="chips">{chips.map((chip) => <span key={chip} className="tag">{chip}</span>)}</div>}
      </div>
      {intent && <span className={`intent-disc intent-${intent}`} aria-hidden="true">{INTENT_ICON[intent]}</span>}
    </article>
  );
}
