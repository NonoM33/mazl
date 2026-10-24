import { displayName } from "../../shared/lib/format";
import { Photo } from "../../shared/ui/photo";
import { cardPhotos } from "../discover/photos";
import type { ShadchanChoice } from "../discover/shadchan";

// « Le mot du Shadchan »: only criteria really shared are named.
export function ShadchanCard({ choice, onOpen, onExpired }: { readonly choice: ShadchanChoice; readonly onOpen: () => void; readonly onExpired: () => void }) {
  const { pick, shared } = choice;
  const name = displayName(pick.display_name);
  return (
    <section className="card-surface shadchan" aria-label="Le mot du Shadchan">
      <Photo src={cardPhotos(pick)[0]} alt="" seed={pick.user_id} radius={20} initial={name.charAt(0).toUpperCase()} style={{ width: 96, height: 120, flex: "none" }} onExpired={onExpired} />
      <div className="stack gap-8 grow">
        <p className="eyebrow">Le mot du Shadchan</p>
        <h3 className="title-l">{name}{pick.age ? `, ${Math.floor(pick.age)}` : ""}</h3>
        <p className="body-m">{shared.length > 0 ? `Vous partagez : ${shared.join(" · ")}` : "Voici la première de vos sélections du jour."}</p>
        <div><button type="button" className="btn btn-outline btn-sm" onClick={onOpen}>Voir le profil</button></div>
      </div>
    </section>
  );
}
