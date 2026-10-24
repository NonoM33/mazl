import { useEffect, useRef, useState } from "react";
import { Copy, Flag, MoreHorizontal, Reply, Undo2 } from "lucide-react";
import type { MessageView } from "../../shared/api/types";
import { ALLOWED_REACTIONS } from "./thread-model";

// Hover bar of a bubble: the six allowed reactions and a menu (Répondre,
// Copier, Retirer for my recent messages, Signaler for the other's).

interface ActionsProps {
  readonly view: MessageView;
  readonly mine: boolean;
  readonly canUnsend: boolean;
  readonly myId: number;
  readonly onReact: (emoji: string) => void;
  readonly onReply: () => void;
  readonly onCopy: () => void;
  readonly onUnsend: () => void;
  readonly onReport: () => void;
}

export function MessageActions({ view, mine, canUnsend, myId, onReact, onReply, onCopy, onUnsend, onReport }: ActionsProps) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const myEmoji = view.reactions.find((reaction) => reaction.user_ids.includes(myId))?.emoji;

  useEffect(() => {
    if (!open) return undefined;
    const onDown = (event: MouseEvent) => { if (!box.current?.contains(event.target as Node)) setOpen(false); };
    const onKey = (event: KeyboardEvent) => { if (event.key === "Escape") { event.stopPropagation(); setOpen(false); } };
    document.addEventListener("mousedown", onDown);
    window.addEventListener("keydown", onKey, true);
    return () => { document.removeEventListener("mousedown", onDown); window.removeEventListener("keydown", onKey, true); };
  }, [open]);

  const choose = (run: () => void) => () => { setOpen(false); run(); };
  return (
    <div ref={box} className="msg-actions" data-side={mine ? "mine" : "theirs"} data-open={open}>
      <div className="react-bar" role="group" aria-label="Réagir au message">
        {ALLOWED_REACTIONS.map((emoji) => (
          <button key={emoji} type="button" className="react-btn" data-mine={myEmoji === emoji} aria-pressed={myEmoji === emoji} aria-label={`Réagir ${emoji}`} onClick={() => onReact(emoji)}>{emoji}</button>
        ))}
        <button type="button" className="react-btn react-more" aria-label="Plus d'actions" aria-haspopup="menu" aria-expanded={open} onClick={() => setOpen((current) => !current)}><MoreHorizontal size={18} aria-hidden="true" /></button>
      </div>
      {open && (
        <div className="msg-menu" role="menu" aria-label="Actions sur le message">
          <button type="button" role="menuitem" onClick={choose(onReply)}><Reply size={20} aria-hidden="true" />Répondre</button>
          {view.content.length > 0 && <button type="button" role="menuitem" onClick={choose(onCopy)}><Copy size={20} aria-hidden="true" />Copier</button>}
          {mine && canUnsend && <button type="button" role="menuitem" className="danger" onClick={choose(onUnsend)}><Undo2 size={20} aria-hidden="true" />Retirer</button>}
          {!mine && <button type="button" role="menuitem" className="danger" onClick={choose(onReport)}><Flag size={20} aria-hidden="true" />Signaler</button>}
        </div>
      )}
    </div>
  );
}
