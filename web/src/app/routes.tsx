import type { ReactNode } from "react";
import { CoupleScreen } from "../features/couple";
import { DiscoverScreen } from "../features/discover";
import { EventDetailScreen, EventsScreen } from "../features/events";
import { HomeScreen } from "../features/home";
import { LikesScreen } from "../features/likes";
import { MessagesScreen } from "../features/messages";
import { PremiumScreen } from "../features/premium";
import { ProfileEditScreen, ProfileScreen } from "../features/profile";
import { SettingsScreen } from "../features/settings";
import { StatsScreen } from "../features/stats";
import { matchPath } from "../shared/router";

// Route table. In couple mode only the couple routes and the shared ones
// (settings, mazl+) exist; otherwise /couple/* is closed
// (docs/couple/CONTRAT.md: one navigation at a time).

type Render = (params: Readonly<Record<string, string>>) => ReactNode;
interface RouteDef { readonly pattern: string; readonly render: Render }

const SHARED: readonly RouteDef[] = [
  { pattern: "/reglages", render: () => <SettingsScreen /> },
  { pattern: "/premium", render: () => <PremiumScreen /> },
];

const DATING: readonly RouteDef[] = [
  { pattern: "/", render: () => <HomeScreen /> },
  { pattern: "/decouvrir", render: () => <DiscoverScreen /> },
  { pattern: "/likes", render: () => <LikesScreen /> },
  { pattern: "/messages", render: () => <MessagesScreen conversationId={null} /> },
  { pattern: "/messages/:id", render: ({ id }) => <MessagesScreen conversationId={Number(id)} /> },
  { pattern: "/profil", render: () => <ProfileScreen /> },
  { pattern: "/profil/modifier", render: () => <ProfileEditScreen /> },
  { pattern: "/statistiques", render: () => <StatsScreen /> },
  { pattern: "/evenements", render: () => <EventsScreen /> },
  { pattern: "/evenements/:id", render: ({ id }) => <EventDetailScreen eventId={Number(id)} /> },
];

const COUPLE: readonly RouteDef[] = [
  { pattern: "/couple", render: () => <CoupleScreen section="espace" /> },
  { pattern: "/couple/activites", render: () => <CoupleScreen section="activites" /> },
  { pattern: "/couple/calendrier", render: () => <CoupleScreen section="calendrier" /> },
  { pattern: "/couple/evenements", render: () => <CoupleScreen section="evenements" /> },
];

export function resolveRoute(path: string, inCouple: boolean): { readonly node: ReactNode } | { readonly redirect: string } {
  const table = [...SHARED, ...(inCouple ? COUPLE : DATING)];
  for (const route of table) {
    const params = matchPath(route.pattern, path);
    if (params) return { node: route.render(params) };
  }
  return { redirect: inCouple ? "/couple" : "/" };
}
