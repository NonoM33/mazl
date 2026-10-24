import { Pencil } from "lucide-react";
import { useState } from "react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { ProfileResponse, ProfileCard } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Link } from "../../shared/router";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { MobileOnly } from "../../shared/ui/mobile-only";
import { Photo } from "../../shared/ui/photo";
import { PhotoViewer } from "../../shared/ui/photo-viewer";
import { ProfilePanel } from "../../shared/ui/profile-panel";
import { VerifiedBadge } from "../../shared/ui/verified-badge";
import { toPromptAnswers, useMeResource, useOwnPromptsResource, useVerificationResource } from "./use-profile-context";
import "./profile.css";

const LEVEL_LABELS = { none: null, photo: "Selfie vérifié", identity: "Identité vérifiée" } as const;

function LargePhotos({ card, onExpired }: { readonly card: ProfileCard; readonly onExpired: () => void }) {
  const [viewer, setViewer] = useState<number | null>(null);
  const photos = card.photos.length > 0 ? card.photos : card.picture ? [card.picture] : [];
  if (photos.length === 0) {
    return <EmptyState title="Aucune photo">Ajoutez des photos depuis « Modifier le profil ».</EmptyState>;
  }
  return (
    <section className="stack gap-12" aria-label="Mes photos">
      <div className="own-photos">
        {photos.map((src, index) => (
          <button key={src} type="button" className={index === 0 ? "photo-thumb own-photo-main" : "photo-thumb"} onClick={() => setViewer(index)} aria-label={`Agrandir la photo ${index + 1}`}>
            <Photo src={src} alt="" seed={card.user_id + index} radius={index === 0 ? 24 : 16} style={{ width: "100%", aspectRatio: "3 / 4" }} onExpired={onExpired} />
          </button>
        ))}
      </div>
      {viewer !== null && <PhotoViewer photos={photos} start={viewer} name={card.display_name ?? "Moi"} seed={card.user_id} onClose={() => setViewer(null)} />}
    </section>
  );
}

export function ProfileScreen() {
  const me = useMeResource();
  const myId = me.state.data?.user.id;
  const profile = useResource<ProfileCard | null>(`own-card:${myId ?? "?"}`, async (signal) => (myId === undefined ? null : (await api.get<ProfileResponse>(`/api/profile/${myId}`, signal)).profile));
  const prompts = useOwnPromptsResource();
  const verification = useVerificationResource();
  const card = profile.state.data;
  const level = verification.state.data?.level ?? "none";
  const badge = LEVEL_LABELS[level];
  const failed = me.state.status === "error" || profile.state.status === "error";
  return (
    <>
      <ScreenHeader eyebrow="Mon profil" title="Tel que vu par les autres" actions={<Link to="/profil/modifier" className="btn btn-accent btn-sm"><Pencil size={16} aria-hidden="true" />Modifier le profil</Link>} />
      <div className="screen-body">
        {card ? (
          <div className="page cols-profile">
            <LargePhotos card={card} onExpired={() => void profile.reload()} />
            <div className="stack gap-24">
              {badge ? (
                <div className="inline gap-8" aria-label="Vérification"><VerifiedBadge label={badge} /><span className="title-s">{badge}</span></div>
              ) : verification.state.status === "ready" ? (
                <MobileOnly title="Faites vérifier votre profil depuis l'app">La vérification par selfie ou par pièce d'identité se fait sur votre téléphone, dans l'application MAZL.</MobileOnly>
              ) : null}
              <ProfilePanel profile={{ ...card, photos: [], picture: null, is_verified: level !== "none" }} prompts={toPromptAnswers(prompts.state.data ?? [])} />
            </div>
          </div>
        ) : failed ? (
          <EmptyState title="Profil indisponible" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => { void me.reload(); void profile.reload(); }}>Réessayer</button>}>{describeError(me.state.error ?? profile.state.error)}</EmptyState>
        ) : (
          <div className="page cols-profile"><Skeleton height={520} radius={24} /><Skeleton height={320} radius={24} /></div>
        )}
      </div>
    </>
  );
}
