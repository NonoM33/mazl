import { ChevronLeft, ChevronRight, Trash2 } from "lucide-react";
import type { DragEvent } from "react";
import type { OwnPhoto } from "../../shared/api/types";
import { Photo } from "../../shared/ui/photo";

export const PHOTO_DRAG_TYPE = "application/x-mazl-photo";

interface SlotProps {
  readonly photo: OwnPhoto;
  readonly index: number;
  readonly count: number;
  readonly userId: number;
  readonly dragging: boolean;
  readonly onMove: (delta: -1 | 1) => void;
  readonly onRemove: () => void;
  readonly onDragStart: () => void;
  readonly onDragEnd: () => void;
  readonly onDropHere: () => void;
  readonly onExpired: () => void;
}

export function PhotoSlot({ photo, index, count, userId, dragging, onMove, onRemove, onDragStart, onDragEnd, onDropHere, onExpired }: SlotProps) {
  const number = index + 1;
  const start = (event: DragEvent) => {
    event.dataTransfer.setData(PHOTO_DRAG_TYPE, String(photo.id));
    event.dataTransfer.effectAllowed = "move";
    onDragStart();
  };
  const over = (event: DragEvent) => {
    if (event.dataTransfer.types.includes(PHOTO_DRAG_TYPE)) { event.preventDefault(); event.dataTransfer.dropEffect = "move"; }
  };
  const drop = (event: DragEvent) => {
    if (!event.dataTransfer.types.includes(PHOTO_DRAG_TYPE)) return;
    event.preventDefault();
    event.stopPropagation();
    onDropHere();
  };
  return (
    <li className={dragging ? "photo-slot is-dragging" : "photo-slot"} draggable onDragStart={start} onDragEnd={onDragEnd} onDragOver={over} onDrop={drop} aria-label={`Photo ${number} sur ${count}${index === 0 ? ", photo principale" : ""}`}>
      <Photo src={photo.url} alt={`Photo ${number}`} seed={userId + photo.id} radius={16} style={{ width: "100%", aspectRatio: "3 / 4" }} onExpired={onExpired} />
      {index === 0 && <span className="photo-slot-main tag tag-accent">Principale</span>}
      <div className="photo-slot-bar">
        <button type="button" className="icon-btn" disabled={index === 0} onClick={() => onMove(-1)} aria-label={`Déplacer la photo ${number} à gauche`}><ChevronLeft size={18} /></button>
        <button type="button" className="icon-btn" disabled={index === count - 1} onClick={() => onMove(1)} aria-label={`Déplacer la photo ${number} à droite`}><ChevronRight size={18} /></button>
        <button type="button" className="icon-btn" onClick={onRemove} aria-label={`Supprimer la photo ${number}`}><Trash2 size={18} /></button>
      </div>
    </li>
  );
}
