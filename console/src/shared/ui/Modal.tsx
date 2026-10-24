import { useEffect, useId, useRef, type ReactElement, type ReactNode } from "react";
import { Icon } from "./Icon";

interface ModalProps {
  readonly title: string;
  readonly onClose: () => void;
  readonly children: ReactNode;
  readonly wide?: boolean;
}

const FOCUSABLE = "button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])";

/** Fenêtre modale : focus piégé, Échap ferme, le focus revient à l'élément d'origine. */
export function Modal({ title, onClose, children, wide = false }: ModalProps): ReactElement {
  const titleId = useId();
  const ref = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    const previous = document.activeElement;
    const first = ref.current?.querySelector<HTMLElement>("textarea, input, select");
    (first ?? ref.current?.querySelector<HTMLElement>(FOCUSABLE))?.focus();
    return () => {
      if (previous instanceof HTMLElement) previous.focus();
    };
  }, []);
  const onKeyDown = (event: React.KeyboardEvent<HTMLDivElement>): void => {
    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
      onClose();
      return;
    }
    if (event.key !== "Tab" || ref.current === null) return;
    const nodes = Array.from(ref.current.querySelectorAll<HTMLElement>(FOCUSABLE));
    const first = nodes[0];
    const last = nodes[nodes.length - 1];
    if (first === undefined || last === undefined) return;
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  };
  return (
    <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div ref={ref} className={`modal${wide ? " modal-wide" : ""}`} role="dialog" aria-modal="true" aria-labelledby={titleId} onKeyDown={onKeyDown}>
        <header className="modal-head">
          <h2 id={titleId}>{title}</h2>
          <button type="button" className="icon-btn" aria-label="Fermer" onClick={onClose}>
            <Icon name="close" />
          </button>
        </header>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  );
}
