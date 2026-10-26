import type { KeyboardEvent, ReactElement } from "react";

export interface TabDef<Id extends string> {
  readonly id: Id;
  readonly label: string;
}

export const tabButtonId = (prefix: string, id: string): string => `${prefix}-tab-${id}`;
export const tabPanelId = (prefix: string): string => `${prefix}-panel`;

interface TabsProps<Id extends string> {
  readonly label: string;
  readonly prefix: string;
  readonly tabs: readonly TabDef<Id>[];
  readonly active: Id;
  readonly onSelect: (id: Id) => void;
}

/** Onglets au clavier : flèches gauche/droite, Début/Fin ; un seul onglet dans l'ordre de tabulation. */
export function Tabs<Id extends string>({ label, prefix, tabs, active, onSelect }: TabsProps<Id>): ReactElement {
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>): void => {
    const index = tabs.findIndex((tab) => tab.id === active);
    const target =
      event.key === "ArrowRight" ? index + 1 : event.key === "ArrowLeft" ? index - 1 : event.key === "Home" ? 0 : event.key === "End" ? tabs.length - 1 : null;
    if (target === null) return;
    event.preventDefault();
    const next = tabs[(target + tabs.length) % tabs.length];
    if (next === undefined) return;
    onSelect(next.id);
    document.getElementById(tabButtonId(prefix, next.id))?.focus();
  };
  return (
    <div className="tabs" role="tablist" aria-label={label} onKeyDown={onKeyDown}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          id={tabButtonId(prefix, tab.id)}
          type="button"
          role="tab"
          aria-selected={tab.id === active}
          aria-controls={tabPanelId(prefix)}
          tabIndex={tab.id === active ? 0 : -1}
          className={`tab${tab.id === active ? " is-active" : ""}`}
          onClick={() => onSelect(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
