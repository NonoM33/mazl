import type { ReactNode } from "react";
import { BarChart3, CalendarDays, CalendarHeart, EyeOff, Heart, Home, Layers, MessageCircle, PartyPopper, Settings, Sparkles, User } from "lucide-react";
import { Link, useRouter } from "../shared/router";
import { useDiscreet } from "../shared/discreet-context";

// The icon rail. Dating mode and couple mode have their own entries, never
// both at once (docs/couple/CONTRAT.md: one navigation at a time).

interface RailEntry { readonly to: string; readonly label: string; readonly icon: ReactNode; readonly badge?: number }

const ICON = { size: 22, strokeWidth: 1.9, "aria-hidden": true } as const;

export function datingEntries(unread: number): readonly RailEntry[] {
  return [
    { to: "/", label: "Accueil", icon: <Home {...ICON} /> },
    { to: "/decouvrir", label: "Découvrir", icon: <Layers {...ICON} /> },
    { to: "/likes", label: "Likes et visiteurs", icon: <Heart {...ICON} /> },
    { to: "/messages", label: "Messages", icon: <MessageCircle {...ICON} />, badge: unread },
    { to: "/evenements", label: "Événements", icon: <CalendarDays {...ICON} /> },
    { to: "/profil", label: "Profil", icon: <User {...ICON} /> },
    { to: "/statistiques", label: "Statistiques", icon: <BarChart3 {...ICON} /> },
  ];
}

export const COUPLE_ENTRIES: readonly RailEntry[] = [
  { to: "/couple", label: "Notre espace", icon: <Heart {...ICON} /> },
  { to: "/couple/activites", label: "Activités", icon: <Sparkles {...ICON} /> },
  { to: "/couple/calendrier", label: "Calendrier", icon: <CalendarHeart {...ICON} /> },
  { to: "/couple/evenements", label: "Événements", icon: <PartyPopper {...ICON} /> },
];

function isCurrent(entry: string, path: string): boolean {
  if (entry === "/") return path === "/";
  if (entry === "/couple") return path === "/couple";
  return path === entry || path.startsWith(`${entry}/`);
}

function RailLink({ entry, path }: { readonly entry: RailEntry; readonly path: string }) {
  const badge = entry.badge && entry.badge > 0 ? (entry.badge > 99 ? "99+" : String(entry.badge)) : null;
  return (
    <Link to={entry.to} className="rail-item" aria-current={isCurrent(entry.to, path) ? "page" : undefined} aria-label={badge ? `${entry.label}, ${badge} non lus` : entry.label}>
      {entry.icon}
      {badge && <span className="badge" aria-hidden="true">{badge}</span>}
      <span className="rail-tooltip" aria-hidden="true">{entry.label}</span>
    </Link>
  );
}

export function Shell({ entries, children }: { readonly entries: readonly RailEntry[]; readonly children: ReactNode }) {
  const { location } = useRouter();
  const discreet = useDiscreet();
  return (
    <div className="shell">
      <nav className="rail" aria-label="Navigation principale">
        <Link to="/" className="rail-logo" aria-label="mazl, accueil">m<span className="dot">.</span></Link>
        <div className="rail-nav">{entries.map((entry) => <RailLink key={entry.to} entry={entry} path={location.path} />)}</div>
        <div className="rail-spacer" />
        <div className="rail-nav">
          <button type="button" className="rail-item" onClick={discreet.enter} aria-label="Mode discret (Échap deux fois)">
            <EyeOff {...ICON} />
            <span className="rail-tooltip" aria-hidden="true">Mode discret · Échap ×2</span>
          </button>
          <RailLink entry={{ to: "/premium", label: "mazl+", icon: <span style={{ fontWeight: 700, fontSize: 15, letterSpacing: -0.6 }}>m+</span> }} path={location.path} />
          <RailLink entry={{ to: "/reglages", label: "Réglages", icon: <Settings {...ICON} /> }} path={location.path} />
        </div>
      </nav>
      <main className="screen" id="contenu">{children}</main>
    </div>
  );
}

export function ScreenHeader({ title, eyebrow, actions }: { readonly title: string; readonly eyebrow?: string; readonly actions?: ReactNode }) {
  return (
    <header className="screen-header">
      <div className="stack gap-4">
        {eyebrow && <p className="eyebrow">{eyebrow}</p>}
        <h1 className="headline-m">{title}</h1>
      </div>
      {actions && <div className="inline gap-8">{actions}</div>}
    </header>
  );
}
