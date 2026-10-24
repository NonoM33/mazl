import { useEffect, useState } from "react";
import { Heart } from "lucide-react";
import { api } from "../../shared/api/client";
import type { PhotosResponse } from "../../shared/api/types";
import { displayName } from "../../shared/lib/format";
import { useRouter } from "../../shared/router";
import { useMe } from "../../shared/session";
import { Avatar } from "../../shared/ui/photo";
import { Dialog } from "../../shared/ui/dialog";
import type { MatchEvent } from "./match-event";
import "./swipe.css";

// « C'est un match » (MOUVEMENT.md §4): two round photos that meet, one accent
// ring that grows once, then the two actions.

function useOwnPhoto(): string | null {
  const me = useMe();
  const [url, setUrl] = useState<string | null>(null);
  useEffect(() => {
    const controller = new AbortController();
    api.get<PhotosResponse>("/api/profile/photos", controller.signal).then(
      (response) => setUrl(response.photos[0]?.url ?? null),
      () => setUrl(null),
    );
    return () => controller.abort();
  }, []);
  return url ?? me.user.picture;
}

export function MatchSheet({ match, onClose }: { readonly match: MatchEvent; readonly onClose: () => void }) {
  const { navigate } = useRouter();
  const mine = useOwnPhoto();
  const name = displayName(match.name);
  const send = () => navigate(match.conversationId === null ? "/messages" : `/messages/${match.conversationId}`);
  return (
    <Dialog title="C'est un match" onClose={onClose}>
      <div className="match-body">
        <div className="match-pair">
          <span className="match-ring" aria-hidden="true" />
          <div className="match-photo match-photo-left"><Avatar src={mine} name="Vous" seed={1} size={116} /></div>
          <div className="match-photo match-photo-right"><Avatar src={match.picture} name={name} seed={match.userId} size={116} /></div>
          <span className="match-heart" aria-hidden="true"><Heart size={18} fill="currentColor" /></span>
        </div>
        <p className="body-l">{name} et vous vous êtes plu.</p>
        <div className="match-actions">
          <button type="button" className="btn btn-primary" onClick={send}>Envoyer un message</button>
          <button type="button" className="btn btn-ghost" onClick={onClose}>Continuer à découvrir</button>
        </div>
      </div>
    </Dialog>
  );
}
