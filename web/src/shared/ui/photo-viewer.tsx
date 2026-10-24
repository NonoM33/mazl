import { useEffect, useState } from "react";
import { ChevronLeft, ChevronRight, X } from "lucide-react";
import { useHotkeys } from "../hooks/use-hotkeys";
import { Photo } from "./photo";

// Full-screen photo viewer (MOUVEMENT.md: opens in 200 ms on a veil).
// ← → browse, Escape closes. Screenshots cannot be prevented on the web,
// which the viewer says once.

export function PhotoViewer({ photos, start, name, seed, onClose }: { readonly photos: readonly string[]; readonly start: number; readonly name: string; readonly seed: number; readonly onClose: () => void }) {
  const [index, setIndex] = useState(start);
  const count = photos.length;
  const go = (step: number) => setIndex((current) => (current + step + count) % count);
  useHotkeys({ arrowleft: () => go(-1), arrowright: () => go(1), escape: onClose, " ": () => go(1) });
  useEffect(() => {
    const previous = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.body.style.overflow = previous; };
  }, []);
  return (
    <div className="viewer" role="dialog" aria-modal="true" aria-label={`Photos de ${name}`} onClick={onClose}>
      <button type="button" className="icon-btn viewer-close" aria-label="Fermer" onClick={onClose}><X size={24} /></button>
      {count > 1 && <button type="button" className="icon-btn viewer-prev" aria-label="Photo précédente" onClick={(event) => { event.stopPropagation(); go(-1); }}><ChevronLeft size={28} /></button>}
      <div className="viewer-stage" onClick={(event) => event.stopPropagation()}>
        <Photo src={photos[index]} alt={`${name}, photo ${index + 1} sur ${count}`} seed={seed + index} radius={20} style={{ height: "min(86vh, 1100px)", aspectRatio: "3 / 4" }} />
      </div>
      {count > 1 && <button type="button" className="icon-btn viewer-next" aria-label="Photo suivante" onClick={(event) => { event.stopPropagation(); go(1); }}><ChevronRight size={28} /></button>}
      <p className="viewer-foot">{index + 1} / {count} · Les captures d'écran ne peuvent pas être empêchées sur un navigateur.</p>
    </div>
  );
}
