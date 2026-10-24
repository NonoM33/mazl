import type { ReceivedLike } from "../../shared/api/types";
import { Photo } from "../../shared/ui/photo";
import { likeCaption } from "./likes-model";

// Without mazl+ the photos are blurred by the browser and only the first name
// shows; the server still sends the picture, so nothing here is a secret
// boundary (see the report).

export function LikesGrid({ likes, plus, onOpen, onExpired }: { readonly likes: readonly ReceivedLike[]; readonly plus: boolean; readonly onOpen: (userId: number) => void; readonly onExpired: () => void }) {
  return (
    <ul className="likes-grid list" aria-label="Ils vous ont aimé">
      {likes.map((like) => (
        <li key={like.user_id}>
          <button type="button" className="like-card" disabled={!plus} onClick={() => onOpen(like.user_id)} aria-label={plus ? `Voir le profil de ${likeCaption(like, true)}` : `Profil flouté de ${likeCaption(like, false)}`}>
            <Photo src={like.picture} alt="" seed={like.user_id} radius={0} className={plus ? "like-photo" : "like-photo blurred"} initial={likeCaption(like, false).charAt(0)} onExpired={onExpired} />
            <span className="like-caption">{likeCaption(like, plus)}</span>
          </button>
        </li>
      ))}
    </ul>
  );
}
