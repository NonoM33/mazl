import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { DiscreetContext } from "../../shared/discreet-context";
import { createDoubleEscape } from "./double-escape";
import neutralIcon from "../../../assets/favicon-neutral.svg";

// Discreet mode: a neutral « Notes » page replaces the site, the tab title
// and icon change, and member photos leave the DOM (Photo reads `active`).
// The screens stay mounted so a draft message is not lost. It does not stop
// screenshots, which no website can prevent.


function swapTabIdentity(active: boolean, saved: { title: string; icon: string | null }): void {
  const link = document.querySelector<HTMLLinkElement>("link[rel='icon']");
  if (active) {
    saved.title = document.title;
    saved.icon = link?.getAttribute("href") ?? null;
    document.title = "Notes";
    link?.setAttribute("href", neutralIcon);
  } else {
    document.title = saved.title || "mazl";
    if (saved.icon) link?.setAttribute("href", saved.icon);
  }
}

export function DiscreetProvider({ children }: { readonly children: ReactNode }) {
  const [active, setActive] = useState(false);
  const saved = useRef({ title: "", icon: null as string | null });
  const enter = useCallback(() => setActive(true), []);
  const exit = useCallback(() => setActive(false), []);

  useEffect(() => {
    const detect = createDoubleEscape(() => setActive((current) => !current));
    const onKey = (event: KeyboardEvent) => { detect(event.key); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  useEffect(() => {
    if (active) {
      const memory = saved.current;
      swapTabIdentity(true, memory);
      return () => { swapTabIdentity(false, memory); };
    }
    return undefined;
  }, [active]);

  const value = useMemo(() => ({ active, enter, exit }), [active, enter, exit]);
  return (
    <DiscreetContext value={value}>
      <div hidden={active} inert={active}>{children}</div>
      {active && <DiscreetScreen onResume={exit} />}
    </DiscreetContext>
  );
}

function DiscreetScreen({ onResume }: { readonly onResume: () => void }) {
  return (
    <div style={{ minHeight: "100vh", background: "#fafafa", color: "#3a3a40", fontFamily: "ui-sans-serif, system-ui, sans-serif" }} data-testid="discreet-screen">
      <div style={{ height: 44, borderBottom: "1px solid #e6e6e6", display: "flex", alignItems: "center", padding: "0 16px", gap: 16, fontSize: 13 }}>
        <span style={{ fontWeight: 600 }}>Notes</span>
        <span style={{ color: "#8a8a8a" }}>Fichier</span>
        <span style={{ color: "#8a8a8a" }}>Édition</span>
        <span style={{ color: "#8a8a8a" }}>Affichage</span>
        <span style={{ flex: 1 }} />
        <button type="button" onClick={onResume} style={{ border: "1px solid #dcdcdc", background: "#fff", borderRadius: 6, padding: "4px 10px", fontSize: 12, color: "#3a3a40" }}>
          Reprendre
        </button>
      </div>
      <div style={{ maxWidth: 720, margin: "48px auto", background: "#fff", minHeight: "70vh", boxShadow: "0 1px 3px rgba(0,0,0,.08)", padding: "56px 64px", fontSize: 15, lineHeight: 1.7 }}>
        <p style={{ color: "#b0b0b0" }}>Sans titre</p>
      </div>
    </div>
  );
}
