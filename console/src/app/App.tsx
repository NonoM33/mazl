import type { ReactElement } from "react";
import { LoginScreen } from "../auth/LoginScreen";
import { MfaCodeStep } from "../auth/MfaCodeStep";
import { MfaEnrollScreen } from "../auth/MfaEnrollScreen";
import { DashboardScreen } from "../dashboard/DashboardScreen";
import { AlgorithmScreen } from "../matching/AlgorithmScreen";
import { tabFromParam } from "../matching/tabs";
import { MemberFileScreen } from "../members/MemberFileScreen";
import { MembersScreen } from "../members/MembersScreen";
import { ReportsScreen } from "../reports/ReportsScreen";
import { EmptyState, Forbidden } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { ToastProvider } from "../shared/ui/Toast";
import { ComingSoon } from "./ComingSoon";
import { can, sectionById } from "./permissions";
import { SessionProvider, useMe, useSession } from "./session";
import { Shell } from "./Shell";
import { useRoute } from "./use-route";
import type { Route } from "./router";

function Screen({ route }: { readonly route: Route }): ReactElement {
  const me = useMe();
  if (route.section === null) {
    return (
      <>
        <PageHeader eyebrow="Erreur 404" title="Page introuvable" />
        <div className="page-body">
          <EmptyState icon="search" title="Cette adresse n'existe pas">
            Utilisez la navigation de gauche pour revenir à une section.
          </EmptyState>
        </div>
      </>
    );
  }
  const section = sectionById(route.section);
  if (!can(me, section.permission)) {
    return (
      <>
        <PageHeader eyebrow="Permission refusée" title={section.label} />
        <div className="page-body">
          <Forbidden what={`la section «\u00A0${section.label}\u00A0»`} />
        </div>
      </>
    );
  }
  switch (section.id) {
    case "tableau-de-bord":
      return <DashboardScreen />;
    case "signalements":
      return <ReportsScreen selectedId={route.id} />;
    case "membres":
      return route.id === null ? <MembersScreen initialQuery={route.params["q"] ?? ""} /> : <MemberFileScreen key={route.id} memberId={route.id} />;
    case "algorithme":
      return <AlgorithmScreen tab={tabFromParam(route.params["onglet"])} />;
    default:
      return <ComingSoon section={section} />;
  }
}

function Gate(): ReactElement {
  const { state } = useSession();
  const route = useRoute();
  switch (state.phase) {
    case "loading":
      return <div className="boot" role="status" aria-label="Chargement de la console" />;
    case "anonymous":
      return <LoginScreen notice={state.notice} />;
    case "challenge":
      return <MfaCodeStep challenge={state.challenge} />;
    case "enrolling":
      return <MfaEnrollScreen />;
    case "ready":
      return (
        <Shell active={route.section}>
          <Screen route={route} />
        </Shell>
      );
  }
}

export function App(): ReactElement {
  return (
    <ToastProvider>
      <SessionProvider>
        <Gate />
      </SessionProvider>
    </ToastProvider>
  );
}
