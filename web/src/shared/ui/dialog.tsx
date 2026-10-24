import { useEffect, useId, useRef, type ReactNode } from "react";
import { X } from "lucide-react";

// Modal dialog: focus moves in, Escape closes, focus returns where it was.
export function Dialog({ title, onClose, children, wide = false, hideTitle = false }: { readonly title: string; readonly onClose: () => void; readonly children: ReactNode; readonly wide?: boolean; readonly hideTitle?: boolean }) {
  const id = useId();
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const previous = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    box.current?.focus();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.stopPropagation();
        onClose();
      }
    };
    window.addEventListener("keydown", onKey, true);
    return () => {
      window.removeEventListener("keydown", onKey, true);
      previous?.focus();
    };
  }, [onClose]);

  return (
    <div className="overlay" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <div ref={box} className={wide ? "dialog dialog-wide" : "dialog"} role="dialog" aria-modal="true" aria-labelledby={id} tabIndex={-1}>
        <div className="spread">
          <h2 id={id} className={hideTitle ? "visually-hidden" : "headline-s"}>{title}</h2>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="Fermer"><X size={22} /></button>
        </div>
        {children}
      </div>
    </div>
  );
}
