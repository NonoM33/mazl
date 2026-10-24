import { useEffect, useState, type ReactElement, type ReactNode } from "react";
import type { ReportPageDto } from "../shared/api/contracts";
import { formatNumber } from "../shared/format";
import { Icon, type IconName } from "../shared/ui/Icon";
import { Wordmark } from "../auth/AuthLayout";
import { can, SECTIONS, type SectionId } from "./permissions";
import { buildHash } from "./router";
import { useMe, useSession } from "./session";

const ICONS: Readonly<Record<SectionId, IconName>> = {
  "tableau-de-bord": "dashboard",
  signalements: "flag",
  membres: "users",
  contestations: "scale",
  verification: "shield",
  autorites: "building",
  algorithme: "sliders",
  audit: "log",
  equipe: "team",
  transparence: "chart",
};

/** Compteur de la file : signalements ouverts (rafraîchi toutes les minutes). */
function useOpenReports(enabled: boolean, refreshKey: string): number | null {
  const { api } = useSession();
  const [count, setCount] = useState<number | null>(null);
  useEffect(() => {
    if (!enabled) return;
    let cancelled = false;
    const load = (): void => {
      void api.get<ReportPageDto>("/reports", { limit: 1 }).then((result) => {
        if (!cancelled && result.ok) setCount(result.data.total);
      });
    };
    load();
    const timer = window.setInterval(load, 60_000);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [api, enabled, refreshKey]);
  return count;
}

export function Shell({ active, children }: { readonly active: SectionId | null; readonly children: ReactNode }): ReactElement {
  const me = useMe();
  const session = useSession();
  const openReports = useOpenReports(can(me, "reports.read"), active ?? "");
  return (
    <div className="shell">
      <a className="skip-link" href="#contenu">
        Aller au contenu
      </a>
      <aside className="sidebar">
        <div className="sidebar-brand">
          <Wordmark size={26} />
          <span className="eyebrow sidebar-tag">Staff</span>
        </div>
        <nav aria-label="Navigation principale" className="sidebar-nav">
          {SECTIONS.map((section) => {
            const allowed = can(me, section.permission);
            if (!allowed) return null;
            const current = section.id === active;
            return (
              <a key={section.id} href={buildHash(section.id)} className={`nav-item${current ? " is-active" : ""}`} aria-current={current ? "page" : undefined}>
                <Icon name={ICONS[section.id]} />
                <span className="nav-label">{section.label}</span>
                {section.id === "signalements" && openReports !== null && openReports > 0 ? (
                  <span className="nav-count" aria-label={`${openReports} ouverts`}>
                    {formatNumber(openReports)}
                  </span>
                ) : null}
                {!section.implemented ? <span className="nav-soon">Bientôt</span> : null}
              </a>
            );
          })}
        </nav>
        <div className="sidebar-foot">
          <div className="sidebar-user">
            <span className="sidebar-email" title={me.email}>
              {me.email}
            </span>
            <span className="sidebar-role">{me.roleLabel}</span>
          </div>
          <button type="button" className="sidebar-logout" onClick={session.logout}>
            <Icon name="logout" size={16} />
            Se déconnecter
          </button>
        </div>
      </aside>
      <main id="contenu" className="content" tabIndex={-1}>
        {children}
      </main>
    </div>
  );
}
