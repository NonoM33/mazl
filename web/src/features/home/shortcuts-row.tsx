import { Heart, MessageCircle } from "lucide-react";
import { useUnreadCount } from "../../app/use-unread";
import { api } from "../../shared/api/client";
import type { CountResponse, VerificationStatus } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { likesCount } from "../../shared/lib/format";
import { Link } from "../../shared/router";
import { MobileOnly } from "../../shared/ui/mobile-only";

function plural(count: number, one: string, many: string): string {
  return count > 1 ? many : one;
}

export function ShortcutsRow() {
  const likes = useResource<CountResponse>("likes-count", (signal) => api.get<CountResponse>("/api/likes/received/count", signal), 60_000);
  const verification = useResource<VerificationStatus>("verification", (signal) => api.get<VerificationStatus>("/api/verification/status", signal), null);
  const unread = useUnreadCount(true);
  const count = likes.state.data?.count;
  const unverified = verification.state.data !== undefined && !verification.state.data.is_verified;
  return (
    <section className="stack gap-16" aria-label="Raccourcis">
      <div className="shortcuts">
        <Link to="/likes" className="card-surface shortcut">
          <Heart size={22} aria-hidden="true" />
          <span className="title-m">Likes</span>
          <span className="body-s">{count === undefined ? "" : count === 0 ? "Aucun like pour l'instant" : `${likesCount(count)} ${plural(count, "personne vous a liké", "personnes vous ont liké")}`}</span>
        </Link>
        <Link to="/messages" className="card-surface shortcut">
          <MessageCircle size={22} aria-hidden="true" />
          <span className="title-m">Messages</span>
          <span className="body-s">{unread === 0 ? "Aucun message non lu" : `${unread} ${plural(unread, "message non lu", "messages non lus")}`}</span>
        </Link>
      </div>
      {unverified && <MobileOnly title="Vérifiez votre profil depuis l'app">La vérification par selfie se fait avec l'appareil photo de votre téléphone.</MobileOnly>}
    </section>
  );
}
