import { useState } from "react";
import { MapPin } from "lucide-react";
import type { ProfileCard } from "../api/types";
import { ageLabel, displayName } from "../lib/format";
import { profileLabels } from "../lib/profile-labels";
import { Eyebrow } from "./eyebrow";
import { Photo } from "./photo";
import { PhotoViewer } from "./photo-viewer";
import { VerifiedBadge } from "./verified-badge";

// A member's full profile in a side column (Découvrir, Messages, Likes):
// photos, bio, practice chips, prompts when the caller has them. Clicking a
// photo opens the viewer.

export interface PromptAnswer { readonly question: string; readonly answer: string }

export function practiceChips(profile: Pick<ProfileCard, "denomination" | "kashrut_level" | "shabbat_observance" | "relationship_intention">): string[] {
  return [
    profileLabels.denomination(profile.denomination),
    profileLabels.kashrut(profile.kashrut_level),
    profileLabels.shabbat(profile.shabbat_observance),
    profileLabels.intention(profile.relationship_intention),
  ].filter((label): label is string => label !== null);
}

export function ProfilePanel({ profile, prompts = [], onExpired }: { readonly profile: ProfileCard; readonly prompts?: readonly PromptAnswer[]; readonly onExpired?: () => void }) {
  const [viewer, setViewer] = useState<number | null>(null);
  const name = displayName(profile.display_name);
  const photos = profile.photos.length > 0 ? profile.photos : profile.picture ? [profile.picture] : [];
  const chips = practiceChips(profile);
  return (
    <article className="profile-panel" aria-label={`Profil de ${name}`}>
      <header className="stack gap-4">
        <div className="inline gap-8">
          <h2 className="headline-s">{name}{profile.age ? <span className="muted">, {Math.floor(profile.age)}</span> : null}</h2>
          {profile.is_verified && <VerifiedBadge />}
        </div>
        {profile.location && <p className="body-s inline gap-4"><MapPin size={14} aria-hidden="true" />{profile.location}</p>}
      </header>
      {profile.bio && <p className="body-m">{profile.bio}</p>}
      {chips.length > 0 && (
        <section className="stack gap-8">
          <Eyebrow>Pratique</Eyebrow>
          <div className="chips">{chips.map((chip) => <span key={chip} className="tag">{chip}</span>)}</div>
        </section>
      )}
      {prompts.map((prompt) => (
        <section key={prompt.question} className="card-surface prompt-card">
          <p className="label-m">{prompt.question}</p>
          <p className="title-m">{prompt.answer}</p>
        </section>
      ))}
      {photos.length > 0 && (
        <section className="stack gap-8">
          <Eyebrow>Photos · {photos.length}</Eyebrow>
          <div className="photo-grid">
            {photos.map((src, index) => (
              <button key={src} type="button" className="photo-thumb" onClick={() => setViewer(index)} aria-label={`Agrandir la photo ${index + 1}`}>
                <Photo src={src} alt="" seed={profile.user_id + index} radius={16} style={{ width: "100%", aspectRatio: "3 / 4" }} onExpired={onExpired} />
              </button>
            ))}
          </div>
        </section>
      )}
      {!profile.age && !profile.bio && chips.length === 0 && <p className="body-s">{ageLabel(profile.age)}</p>}
      {viewer !== null && <PhotoViewer photos={photos} start={viewer} name={name} seed={profile.user_id} onClose={() => setViewer(null)} />}
    </article>
  );
}
