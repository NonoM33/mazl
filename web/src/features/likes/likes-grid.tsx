import type { ReceivedLike } from "../../shared/api/types";
import { Photo } from "../../shared/ui/photo";
import { likeCaption } from "./likes-model";

// Without mazl+ the server sends no photo nor id (docs/web/adr/W11): the cards
// are blurred tints with a first name. With mazl+, a card opens the profile.

export function LikesGrid({ likes, plus, onOpen, onExpired }: { readonly likes: readonly ReceivedLike[]; readonly plus: boolean; readonly onOpen: (userId: number) => void; readonly onExpired: () => void }) {
  return (
    <ul className="likes-grid list" aria-label="Ils vous ont aimé">
      {likes.map((like, index) => (
        <li key={like.user_id ?? `${index}-${like.liked_at}`}>
          <button type="button" className="like-card" disabled={!plus || like.user_id === undefined} onClick={() => { if (like.user_id !== undefined) onOpen(like.user_id); }} aria-label={plus ? `Voir le profil de ${likeCaption(like, true)}` : `Profil flouté de ${likeCaption(like, false)}`}>
            <Photo src={like.picture} alt="" seed={like.user_id ?? index} radius={0} className={plus ? "like-photo" : "like-photo blurred"} initial={likeCaption(like, false).charAt(0)} onExpired={onExpired} />
            <span className="like-caption">{likeCaption(like, plus)}</span>
          </button>
        </li>
      ))}
    </ul>
  );
}
