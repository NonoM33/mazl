import { Plus } from "lucide-react";
import { useRef, useState, type ChangeEvent, type DragEvent } from "react";
import { Dialog } from "../../shared/ui/dialog";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { Skeleton } from "../../shared/ui/empty-state";
import { MAX_PHOTOS } from "./photo-order";
import { PhotoSlot } from "./photo-slot";
import type { usePhotos } from "./use-photos";

type Photos = ReturnType<typeof usePhotos>;

function carriesFiles(event: DragEvent): boolean {
  return event.dataTransfer.types.includes("Files");
}

export function PhotoManager({ photos: api, userId }: { readonly photos: Photos; readonly userId: number }) {
  const input = useRef<HTMLInputElement>(null);
  const [dragged, setDragged] = useState<number | null>(null);
  const [filesOver, setFilesOver] = useState(false);
  const [confirming, setConfirming] = useState<number | null>(null);
  const { photos, pending } = api;
  const empties = Math.max(0, MAX_PHOTOS - photos.length - pending.length);
  const full = photos.length + pending.length >= MAX_PHOTOS;

  const pick = (event: ChangeEvent<HTMLInputElement>) => {
    void api.upload(Array.from(event.target.files ?? []));
    event.target.value = "";
  };
  const dropFiles = (event: DragEvent) => {
    if (!carriesFiles(event)) return;
    event.preventDefault();
    setFilesOver(false);
    void api.upload(Array.from(event.dataTransfer.files));
  };

  return (
    <section className="stack gap-12" aria-label="Photos">
      <div className="spread">
        <div className="stack gap-4">
          <Eyebrow as="h2">Photos · {photos.length}/{MAX_PHOTOS}</Eyebrow>
          <p className="body-s">La première photo est votre photo principale. Glissez les vignettes ou utilisez les flèches pour changer l'ordre.</p>
        </div>
        <button type="button" className="btn btn-outline btn-sm" disabled={full} onClick={() => input.current?.click()}>Ajouter des photos</button>
      </div>
      <input ref={input} type="file" accept="image/jpeg,image/png,image/heic,image/heif,.heic,.heif" multiple hidden onChange={pick} aria-label="Choisir des photos" data-testid="photo-input" />
      {api.message && <p className="banner banner-error" role="alert">{api.message}</p>}
      <p className="visually-hidden" role="status" aria-live="polite">{api.announcement}</p>
      {api.state.status === "loading" ? <Skeleton height={220} radius={16} /> : (
        <ul className={filesOver ? "photo-manager is-over" : "photo-manager"} aria-label="Vos photos" onDragOver={(event) => { if (carriesFiles(event)) { event.preventDefault(); setFilesOver(true); } }} onDragLeave={() => setFilesOver(false)} onDrop={dropFiles}>
          {photos.map((photo, index) => (
            <PhotoSlot key={photo.id} photo={photo} index={index} count={photos.length} userId={userId} dragging={dragged === photo.id}
              onMove={(delta) => void api.move(photo.id, delta)} onRemove={() => setConfirming(photo.id)}
              onDragStart={() => setDragged(photo.id)} onDragEnd={() => setDragged(null)}
              onDropHere={() => { if (dragged !== null) void api.dropAt(dragged, index); setDragged(null); }} onExpired={() => void api.reload()} />
          ))}
          {pending.map((item) => (
            <li key={item.key} className="photo-slot is-pending" aria-label="Envoi en cours">
              <img src={item.preview} alt="" style={{ width: "100%", aspectRatio: "3 / 4", objectFit: "cover", borderRadius: 16 }} />
              <span className="photo-slot-main tag">Envoi…</span>
            </li>
          ))}
          {Array.from({ length: empties }, (_, slot) => (
            <li key={`empty-${slot}`} className="photo-slot">
              <button type="button" className="photo-empty" onClick={() => input.current?.click()} aria-label="Ajouter une photo"><Plus size={24} aria-hidden="true" /><span className="body-s">Déposer ou choisir</span></button>
            </li>
          ))}
        </ul>
      )}
      <p className="label-m">JPEG, PNG ou HEIC, 10 Mo au maximum. Vos photos sont ré-encodées à l'envoi. Si votre profil a été vérifié par selfie, une photo ajoutée peut être comparée à ce selfie.</p>
      {confirming !== null && (
        <Dialog title="Supprimer cette photo ?" onClose={() => setConfirming(null)}>
          <p className="body-m">Elle disparaîtra de votre profil.</p>
          <div className="inline gap-8" style={{ justifyContent: "flex-end" }}>
            <button type="button" className="btn btn-outline btn-sm" onClick={() => setConfirming(null)}>Garder</button>
            <button type="button" className="btn btn-danger btn-sm" onClick={() => { void api.remove(confirming); setConfirming(null); }}>Supprimer</button>
          </div>
        </Dialog>
      )}
    </section>
  );
}
