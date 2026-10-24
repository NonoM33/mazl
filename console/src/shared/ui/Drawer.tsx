import { useEffect, useRef, type ReactElement, type ReactNode } from "react";
import { Icon } from "./Icon";

interface DrawerProps {
  readonly title: string;
  readonly eyebrow?: string;
  readonly onClose: () => void;
  readonly children: ReactNode;
  readonly wide?: boolean;
}

/** Panneau latéral non modal : Échap le ferme, le focus y entre à l'ouverture. */
export function Drawer({ title, eyebrow, onClose, children, wide = false }: DrawerProps): ReactElement {
  const ref = useRef<HTMLElement | null>(null);
  useEffect(() => {
    ref.current?.focus();
  }, []);
  useEffect(() => {
    const onKey = (event: KeyboardEvent): void => {
      if (event.key === "Escape" && !event.defaultPrevented && document.querySelector("[aria-modal='true']") === null) onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  return (
    <aside ref={ref} className={`drawer${wide ? " drawer-wide" : ""}`} role="dialog" aria-label={title} tabIndex={-1}>
      <header className="drawer-head">
        <div>
          {eyebrow !== undefined ? <p className="eyebrow">{eyebrow}</p> : null}
          <h2>{title}</h2>
        </div>
        <button type="button" className="icon-btn" aria-label="Fermer le panneau (Échap)" onClick={onClose}>
          <Icon name="close" />
        </button>
      </header>
      <div className="drawer-body">{children}</div>
    </aside>
  );
}
